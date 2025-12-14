"""
Module pour la prédiction long terme (7-30 jours) avec ML (RandomForest Time Series)
"""
from __future__ import annotations

import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import pandas as pd
from joblib import load, dump
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler

from .utils import get_logger, resolve_path_from_env

LOGGER = get_logger(__name__)

MODEL_DIR = resolve_path_from_env("MODEL_DIR", "models")
CLEAN_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")

# Modèles ML pour prévisions long terme
LONGTERM_CONSUMPTION_MODEL = None
LONGTERM_PV_MODEL = None
LONGTERM_SCALER_CONS = None
LONGTERM_SCALER_PV = None


def prepare_longterm_features(historical_data: List[Dict]) -> np.ndarray:
    """Prépare les features pour la prédiction long terme"""
    if not historical_data:
        return np.array([])
    
    # Extraire séries temporelles
    consumption = [d.get("consumption", 0.0) for d in historical_data]
    pv_production = [d.get("pv_production", 0.0) for d in historical_data]
    temperature = [d.get("temperature", 20.0) for d in historical_data]
    irradiance = [d.get("irradiance", 0.0) for d in historical_data]
    
    # Features statistiques
    features = np.array([
        np.mean(consumption),
        np.std(consumption),
        np.mean(pv_production),
        np.std(pv_production),
        np.mean(temperature),
        np.mean(irradiance),
        consumption[-1] if consumption else 0.0,  # Dernière valeur
        pv_production[-1] if pv_production else 0.0,
    ])
    
    return features.reshape(1, -1)


def predict_longterm_simple(
    historical_data: List[Dict],
    horizon_days: int,
) -> Dict:
    """
    Prédiction long terme simplifiée (sans LSTM pour l'instant)
    Utilise des moyennes et tendances
    """
    if not historical_data:
        return {
            "predictions": [],
            "confidence_intervals": [],
            "trend": "insufficient_data"
        }
    
    # Extraire séries
    consumption = [d.get("consumption", 0.0) for d in historical_data]
    pv_production = [d.get("pv_production", 0.0) for d in historical_data]
    
    # Calculer moyennes et tendances
    avg_consumption = np.mean(consumption)
    avg_pv = np.mean(pv_production)
    
    # Tendances (linéaire simple)
    if len(consumption) > 1:
        consumption_trend = (consumption[-1] - consumption[0]) / len(consumption)
        pv_trend = (pv_production[-1] - pv_production[0]) / len(pv_production) if len(pv_production) > 1 else 0.0
    else:
        consumption_trend = 0.0
        pv_trend = 0.0
    
    # Calculer la variance pour ajouter des variations réalistes
    consumption_std = np.std(consumption) if len(consumption) > 1 else avg_consumption * 0.15
    pv_std = np.std(pv_production) if len(pv_production) > 1 else avg_pv * 0.15
    
    # Générer prédictions pour chaque jour avec variations réalistes
    predictions = []
    confidence_intervals = []
    
    base_date = datetime.now()
    
    for day in range(1, horizon_days + 1):
        future_date = base_date + timedelta(days=day)
        day_of_week = future_date.weekday()
        month = future_date.month
        
        # Variations hebdomadaires (weekend = moins de consommation)
        weekday_factor_cons = 0.85 if day_of_week >= 5 else 1.0
        weekday_factor_pv = 1.0  # PV ne dépend pas du jour de la semaine
        
        # Variations saisonnières
        seasonal_factor_cons = 1.15 if month in [6, 7, 8] else 0.95 if month in [12, 1, 2] else 1.0
        seasonal_factor_pv = 1.2 if month in [5, 6, 7] else 0.8 if month in [12, 1] else 1.0
        
        # Variation cyclique (simuler des patterns)
        cycle_factor = 1.0 + 0.1 * np.sin(2 * np.pi * day / 7)  # Cycle hebdomadaire
        
        # Prédiction basée sur moyenne + tendance + variations
        pred_consumption = (avg_consumption + consumption_trend * day) * weekday_factor_cons * seasonal_factor_cons * cycle_factor
        pred_pv = (avg_pv + pv_trend * day) * seasonal_factor_pv * cycle_factor
        
        # Ajouter une variation aléatoire basée sur l'écart-type historique
        pred_consumption += np.random.normal(0, consumption_std * 0.3)
        pred_pv += np.random.normal(0, pv_std * 0.3)
        
        # S'assurer que les valeurs sont positives
        pred_consumption = max(0.0, pred_consumption)
        pred_pv = max(0.0, pred_pv)
        
        # Intervalle de confiance basé sur l'écart-type
        conf_lower_cons = max(0.0, pred_consumption - 1.5 * consumption_std)
        conf_upper_cons = pred_consumption + 1.5 * consumption_std
        conf_lower_pv = max(0.0, pred_pv - 1.5 * pv_std)
        conf_upper_pv = pred_pv + 1.5 * pv_std
        
        predictions.append({
            "day": day,
            "predicted_consumption": float(pred_consumption),
            "predicted_pv_production": float(pred_pv),
        })
        
        confidence_intervals.append({
            "day": day,
            "consumption_lower": float(conf_lower_cons),
            "consumption_upper": float(conf_upper_cons),
            "pv_lower": float(conf_lower_pv),
            "pv_upper": float(conf_upper_pv),
        })
    
    # Calculer tendance globale
    if consumption_trend > 0.01:
        trend = "increasing"
    elif consumption_trend < -0.01:
        trend = "decreasing"
    else:
        trend = "stable"
    
    return {
        "predictions": predictions,
        "confidence_intervals": confidence_intervals,
        "trend": trend,
        "method": "simple_average_trend"
    }


