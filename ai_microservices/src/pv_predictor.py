"""
Module pour la prédiction de production PV avec ML
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Optional

import numpy as np
import pandas as pd
from joblib import load
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from .utils import get_logger, resolve_path_from_env

LOGGER = get_logger(__name__)

MODEL_DIR = resolve_path_from_env("MODEL_DIR", "models")
CLEAN_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")
RAW_DIR = resolve_path_from_env("DATA_RAW_DIR", "data_raw")

PV_MODEL = None
PV_SCALER = None
PV_FEATURE_LIST: list[str] = []


def load_pv_data() -> pd.DataFrame:
    """Charge les données PV pour entraînement"""
    # Charger toutes les zones
    pv_files = [
        "casablanca_pv_2024_6h.csv",
        "zone_a_sahara_pv_2024_6h.csv",
        "zone_b_centre_pv_2024_6h.csv",
        "zone_d_rif_pv_2024_6h.csv",
    ]
    
    all_data = []
    for filename in pv_files:
        filepath = RAW_DIR / filename
        if filepath.exists():
            df = pd.read_csv(filepath)
            df["datetime"] = pd.to_datetime(df["datetime"])
            all_data.append(df)
            LOGGER.info(f"Loaded {filename}: {len(df)} rows")
    
    if not all_data:
        raise FileNotFoundError("No PV data files found")
    
    return pd.concat(all_data, ignore_index=True)


def prepare_pv_features(df: pd.DataFrame, meteo_df: Optional[pd.DataFrame] = None) -> pd.DataFrame:
    """Prépare les features pour la prédiction PV"""
    features = pd.DataFrame()
    
    # Features temporelles
    features["hour"] = df["datetime"].dt.hour
    features["dayofweek"] = df["datetime"].dt.dayofweek
    features["month"] = df["datetime"].dt.month
    features["is_weekend"] = (df["datetime"].dt.dayofweek >= 5).astype(int)
    features["is_night"] = ((df["datetime"].dt.hour < 6) | (df["datetime"].dt.hour >= 18)).astype(int)
    
    # Si données météo disponibles, les utiliser
    if meteo_df is not None:
        merged = df.merge(meteo_df, on="datetime", how="left")
        features["temperature_C"] = merged["temperature_C"].fillna(20.0)
        features["irradiance_kWh_m2"] = merged["irradiance_kWh_m2"].fillna(0.0)
    else:
        # Estimation basique
        features["temperature_C"] = 20.0
        features["irradiance_kWh_m2"] = 0.0
    
    # Lags (production PV précédente)
    df_sorted = df.sort_values("datetime")
    features["lag_6h"] = df_sorted["pv_prod_kWh"].shift(1).fillna(0.0)
    features["lag_12h"] = df_sorted["pv_prod_kWh"].shift(2).fillna(0.0)
    features["lag_24h"] = df_sorted["pv_prod_kWh"].shift(4).fillna(0.0)
    
    # Rolling statistics
    features["roll_mean_24h"] = df_sorted["pv_prod_kWh"].rolling(window=4, min_periods=1).mean().fillna(0.0)
    features["roll_std_24h"] = df_sorted["pv_prod_kWh"].rolling(window=4, min_periods=1).std().fillna(0.0)
    
    return features


def train_pv_model() -> Dict:
    """Entraîne le modèle ML pour prédire la production PV"""
    LOGGER.info("Loading PV data for training...")
    pv_df = load_pv_data()
    
    # Charger données météo si disponibles
    meteo_files = [
        "casablanca_meteo_2024_6h.csv",
        "zone_a_sahara_meteo_2024_6h.csv",
        "zone_b_centre_meteo_2024_6h.csv",
        "zone_d_rif_meteo_2024_6h.csv",
    ]
    
    meteo_data = []
    for filename in meteo_files:
        filepath = RAW_DIR / filename
        if filepath.exists():
            df = pd.read_csv(filepath)
            df["datetime"] = pd.to_datetime(df["datetime"])
            meteo_data.append(df)
    
    meteo_df = pd.concat(meteo_data, ignore_index=True) if meteo_data else None
    
    # Préparer features
    LOGGER.info("Preparing features...")
    X = prepare_pv_features(pv_df, meteo_df)
    y = pv_df["pv_prod_kWh"].values
    
    # Split train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, shuffle=False
    )
    
    # Scaling
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    # Entraîner modèle (RandomForest pour commencer)
    LOGGER.info("Training PV prediction model...")
    model = RandomForestRegressor(n_estimators=100, random_state=42, n_jobs=-1)
    model.fit(X_train_scaled, y_train)
    
    # Évaluer
    y_pred_train = model.predict(X_train_scaled)
    y_pred_test = model.predict(X_test_scaled)
    
    train_mae = mean_absolute_error(y_train, y_pred_train)
    test_mae = mean_absolute_error(y_test, y_pred_test)
    train_rmse = np.sqrt(mean_squared_error(y_train, y_pred_train))
    test_rmse = np.sqrt(mean_squared_error(y_test, y_pred_test))
    
    metrics = {
        "train": {"mae": float(train_mae), "rmse": float(train_rmse)},
        "test": {"mae": float(test_mae), "rmse": float(test_rmse)},
    }
    
    # Sauvegarder
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    from joblib import dump
    
    dump(model, MODEL_DIR / "pv_model.joblib")
    dump(scaler, MODEL_DIR / "pv_scaler.joblib")
    
    feature_list = X.columns.tolist()
    with open(MODEL_DIR / "pv_feature_list.json", "w") as f:
        json.dump(feature_list, f)
    
    LOGGER.info(f"PV model trained. Metrics: {metrics}")
    return metrics


def ensure_pv_model_loaded(force: bool = False) -> None:
    """Charge le modèle PV si pas déjà chargé"""
    global PV_MODEL, PV_SCALER, PV_FEATURE_LIST
    
    if PV_MODEL is not None and PV_SCALER is not None and not force:
        return
    
    model_path = MODEL_DIR / "pv_model.joblib"
    scaler_path = MODEL_DIR / "pv_scaler.joblib"
    features_path = MODEL_DIR / "pv_feature_list.json"
    
    if not (model_path.exists() and scaler_path.exists() and features_path.exists()):
        LOGGER.info("PV model not found. Training new model...")
        train_pv_model()
    
    PV_MODEL = load(model_path)
    PV_SCALER = load(scaler_path)
    with open(features_path, "r") as f:
        PV_FEATURE_LIST = json.load(f)
    
    LOGGER.info("PV model loaded successfully")


def predict_pv(
    datetime: pd.Timestamp,
    irradiance_kWh_m2: float,
    temperature_C: float,
    surface_m2: float,
    historical_pv: Optional[list[float]] = None,
) -> float:
    """Prédit la production PV avec ML"""
    ensure_pv_model_loaded()
    
    # Préparer features
    features = pd.DataFrame({
        "hour": [datetime.hour],
        "dayofweek": [datetime.dayofweek],
        "month": [datetime.month],
        "is_weekend": [1 if datetime.dayofweek >= 5 else 0],
        "is_night": [1 if datetime.hour < 6 or datetime.hour >= 18 else 0],
        "temperature_C": [temperature_C],
        "irradiance_kWh_m2": [irradiance_kWh_m2],
        "lag_6h": [historical_pv[-1] if historical_pv and len(historical_pv) > 0 else 0.0],
        "lag_12h": [historical_pv[-2] if historical_pv and len(historical_pv) > 1 else 0.0],
        "lag_24h": [historical_pv[-4] if historical_pv and len(historical_pv) > 3 else 0.0],
        "roll_mean_24h": [np.mean(historical_pv[-4:]) if historical_pv and len(historical_pv) >= 4 else 0.0],
        "roll_std_24h": [np.std(historical_pv[-4:]) if historical_pv and len(historical_pv) >= 4 else 0.0],
    })
    
    # S'assurer que toutes les features sont présentes
    for feature in PV_FEATURE_LIST:
        if feature not in features.columns:
            features[feature] = 0.0
    
    # Réordonner selon PV_FEATURE_LIST
    features = features[PV_FEATURE_LIST]
    
    # Prédire
    features_scaled = PV_SCALER.transform(features)
    prediction = PV_MODEL.predict(features_scaled)[0]
    
    # Ajuster selon la surface (le modèle est entraîné sur une surface de référence)
    # On assume que la production est proportionnelle à la surface
    reference_surface = 1000.0  # Surface de référence utilisée pour l'entraînement
    prediction = prediction * (surface_m2 / reference_surface)
    
    # S'assurer que la prédiction est positive
    return max(0.0, prediction)


