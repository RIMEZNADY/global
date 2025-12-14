"""
Module pour le clustering d'établissements similaires
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import pandas as pd
from joblib import load, dump
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

from .utils import get_logger, resolve_path_from_env

LOGGER = get_logger(__name__)

MODEL_DIR = resolve_path_from_env("MODEL_DIR", "models")

CLUSTERING_MODEL = None
CLUSTERING_SCALER = None


def prepare_establishment_features(
    establishment_type: str,
    number_of_beds: int,
    monthly_consumption: float,
    installable_surface: Optional[float],
    irradiation_class: str,
    latitude: Optional[float],
    longitude: Optional[float],
) -> np.ndarray:
    """Prépare les features pour le clustering"""
    # Encoder type d'établissement (simplifié)
    type_encoding = {
        "CHU": 1.0,
        "HOPITAL_REGIONAL": 0.9,
        "HOPITAL_PREFECTORAL": 0.8,
        "HOPITAL_PROVINCIAL": 0.8,
        "HOPITAL_GENERAL": 0.75,
        "HOPITAL_SPECIALISE": 0.85,
        "CENTRE_REGIONAL_ONCOLOGIE": 0.7,
        "CENTRE_HEMODIALYSE": 0.75,
        "CENTRE_REEDUCATION": 0.5,
        "CENTRE_ADDICTOLOGIE": 0.4,
        "CENTRE_SOINS_PALLIATIFS": 0.4,
        "UMH": 0.6,
        "UMP": 0.5,
        "UPH": 0.4,
        "CENTRE_SANTE_PRIMAIRE": 0.3,
        "CLINIQUE_PRIVEE": 0.65,
        "AUTRE": 0.5,
    }
    
    # Encoder classe d'irradiation
    irradiation_encoding = {"A": 1.0, "B": 0.75, "C": 0.5, "D": 0.25}
    
    features = np.array([
        type_encoding.get(establishment_type, 0.5),
        float(number_of_beds) / 1000.0,  # Normaliser
        monthly_consumption / 100000.0,  # Normaliser (100k kWh = 1.0)
        (installable_surface or 0.0) / 10000.0,  # Normaliser (10k m² = 1.0)
        irradiation_encoding.get(irradiation_class, 0.5),
        (latitude or 33.0) / 100.0,  # Normaliser
        (longitude or -7.0) / 100.0,  # Normaliser
    ])
    
    return features.reshape(1, -1)


def train_clustering_model(establishments_data: List[Dict]) -> Dict:
    """Entraîne le modèle de clustering"""
    LOGGER.info("Training clustering model with %d establishments", len(establishments_data))
    
    if len(establishments_data) < 5:
        LOGGER.warning("Not enough establishments for clustering (minimum 5)")
        return {"status": "insufficient_data", "n_clusters": 0}
    
    # Préparer features
    features_list = []
    for est in establishments_data:
        features = prepare_establishment_features(
            establishment_type=est.get("type", "AUTRE"),
            number_of_beds=est.get("numberOfBeds", 0),
            monthly_consumption=est.get("monthlyConsumptionKwh", 0.0),
            installable_surface=est.get("installableSurfaceM2"),
            irradiation_class=est.get("irradiationClass", "C"),
            latitude=est.get("latitude"),
            longitude=est.get("longitude"),
        )
        features_list.append(features[0])
    
    X = np.array(features_list)
    
    # Scaling
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Déterminer nombre optimal de clusters (3-5 selon nombre d'établissements)
    n_clusters = min(max(3, len(establishments_data) // 5), 5)
    
    # Entraîner K-Means
    model = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    model.fit(X_scaled)
    
    # Sauvegarder
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    dump(model, MODEL_DIR / "clustering_model.joblib")
    dump(scaler, MODEL_DIR / "clustering_scaler.joblib")
    
    LOGGER.info("Clustering model trained with %d clusters", n_clusters)
    return {"status": "trained", "n_clusters": n_clusters}


def ensure_clustering_model_loaded(force: bool = False) -> None:
    """Charge le modèle de clustering"""
    global CLUSTERING_MODEL, CLUSTERING_SCALER
    
    if CLUSTERING_MODEL is not None and CLUSTERING_SCALER is not None and not force:
        return
    
    model_path = MODEL_DIR / "clustering_model.joblib"
    scaler_path = MODEL_DIR / "clustering_scaler.joblib"
    
    if not (model_path.exists() and scaler_path.exists()):
        LOGGER.warning("Clustering model not found. Need to train first.")
        return
    
    CLUSTERING_MODEL = load(model_path)
    CLUSTERING_SCALER = load(scaler_path)
    LOGGER.info("Clustering model loaded successfully")


def cluster_establishment(
    establishment_type: str,
    number_of_beds: int,
    monthly_consumption: float,
    installable_surface: Optional[float],
    irradiation_class: str,
    latitude: Optional[float],
    longitude: Optional[float],
) -> Dict:
    """Clustérise un établissement"""
    ensure_clustering_model_loaded()
    
    if CLUSTERING_MODEL is None or CLUSTERING_SCALER is None:
        return {
            "cluster_id": -1,
            "message": "Clustering model not available. Need training data."
        }
    
    # Préparer features
    features = prepare_establishment_features(
        establishment_type, number_of_beds, monthly_consumption,
        installable_surface, irradiation_class, latitude, longitude
    )
    
    # Scaling
    features_scaled = CLUSTERING_SCALER.transform(features)
    
    # Prédire cluster
    cluster_id = int(CLUSTERING_MODEL.predict(features_scaled)[0])
    
    # Distance au centre du cluster
    cluster_center = CLUSTERING_MODEL.cluster_centers_[cluster_id]
    distance = float(np.linalg.norm(features_scaled[0] - cluster_center))
    
    return {
        "cluster_id": cluster_id,
        "distance_to_center": distance,
        "cluster_characteristics": {
            "typical_beds_range": "To be determined from cluster analysis",
            "typical_consumption_range": "To be determined from cluster analysis",
        }
    }