def prepare_longterm_ml_features(historical_data: List[Dict], day_offset: int = 0) -> np.ndarray:
    """
    Prépare des features ML avancées pour prédiction long terme
    Utilise des features temporelles, statistiques et séquentielles
    """
    if not historical_data:
        return np.array([]).reshape(1, -1)
    
    # Extraire séries temporelles
    consumption = [d.get("consumption", 0.0) for d in historical_data]
    pv_production = [d.get("pv_production", 0.0) for d in historical_data]
    temperature = [d.get("temperature", 20.0) for d in historical_data]
    irradiance = [d.get("irradiance", 0.0) for d in historical_data]
    
    # Features de base
    features = []
    
    # Statistiques consommation
    features.extend([
        np.mean(consumption),
        np.std(consumption),
        np.min(consumption),
        np.max(consumption),
        consumption[-1] if consumption else 0.0,  # Dernière valeur
        consumption[-7] if len(consumption) >= 7 else consumption[0] if consumption else 0.0,  # 7 jours avant
        np.median(consumption),
    ])
    
    # Statistiques PV
    features.extend([
        np.mean(pv_production),
        np.std(pv_production),
        np.min(pv_production),
        np.max(pv_production),
        pv_production[-1] if pv_production else 0.0,
        pv_production[-7] if len(pv_production) >= 7 else pv_production[0] if pv_production else 0.0,
        np.median(pv_production),
    ])
    
    # Features temporelles
    features.extend([
        np.mean(temperature),
        np.std(temperature),
        np.mean(irradiance),
        np.std(irradiance),
        day_offset,  # Offset du jour (0 = demain, 1 = après-demain, etc.)
        len(historical_data),  # Longueur de l'historique
    ])
    
    # Tendances (moyennes mobiles)
    if len(consumption) >= 7:
        features.extend([
            np.mean(consumption[-7:]),  # Moyenne 7 derniers jours
            np.mean(consumption[-14:]) if len(consumption) >= 14 else np.mean(consumption),  # Moyenne 14 jours
            np.mean(pv_production[-7:]),
            np.mean(pv_production[-14:]) if len(pv_production) >= 14 else np.mean(pv_production),
        ])
    else:
        features.extend([np.mean(consumption), np.mean(consumption), np.mean(pv_production), np.mean(pv_production)])
    
    # Ratios et corrélations
    if len(consumption) > 1:
        features.extend([
            np.corrcoef(consumption[-min(7, len(consumption)):], 
                       pv_production[-min(7, len(pv_production)):])[0, 1] if len(consumption) > 1 and len(pv_production) > 1 else 0.0,
            np.mean(consumption) / (np.mean(pv_production) + 1e-6),  # Ratio consommation/PV
        ])
    else:
        features.extend([0.0, 1.0])
    
    return np.array(features).reshape(1, -1)


