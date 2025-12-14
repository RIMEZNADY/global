"""
Module pour la détection d'anomalies avec ML
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, Optional

import numpy as np
import pandas as pd
from joblib import load
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

from .utils import get_logger, resolve_path_from_env

LOGGER = get_logger(__name__)

MODEL_DIR = resolve_path_from_env("MODEL_DIR", "models")
CLEAN_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")

ANOMALY_MODEL = None
ANOMALY_SCALER = None
ANOMALY_THRESHOLD = -0.1  # Seuil pour détecter anomalies


def prepare_anomaly_features(
    consumption: float,
    predicted_consumption: float,
    pv_production: float,
    expected_pv: float,
    soc: float,
    temperature: float,
    irradiance: float,
) -> np.ndarray:
    """Prépare les features pour la détection d'anomalies"""
    features = np.array([
        consumption,
        predicted_consumption,
        pv_production,
        expected_pv,
        soc,
        temperature,
        irradiance,
        abs(consumption - predicted_consumption),  # Écart consommation
        abs(pv_production - expected_pv),  # Écart production PV
        consumption / max(predicted_consumption, 0.1),  # Ratio consommation
        pv_production / max(expected_pv, 0.1),  # Ratio production PV
    ])
    return features.reshape(1, -1)


def train_anomaly_detector() -> Dict:
    """Entraîne le détecteur d'anomalies"""
    LOGGER.info("Training anomaly detector...")
    
    # Charger données historiques pour entraînement
    history_path = CLEAN_DIR / "merged.parquet"
    if not history_path.exists():
        LOGGER.warning("No historical data found. Using default anomaly detector.")
        return {"status": "default"}
    
    df = pd.read_parquet(history_path)
    
    # Préparer features
    features_list = []
    for idx in range(len(df)):
        row = df.iloc[idx]
        features = prepare_anomaly_features(
            consumption=row.get("total_consumption_kWh", 0.0),
            predicted_consumption=row.get("total_consumption_kWh", 0.0),  # Approx
            pv_production=row.get("pv_prod_kWh", 0.0),
            expected_pv=row.get("pv_prod_kWh", 0.0),  # Approx
            soc=row.get("soc_batterie_kWh", 0.0) if "soc_batterie_kWh" in row else 0.0,
            temperature=row.get("temperature_C", 20.0),
            irradiance=row.get("irradiance_kWh_m2", 0.0),
        )
        features_list.append(features[0])
    
    X = np.array(features_list)
    
    # Scaling
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Entraîner Isolation Forest
    model = IsolationForest(contamination=0.1, random_state=42, n_jobs=-1)
    model.fit(X_scaled)
    
    # Sauvegarder
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    from joblib import dump
    
    dump(model, MODEL_DIR / "anomaly_model.joblib")
    dump(scaler, MODEL_DIR / "anomaly_scaler.joblib")
    
    LOGGER.info("Anomaly detector trained successfully")
    return {"status": "trained"}


def ensure_anomaly_model_loaded(force: bool = False) -> None:
    """Charge le modèle de détection d'anomalies"""
    global ANOMALY_MODEL, ANOMALY_SCALER
    
    if ANOMALY_MODEL is not None and ANOMALY_SCALER is not None and not force:
        return
    
    model_path = MODEL_DIR / "anomaly_model.joblib"
    scaler_path = MODEL_DIR / "anomaly_scaler.joblib"
    
    if not (model_path.exists() and scaler_path.exists()):
        LOGGER.info("Anomaly model not found. Training new model...")
        train_anomaly_detector()
    
    ANOMALY_MODEL = load(model_path)
    ANOMALY_SCALER = load(scaler_path)
    
    LOGGER.info("Anomaly detector loaded successfully")


def detect_anomaly(
    consumption: float,
    predicted_consumption: float,
    pv_production: float,
    expected_pv: float,
    soc: float,
    temperature: float,
    irradiance: float,
) -> Dict:
    """Détecte une anomalie dans les données"""
    ensure_anomaly_model_loaded()
    
    # Préparer features
    features = prepare_anomaly_features(
        consumption, predicted_consumption, pv_production,
        expected_pv, soc, temperature, irradiance
    )
    
    # Scaling
    features_scaled = ANOMALY_SCALER.transform(features)
    
    # Prédire
    anomaly_score = ANOMALY_MODEL.score_samples(features_scaled)[0]
    is_anomaly = anomaly_score < ANOMALY_THRESHOLD
    
    # Classifier le type d'anomalie
    anomaly_type = "normal"
    if is_anomaly:
        consumption_diff = abs(consumption - predicted_consumption) / max(predicted_consumption, 0.1)
        pv_diff = abs(pv_production - expected_pv) / max(expected_pv, 0.1)
        
        if consumption_diff > 0.3:
            anomaly_type = "high_consumption" if consumption > predicted_consumption else "low_consumption"
        elif pv_diff > 0.3:
            anomaly_type = "pv_malfunction" if pv_production < expected_pv else "pv_overproduction"
        elif soc < 0.1:
            anomaly_type = "battery_low"
        else:
            anomaly_type = "unknown_anomaly"
    
    # Recommandation
    recommendation = "No action needed"
    if anomaly_type == "high_consumption":
        recommendation = "Check for equipment malfunction or unexpected load"
    elif anomaly_type == "low_consumption":
        recommendation = "Verify system is operating normally"
    elif anomaly_type == "pv_malfunction":
        recommendation = "Inspect PV panels for damage, shading, or cleaning needed"
    elif anomaly_type == "battery_low":
        recommendation = "Check battery health and charging system"
    
    return {
        "is_anomaly": bool(is_anomaly),
        "anomaly_score": float(anomaly_score),
        "anomaly_type": anomaly_type,
        "recommendation": recommendation,
    }


