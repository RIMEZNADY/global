from __future__ import annotations

import importlib
import json
from datetime import datetime
from typing import Dict, Optional, Tuple

import numpy as np
import pandas as pd
from joblib import dump
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.preprocessing import StandardScaler

from .utils import get_logger, resolve_path_from_env, serialize_json


LOGGER = get_logger(__name__)
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

CLEAN_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")
MODEL_DIR = resolve_path_from_env("MODEL_DIR", "models")


def load_features() -> Tuple[pd.DataFrame, pd.Series]:
    features_path = CLEAN_DIR / "features.parquet"
    if not features_path.exists():
        LOGGER.info(
            "Features not found at %s. Triggering data preparation.", features_path
        )
        from . import data_prep

        data_prep.build_dataset()
    df = pd.read_parquet(features_path)
    if "target" not in df.columns:
        raise ValueError("Features parquet must contain 'target' column.")
    X = df.drop(columns=["target"])
    y = df["target"]
    return X, y


def _time_split(
    X: pd.DataFrame, y: pd.Series, test_ratio: float = 0.2
) -> Tuple[pd.DataFrame, pd.DataFrame, pd.Series, pd.Series]:
    split_idx = int(len(X) * (1 - test_ratio))
    if split_idx == 0 or split_idx == len(X):
        raise ValueError("Not enough samples to split into train/test sets.")
    X_train = X.iloc[:split_idx]
    X_test = X.iloc[split_idx:]
    y_train = y.iloc[:split_idx]
    y_test = y.iloc[split_idx:]
    return X_train, X_test, y_train, y_test


def _load_model_class() -> Tuple[str, object]:
    try:
        xgb_module = importlib.import_module("xgboost")
        model = xgb_module.XGBRegressor(
            objective="reg:squarederror",
            random_state=RANDOM_SEED,
            n_estimators=300,
            learning_rate=0.05,
            max_depth=5,
            subsample=0.8,
            colsample_bytree=0.8,
            early_stopping_rounds=20,  # Arrêt anticipé si pas d'amélioration
            eval_metric="rmse",
        )
        return "XGBRegressor", model
    except ModuleNotFoundError:
        from sklearn.ensemble import RandomForestRegressor

        LOGGER.warning("xgboost not available; falling back to RandomForestRegressor.")
        model = RandomForestRegressor(
            n_estimators=300,
            random_state=RANDOM_SEED,
            n_jobs=-1,
            max_depth=10,  # Limiter la profondeur pour éviter overfitting
            min_samples_split=10,  # Minimum d'échantillons pour split
            min_samples_leaf=5,  # Minimum d'échantillons par feuille
        )
        return "RandomForestRegressor", model


def _compute_metrics(
    y_true_train: np.ndarray,
    y_pred_train: np.ndarray,
    y_true_test: np.ndarray,
    y_pred_test: np.ndarray,
) -> Dict[str, Dict[str, float]]:
    def metrics(y_true: np.ndarray, y_pred: np.ndarray) -> Dict[str, float]:
        epsilon = 1e-6
        safe_true = np.where(np.abs(y_true) < epsilon, epsilon, y_true)
        mape = float(np.mean(np.abs((y_true - y_pred) / safe_true)))
        return {
            "mae": float(mean_absolute_error(y_true, y_pred)),
            "rmse": float(np.sqrt(mean_squared_error(y_true, y_pred))),
            "mape": mape,
        }

    return {"train": metrics(y_true_train, y_pred_train), "test": metrics(y_true_test, y_pred_test)}


def _load_previous_metrics() -> Optional[Dict]:
    """Charge les métriques précédentes pour comparaison"""
    metrics_path = MODEL_DIR / "metrics.json"
    if metrics_path.exists():
        try:
            return json.loads(metrics_path.read_text(encoding="utf-8"))
        except Exception:
            return None
    return None


def train_model() -> Dict[str, Dict[str, float]]:
    # Charger métriques précédentes pour comparaison
    previous_metrics = _load_previous_metrics()
    
    X, y = load_features()
    feature_names = X.columns.tolist()
    X_train, X_test, y_train, y_test = _time_split(X, y)
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    model_name, model = _load_model_class()
    LOGGER.info("Training model: %s with %d training samples", model_name, len(X_train))
    
    # Pour XGBoost, utiliser validation set pour early stopping
    if model_name == "XGBRegressor":
        try:
            model.fit(
                X_train_scaled, y_train,
                eval_set=[(X_test_scaled, y_test)],
                verbose=False
            )
        except Exception as e:
            LOGGER.warning("Early stopping failed, using standard fit: %s", e)
            model.fit(X_train_scaled, y_train)
    else:
        model.fit(X_train_scaled, y_train)

    y_pred_train = model.predict(X_train_scaled)
    y_pred_test = model.predict(X_test_scaled)
    metrics = _compute_metrics(
        y_train.to_numpy(),
        np.asarray(y_pred_train),
        y_test.to_numpy(),
        np.asarray(y_pred_test),
    )
    
    # Comparer avec métriques précédentes
    if previous_metrics:
        prev_test_mae = previous_metrics.get("test", {}).get("mae", float('inf'))
        prev_test_rmse = previous_metrics.get("test", {}).get("rmse", float('inf'))
        curr_test_mae = metrics["test"]["mae"]
        curr_test_rmse = metrics["test"]["rmse"]
        
        mae_improvement = ((prev_test_mae - curr_test_mae) / prev_test_mae) * 100 if prev_test_mae > 0 else 0
        rmse_improvement = ((prev_test_rmse - curr_test_rmse) / prev_test_rmse) * 100 if prev_test_rmse > 0 else 0
        
        metrics["improvement"] = {
            "mae_pct": round(mae_improvement, 2),
            "rmse_pct": round(rmse_improvement, 2),
            "improved": mae_improvement > 0 or rmse_improvement > 0
        }
        
        if mae_improvement > 0:
            LOGGER.info("✅ Model improved! MAE: %.2f%% better, RMSE: %.2f%% better", 
                       mae_improvement, rmse_improvement)
        else:
            LOGGER.warning("⚠️ Model performance degraded. MAE: %.2f%% worse, RMSE: %.2f%% worse", 
                          -mae_improvement, -rmse_improvement)
    
    metrics["meta"] = {
        "model": model_name,
        "timestamp": datetime.utcnow().isoformat(),
        "features": len(feature_names),
        "train_rows": int(len(X_train)),
        "test_rows": int(len(X_test)),
    }

    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    dump(model, MODEL_DIR / "model.joblib")
    dump(scaler, MODEL_DIR / "scaler.joblib")
    serialize_json(feature_names, MODEL_DIR / "feature_list.json")
    serialize_json(metrics, MODEL_DIR / "metrics.json")

    LOGGER.info("Model, scaler, and artifacts saved to %s", MODEL_DIR)
    LOGGER.info("Test metrics - MAE: %.4f, RMSE: %.4f, MAPE: %.2f%%", 
               metrics["test"]["mae"], metrics["test"]["rmse"], metrics["test"]["mape"] * 100)
    return metrics


def main() -> None:
    try:
        metrics = train_model()
        LOGGER.info("Training completed. Metrics: %s", metrics)
    except Exception as exc:
        LOGGER.error("Training failed: %s", exc)
        raise


if __name__ == "__main__":
    main()