def ensure_longterm_models_loaded(force: bool = False) -> bool:
    """
    Charge les modèles ML pour prédiction long terme
    Si les modèles n'existent pas, retourne False (fallback sur méthode simple)
    """
    global LONGTERM_CONSUMPTION_MODEL, LONGTERM_PV_MODEL, LONGTERM_SCALER_CONS, LONGTERM_SCALER_PV
    
    if (LONGTERM_CONSUMPTION_MODEL is not None and LONGTERM_PV_MODEL is not None and 
        LONGTERM_SCALER_CONS is not None and LONGTERM_SCALER_PV is not None and not force):
        return True
    
    model_cons_path = MODEL_DIR / "longterm_consumption_model.joblib"
    model_pv_path = MODEL_DIR / "longterm_pv_model.joblib"
    scaler_cons_path = MODEL_DIR / "longterm_consumption_scaler.joblib"
    scaler_pv_path = MODEL_DIR / "longterm_pv_scaler.joblib"
    
    if all(p.exists() for p in [model_cons_path, model_pv_path, scaler_cons_path, scaler_pv_path]):
        try:
            LONGTERM_CONSUMPTION_MODEL = load(model_cons_path)
            LONGTERM_PV_MODEL = load(model_pv_path)
            LONGTERM_SCALER_CONS = load(scaler_cons_path)
            LONGTERM_SCALER_PV = load(scaler_pv_path)
            LOGGER.info("Long-term ML models loaded successfully")
            return True
        except Exception as e:
            LOGGER.warning("Failed to load long-term ML models: %s. Using simple method.", e)
            return False
    else:
        LOGGER.info("Long-term ML models not found. Using simple method.")
        return False


def predict_longterm_ml(
    historical_data: List[Dict],
    horizon_days: int,
) -> Dict:
    """
    Prédit consommation et production PV avec modèles ML (RandomForest)
    """
    if not historical_data or len(historical_data) < 7:
        # Pas assez de données, utiliser méthode simple
        return predict_longterm_simple(historical_data, horizon_days)
    
    if not ensure_longterm_models_loaded():
        # Modèles non disponibles, utiliser méthode simple
        return predict_longterm_simple(historical_data, horizon_days)
    
    predictions = []
    confidence_intervals = []
    
    # Prédire pour chaque jour
    for day in range(1, horizon_days + 1):
        # Préparer features pour ce jour
        features = prepare_longterm_ml_features(historical_data, day_offset=day)
        
        # Prédire consommation
        features_scaled_cons = LONGTERM_SCALER_CONS.transform(features)
        pred_consumption = LONGTERM_CONSUMPTION_MODEL.predict(features_scaled_cons)[0]
        pred_consumption = max(0.0, float(pred_consumption))
        
        # Prédire PV
        features_scaled_pv = LONGTERM_SCALER_PV.transform(features)
        pred_pv = LONGTERM_PV_MODEL.predict(features_scaled_pv)[0]
        pred_pv = max(0.0, float(pred_pv))
        
        # Intervalles de confiance (utiliser l'écart-type des prédictions des arbres)
        # RandomForest permet d'obtenir une estimation de l'incertitude via les prédictions individuelles
        if hasattr(LONGTERM_CONSUMPTION_MODEL, 'estimators_'):
            cons_preds = [tree.predict(features_scaled_cons)[0] for tree in LONGTERM_CONSUMPTION_MODEL.estimators_]
            cons_std = np.std(cons_preds)
            cons_lower = max(0.0, pred_consumption - 1.96 * cons_std)
            cons_upper = pred_consumption + 1.96 * cons_std
        else:
            cons_lower = pred_consumption * 0.85
            cons_upper = pred_consumption * 1.15
        
        if hasattr(LONGTERM_PV_MODEL, 'estimators_'):
            pv_preds = [tree.predict(features_scaled_pv)[0] for tree in LONGTERM_PV_MODEL.estimators_]
            pv_std = np.std(pv_preds)
            pv_lower = max(0.0, pred_pv - 1.96 * pv_std)
            pv_upper = pred_pv + 1.96 * pv_std
        else:
            pv_lower = max(0.0, pred_pv * 0.85)
            pv_upper = pred_pv * 1.15
        
        predictions.append({
            "day": day,
            "predicted_consumption": pred_consumption,
            "predicted_pv_production": pred_pv,
        })
        
        confidence_intervals.append({
            "day": day,
            "consumption_lower": float(cons_lower),
            "consumption_upper": float(cons_upper),
            "pv_lower": float(pv_lower),
            "pv_upper": float(pv_upper),
        })
    
    # Calculer tendance
    if len(predictions) > 1:
        first_cons = predictions[0]["predicted_consumption"]
        last_cons = predictions[-1]["predicted_consumption"]
        trend_val = (last_cons - first_cons) / len(predictions)
        
        if trend_val > 0.01:
            trend = "increasing"
        elif trend_val < -0.01:
            trend = "decreasing"
        else:
            trend = "stable"
    else:
        trend = "stable"
    
    return {
        "predictions": predictions,
        "confidence_intervals": confidence_intervals,
        "trend": trend,
        "method": "ml_random_forest"
    }


def train_longterm_models(training_data: List[Dict]) -> Dict:
    """
    Entraîne les modèles ML pour prédiction long terme
    training_data doit contenir des séries temporelles avec au moins 14 jours d'historique
    """
    if not training_data or len(training_data) < 14:
        return {"status": "insufficient_data", "message": "Need at least 14 days of historical data"}
    
    LOGGER.info("Training long-term ML models with %d data points", len(training_data))
    
    # Préparer données d'entraînement
    # On va créer des exemples: pour chaque jour, on prend les 7 jours précédents pour prédire ce jour
    X_cons, y_cons = [], []
    X_pv, y_pv = [], []
    
    window_size = 7  # Utiliser 7 jours d'historique
    
    for i in range(window_size, len(training_data)):
        # Historique pour ce point
        historical_window = training_data[i - window_size:i]
        current_day_data = training_data[i]
        
        # Features (jour 0 = prédire le jour i)
        features = prepare_longterm_ml_features(historical_window, day_offset=0)
        
        # Targets
        target_cons = current_day_data.get("consumption", 0.0)
        target_pv = current_day_data.get("pv_production", 0.0)
        
        X_cons.append(features[0])
        y_cons.append(target_cons)
        X_pv.append(features[0])
        y_pv.append(target_pv)
    
    if len(X_cons) < 10:
        return {"status": "insufficient_data", "message": "Need at least 10 training samples"}
    
    X_cons = np.array(X_cons)
    X_pv = np.array(X_pv)
    y_cons = np.array(y_cons)
    y_pv = np.array(y_pv)
    
    # Split train/test (80/20) pour validation
    split_idx = int(len(X_cons) * 0.8)
    if split_idx < 5:
        split_idx = len(X_cons) // 2  # Au moins 50% pour train si trop peu de données
    
    X_cons_train, X_cons_test = X_cons[:split_idx], X_cons[split_idx:]
    X_pv_train, X_pv_test = X_pv[:split_idx], X_pv[split_idx:]
    y_cons_train, y_cons_test = y_cons[:split_idx], y_cons[split_idx:]
    y_pv_train, y_pv_test = y_pv[:split_idx], y_pv[split_idx:]
    
    # Scaling
    scaler_cons = StandardScaler()
    scaler_pv = StandardScaler()
    X_cons_train_scaled = scaler_cons.fit_transform(X_cons_train)
    X_cons_test_scaled = scaler_cons.transform(X_cons_test)
    X_pv_train_scaled = scaler_pv.fit_transform(X_pv_train)
    X_pv_test_scaled = scaler_pv.transform(X_pv_test)
    
    # Entraîner modèles avec paramètres anti-overfitting
    model_cons = RandomForestRegressor(
        n_estimators=100, 
        random_state=42, 
        n_jobs=-1, 
        max_depth=10,
        min_samples_split=5,  # Anti-overfitting
        min_samples_leaf=2,    # Anti-overfitting
    )
    model_pv = RandomForestRegressor(
        n_estimators=100, 
        random_state=42, 
        n_jobs=-1, 
        max_depth=10,
        min_samples_split=5,
        min_samples_leaf=2,
    )
    
    LOGGER.info("Training long-term models: %d train samples, %d test samples", 
               len(X_cons_train), len(X_cons_test))
    
    model_cons.fit(X_cons_train_scaled, y_cons_train)
    model_pv.fit(X_pv_train_scaled, y_pv_train)
    
    # Évaluer sur train et test
    from sklearn.metrics import mean_absolute_error, mean_squared_error
    
    y_cons_train_pred = model_cons.predict(X_cons_train_scaled)
    y_cons_test_pred = model_cons.predict(X_cons_test_scaled)
    y_pv_train_pred = model_pv.predict(X_pv_train_scaled)
    y_pv_test_pred = model_pv.predict(X_pv_test_scaled)
    
    # Métriques train
    cons_train_mae = mean_absolute_error(y_cons_train, y_cons_train_pred)
    cons_train_rmse = np.sqrt(mean_squared_error(y_cons_train, y_cons_train_pred))
    pv_train_mae = mean_absolute_error(y_pv_train, y_pv_train_pred)
    pv_train_rmse = np.sqrt(mean_squared_error(y_pv_train, y_pv_train_pred))
    
    # Métriques test (plus importantes)
    cons_test_mae = mean_absolute_error(y_cons_test, y_cons_test_pred)
    cons_test_rmse = np.sqrt(mean_squared_error(y_cons_test, y_cons_test_pred))
    pv_test_mae = mean_absolute_error(y_pv_test, y_pv_test_pred)
    pv_test_rmse = np.sqrt(mean_squared_error(y_pv_test, y_pv_test_pred))
    
    # Vérifier overfitting (différence train/test)
    cons_overfit = cons_train_mae < cons_test_mae * 0.7  # Train beaucoup mieux que test = overfitting
    pv_overfit = pv_train_mae < pv_test_mae * 0.7
    
    if cons_overfit or pv_overfit:
        LOGGER.warning("⚠️ Possible overfitting detected! Train metrics much better than test.")
    
    cons_mae = cons_test_mae  # Utiliser test pour reporting
    cons_rmse = cons_test_rmse
    pv_mae = pv_test_mae
    pv_rmse = pv_test_rmse
    
    # Sauvegarder
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    dump(model_cons, MODEL_DIR / "longterm_consumption_model.joblib")
    dump(model_pv, MODEL_DIR / "longterm_pv_model.joblib")
    dump(scaler_cons, MODEL_DIR / "longterm_consumption_scaler.joblib")
    dump(scaler_pv, MODEL_DIR / "longterm_pv_scaler.joblib")
    
    LOGGER.info("✅ Long-term ML models trained successfully")
    LOGGER.info("Consumption (TEST) - MAE: %.2f, RMSE: %.2f", cons_mae, cons_rmse)
    LOGGER.info("PV Production (TEST) - MAE: %.2f, RMSE: %.2f", pv_mae, pv_rmse)
    
    return {
        "status": "trained",
        "metrics": {
            "consumption": {
                "mae": float(cons_mae), 
                "rmse": float(cons_rmse),
                "train_mae": float(cons_train_mae),
                "train_rmse": float(cons_train_rmse),
            },
            "pv_production": {
                "mae": float(pv_mae), 
                "rmse": float(pv_rmse),
                "train_mae": float(pv_train_mae),
                "train_rmse": float(pv_train_rmse),
            },
            "overfitting_detected": cons_overfit or pv_overfit,
        },
        "meta": {
            "train_samples": len(X_cons_train),
            "test_samples": len(X_cons_test),
            "total_samples": len(X_cons),
        }
    }


def predict_longterm(
    historical_data: List[Dict],
    horizon_days: int = 7,
) -> Dict:
    """
    Prédit consommation et production PV sur plusieurs jours
    Utilise ML si disponible, sinon méthode simple
    """
    if horizon_days < 1 or horizon_days > 30:
        raise ValueError("horizon_days must be between 1 and 30")
    
    # Essayer d'utiliser le modèle ML
    if len(historical_data) >= 7:
        result_ml = predict_longterm_ml(historical_data, horizon_days)
        if result_ml.get("method") == "ml_random_forest":
            return result_ml
    
    # Fallback sur méthode simple
    return predict_longterm_simple(historical_data, horizon_days)


