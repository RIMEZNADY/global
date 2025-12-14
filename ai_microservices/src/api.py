from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Union

import numpy as np
import pandas as pd
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from joblib import load
from pydantic import BaseModel, Field, field_validator

from . import data_prep, optimizer, train_model, pv_predictor, anomaly_detector, clustering, ml_recommendations, longterm_predictor, seasonal_predictor
from .utils import get_logger, resolve_path_from_env


LOGGER = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application"""
    # Startup
    LOGGER.info("Starting AI microservice...")
    
    # Vérifier si le modèle ROI existe
    roi_model_path = MODEL_DIR / "roi_model.joblib"
    if not roi_model_path.exists():
        LOGGER.info("ROI model not found. Use POST /train/roi to train it.")
    
    # Vérifier si les modèles long terme existent
    longterm_model_path = MODEL_DIR / "longterm_consumption_model.joblib"
    if not longterm_model_path.exists():
        LOGGER.info("Long-term ML models not found. Use POST /train/longterm to train them.")
    
    ensure_artifacts_loaded()
    LOGGER.info("AI microservice ready.")
    
    yield
    
    # Shutdown (si nécessaire)
    LOGGER.info("Shutting down AI microservice...")


app = FastAPI(title="Microgrid Hospitalier Intelligent", version="0.1.0", lifespan=lifespan)

MODEL_DIR = resolve_path_from_env("MODEL_DIR", "models")
CLEAN_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")

MODEL = None
SCALER = None
FEATURE_LIST: List[str] = []
HISTORY: Optional[pd.DataFrame] = None


class PredictRequest(BaseModel):
    datetime: datetime
    temperature_C: float
    irradiance_kWh_m2: float
    pv_prod_kWh: float
    patients: float
    soc_batterie_kWh: Optional[float] = None
    event: Optional[str] = Field(default=None, description="Event descriptor")

    @field_validator("datetime", mode="before")
    @classmethod
    def ensure_datetime(cls, value: datetime) -> datetime:
        dt = value if isinstance(value, datetime) else datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        else:
            dt = dt.astimezone(timezone.utc)
        return dt


class OptimizeRequest(BaseModel):
    pred_kWh: float
    pv_kWh: float
    soc_kwh: float
    BATTERY_CAP_KWH: Optional[float] = None
    SOC_MIN: Optional[float] = None
    SOC_MAX: Optional[float] = None
    CHARGE_MAX_KW: Optional[float] = None
    DISCHARGE_MAX_KW: Optional[float] = None


def ensure_artifacts_loaded(force: bool = False) -> None:
    global MODEL, SCALER, FEATURE_LIST, HISTORY
    if MODEL is not None and SCALER is not None and FEATURE_LIST and not force:
        return
    model_path = MODEL_DIR / "model.joblib"
    scaler_path = MODEL_DIR / "scaler.joblib"
    features_path = MODEL_DIR / "feature_list.json"
    if not (model_path.exists() and scaler_path.exists() and features_path.exists()):
        LOGGER.info("Artifacts missing. Running preparation and training pipeline.")
        data_prep.build_dataset()
        train_model.train_model()
    MODEL = load(model_path)
    SCALER = load(scaler_path)
    FEATURE_LIST = json.loads(features_path.read_text(encoding="utf-8"))
    history_path = CLEAN_DIR / "merged.parquet"
    if history_path.exists():
        HISTORY = pd.read_parquet(history_path)
    else:
        LOGGER.warning("Merged history not found at %s", history_path)
        HISTORY = None
    LOGGER.info("Artifacts loaded successfully.")


def get_history() -> pd.DataFrame:
    ensure_artifacts_loaded()
    if HISTORY is None or HISTORY.empty:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Historical data unavailable.",
        )
    return HISTORY.copy()


def _compute_lag_features(history: pd.DataFrame) -> Dict[str, float]:
    if "total_consumption_kWh" not in history.columns:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Historical dataset missing total consumption.",
        )
    consumption = history["total_consumption_kWh"].dropna()
    if consumption.empty:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Insufficient history to compute lag features.",
        )
    values = consumption.to_numpy()
    lag_6h = float(values[-1])
    lag_12h = float(values[-2]) if len(values) >= 2 else lag_6h
    lag_24h = float(values[-4]) if len(values) >= 4 else lag_6h
    window = values[-4:] if len(values) >= 4 else values
    roll_mean = float(np.mean(window))
    roll_std = float(np.std(window, ddof=0))
    return {
        "total_consumption_kWh": lag_6h,
        "lag_6h": lag_6h,
        "lag_12h": lag_12h,
        "lag_24h": lag_24h,
        "roll_mean_24h": roll_mean,
        "roll_std_24h": roll_std,
    }


def _build_feature_vector(payload: PredictRequest) -> pd.DataFrame:
    ensure_artifacts_loaded()
    history = get_history()
    feature_values = {feature: 0.0 for feature in FEATURE_LIST}

    base_lags = _compute_lag_features(history)
    feature_values.update(base_lags)

    dt = payload.datetime
    feature_values["hour"] = float(dt.hour)
    feature_values["dayofweek"] = float(dt.weekday())
    feature_values["is_weekend"] = float(1 if dt.weekday() >= 5 else 0)
    feature_values["month"] = float(dt.month)
    feature_values["is_night"] = float(1 if dt.hour >= 22 or dt.hour < 6 else 0)

    feature_values["temperature_C"] = float(payload.temperature_C)
    feature_values["irradiance_kWh_m2"] = float(payload.irradiance_kWh_m2)
    feature_values["pv_prod_kWh"] = float(payload.pv_prod_kWh)
    feature_values["patients"] = float(payload.patients)

    if "soc_batterie_kWh" in FEATURE_LIST:
        soc_value = (
            float(payload.soc_batterie_kWh)
            if payload.soc_batterie_kWh is not None
            else float(history.get("soc_batterie_kWh", pd.Series([0.0])).ffill().iloc[-1])
        )
        feature_values["soc_batterie_kWh"] = soc_value

    event_columns = [col for col in FEATURE_LIST if col.startswith("event_")]
    if event_columns:
        event_value = (payload.event or "other_event").lower().replace(" ", "_")
        matched = False
        for col in event_columns:
            suffix = col[len("event_") :].lower()
            if suffix == event_value:
                feature_values[col] = 1.0
                matched = True
            else:
                feature_values[col] = 0.0 if feature_values[col] != 1.0 else feature_values[col]
        if not matched and "event_other_event" in event_columns:
            feature_values["event_other_event"] = 1.0

    missing_required = [
        field
        for field in ["temperature_C", "irradiance_kWh_m2", "pv_prod_kWh", "patients"]
        if field not in FEATURE_LIST
    ]
    if missing_required:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Model missing required feature columns: {missing_required}",
        )

    df = pd.DataFrame([[feature_values.get(col, 0.0) for col in FEATURE_LIST]], columns=FEATURE_LIST)
    return df


@app.on_event("startup")
def startup_event() -> None:
    try:
        ensure_artifacts_loaded()
    except Exception as exc:
        LOGGER.error("Startup failed to load artifacts: %s", exc)
        raise


@app.get("/health")
def health() -> Dict[str, Union[bool, str]]:
    healthy = MODEL is not None and SCALER is not None
    roi_model_loaded = (MODEL_DIR / "roi_model.joblib").exists()
    longterm_models_loaded = (MODEL_DIR / "longterm_consumption_model.joblib").exists()
    
    return {
        "status": "ok" if healthy else "degraded",
        "model_loaded": bool(healthy),
        "roi_model_loaded": roi_model_loaded,
        "longterm_models_loaded": longterm_models_loaded,
    }


@app.get("/metrics")
def metrics() -> JSONResponse:
    ensure_artifacts_loaded()
    metrics_path = MODEL_DIR / "metrics.json"
    if not metrics_path.exists():
        raise HTTPException(status_code=404, detail="Metrics not available.")
    data = json.loads(metrics_path.read_text(encoding="utf-8"))
    return JSONResponse(content=data)


@app.post("/predict")
def predict(payload: PredictRequest) -> Dict[str, object]:
    ensure_artifacts_loaded()
    if MODEL is None or SCALER is None:
        raise HTTPException(status_code=500, detail="Model not loaded.")
    try:
        features = _build_feature_vector(payload)
        scaled = SCALER.transform(features)
        prediction = MODEL.predict(scaled)[0]
    except HTTPException:
        raise
    except Exception as exc:
        LOGGER.error("Prediction failed: %s", exc)
        raise HTTPException(status_code=500, detail="Prediction failure.")
    return {"pred_kWh": float(prediction), "features_used": FEATURE_LIST}


@app.post("/optimize")
def optimize(request: OptimizeRequest) -> Dict[str, Union[float, str]]:
    params = {
        key: value
        for key, value in request.model_dump().items()
        if key.isupper() and value is not None
    }
    result = optimizer.optimize_step(
        pred_kwh=request.pred_kWh,
        pv_kwh=request.pv_kWh,
        soc_kwh=request.soc_kwh,
        battery_params=params or None,
    )
    return result


@app.post("/retrain")
def retrain() -> Dict[str, object]:
    try:
        data_prep.build_dataset()
        metrics = train_model.train_model()
        ensure_artifacts_loaded(force=True)
    except Exception as exc:
        LOGGER.error("Retrain failed: %s", exc)
        raise HTTPException(status_code=500, detail="Retraining failed.")
    return {"status": "ok", "metrics": metrics}


class PvPredictRequest(BaseModel):
    datetime: datetime
    irradiance_kWh_m2: float
    temperature_C: float
    surface_m2: float
    historical_pv: Optional[list[float]] = Field(default=None, description="Historical PV production values")

    @field_validator("datetime", mode="before")
    @classmethod
    def ensure_datetime(cls, value: datetime) -> datetime:
        dt = value if isinstance(value, datetime) else datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        else:
            dt = dt.astimezone(timezone.utc)
        return dt


class AnomalyDetectionRequest(BaseModel):
    consumption: float
    predicted_consumption: float
    pv_production: float
    expected_pv: float
    soc: float
    temperature_C: float
    irradiance_kWh_m2: float


class ClusterRequest(BaseModel):
    establishment_type: str
    number_of_beds: int
    monthly_consumption: float
    installable_surface: Optional[float] = None
    irradiation_class: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None


class MlRecommendationRequest(BaseModel):
    establishment_type: str
    number_of_beds: int
    monthly_consumption: float
    installable_surface: Optional[float] = None
    irradiation_class: str
    recommended_pv_power: float
    recommended_battery: float
    autonomy: float
    roi_years: Optional[float] = Field(default=None, description="ROI calculé côté backend (formule déterministe)")
    similar_establishments: Optional[List[Dict]] = None


class LongTermPredictRequest(BaseModel):
    historical_data: List[Dict]
    horizon_days: int = Field(default=7, ge=1, le=30)


class SeasonalPredictRequest(BaseModel):
    historical_data: List[Dict]
    season: str = Field(..., description="Saison: 'ete', 'hiver', 'printemps', 'automne'")
    year: Optional[int] = Field(default=None, description="Année pour la prédiction (défaut: année actuelle)")


@app.post("/predict/pv")
def predict_pv_endpoint(payload: PvPredictRequest) -> Dict[str, object]:
    """Prédit la production PV avec ML"""
    try:
        import pandas as pd
        prediction = pv_predictor.predict_pv(
            datetime=pd.Timestamp(payload.datetime),
            irradiance_kWh_m2=payload.irradiance_kWh_m2,
            temperature_C=payload.temperature_C,
            surface_m2=payload.surface_m2,
            historical_pv=payload.historical_pv,
        )
        return {"predicted_pv_kWh": float(prediction)}
    except Exception as exc:
        LOGGER.error("PV prediction failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"PV prediction failed: {exc}")


@app.post("/detect/anomalies")
def detect_anomalies_endpoint(payload: AnomalyDetectionRequest) -> Dict[str, object]:
    """Détecte des anomalies dans les données"""
    try:
        result = anomaly_detector.detect_anomaly(
            consumption=payload.consumption,
            predicted_consumption=payload.predicted_consumption,
            pv_production=payload.pv_production,
            expected_pv=payload.expected_pv,
            soc=payload.soc,
            temperature=payload.temperature_C,
            irradiance=payload.irradiance_kWh_m2,
        )
        return result
    except Exception as exc:
        LOGGER.error("Anomaly detection failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Anomaly detection failed: {exc}")


@app.post("/cluster/establishments")
def cluster_establishments_endpoint(payload: ClusterRequest) -> Dict[str, object]:
    """Clustérise un établissement"""
    try:
        result = clustering.cluster_establishment(
            establishment_type=payload.establishment_type,
            number_of_beds=payload.number_of_beds,
            monthly_consumption=payload.monthly_consumption,
            installable_surface=payload.installable_surface,
            irradiation_class=payload.irradiation_class,
            latitude=payload.latitude,
            longitude=payload.longitude,
        )
        return result
    except Exception as exc:
        LOGGER.error("Clustering failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Clustering failed: {exc}")


@app.post("/recommendations/ml")
def ml_recommendations_endpoint(payload: MlRecommendationRequest) -> Dict[str, object]:
    """
    Génère des recommandations intelligentes basées sur règles + patterns similaires
    
    Approche "Hybrid Decision System" :
    - Règles simples déterministes pour cas évidents
    - Comparaison avec établissements similaires pour patterns
    - ROI calculé via formule déterministe côté backend Java, pas avec ML
    """
    try:
        result = ml_recommendations.get_ml_recommendations(
            establishment_type=payload.establishment_type,
            number_of_beds=payload.number_of_beds,
            monthly_consumption=payload.monthly_consumption,
            installable_surface=payload.installable_surface,
            irradiation_class=payload.irradiation_class,
            recommended_pv_power=payload.recommended_pv_power,
            recommended_battery=payload.recommended_battery,
            autonomy=payload.autonomy,
            roi_years=payload.roi_years,  # ROI calculé côté backend
            similar_establishments=payload.similar_establishments,
        )
        return result
    except Exception as exc:
        LOGGER.error("ML recommendations failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"ML recommendations failed: {exc}")


@app.post("/predict/longterm")
def predict_longterm_endpoint(payload: LongTermPredictRequest) -> Dict[str, object]:
    """Prédit consommation et production PV sur plusieurs jours"""
    try:
        result = longterm_predictor.predict_longterm(
            historical_data=payload.historical_data,
            horizon_days=payload.horizon_days,
        )
        return result
    except Exception as exc:
        LOGGER.error("Long-term prediction failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Long-term prediction failed: {exc}")


@app.post("/predict/seasonal")
def predict_seasonal_endpoint(payload: SeasonalPredictRequest) -> Dict[str, object]:
    """Prédit consommation et production PV pour une saison spécifique (été, hiver, printemps, automne)"""
    try:
        from . import seasonal_predictor
        result = seasonal_predictor.predict_seasonal(
            historical_data=payload.historical_data,
            season=payload.season,
            year=payload.year,
        )
        return result
    except Exception as exc:
        LOGGER.error("Seasonal prediction failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Seasonal prediction failed: {exc}")


@app.post("/predict/pv")
def predict_pv(payload: PvPredictRequest) -> Dict[str, object]:
    """Prédit la production PV avec ML"""
    try:
        import pandas as pd
        prediction = pv_predictor.predict_pv(
            datetime=pd.Timestamp(payload.datetime),
            irradiance_kWh_m2=payload.irradiance_kWh_m2,
            temperature_C=payload.temperature_C,
            surface_m2=payload.surface_m2,
            historical_pv=payload.historical_pv,
        )
        return {"predicted_pv_kWh": float(prediction)}
    except Exception as exc:
        LOGGER.error("PV prediction failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"PV prediction failed: {exc}")


@app.post("/detect/anomalies")
def detect_anomalies(payload: AnomalyDetectionRequest) -> Dict[str, object]:
    """Détecte des anomalies dans les données"""
    try:
        result = anomaly_detector.detect_anomaly(
            consumption=payload.consumption,
            predicted_consumption=payload.predicted_consumption,
            pv_production=payload.pv_production,
            expected_pv=payload.expected_pv,
            soc=payload.soc,
            temperature=payload.temperature_C,
            irradiance=payload.irradiance_kWh_m2,
        )
        return result
    except Exception as exc:
        LOGGER.error("Anomaly detection failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Anomaly detection failed: {exc}")


@app.post("/train/roi")
def train_roi_endpoint() -> Dict[str, object]:
    """Entraîne le modèle ROI avec des données synthétiques (charge depuis fichier si disponible)"""
    try:
        # Import ici pour éviter import circulaire
        from .train_roi_model import load_training_data
        
        LOGGER.info("Démarrage de l'entraînement du modèle ROI...")
        
        # Charger les données (depuis fichier si disponible, sinon génère)
        training_data = load_training_data()
        
        # Entraîner le modèle
        result = ml_recommendations.train_roi_model(training_data)
        
        if result.get("status") == "trained":
            return {
                "status": "success",
                "message": "Modèle ROI entraîné avec succès",
                "metrics": result.get("metrics"),
                "samples_used": len(training_data),
            }
        else:
            return {
                "status": "failed",
                "message": result.get("status", "Échec de l'entraînement"),
            }
    except Exception as exc:
        LOGGER.error("ROI training failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"ROI training failed: {exc}")


@app.post("/train/longterm")
def train_longterm_endpoint(payload: LongTermPredictRequest) -> Dict[str, object]:
    """Entraîne les modèles ML pour prédiction long terme"""
    try:
        LOGGER.info("Démarrage de l'entraînement des modèles long terme...")
        
        if not payload.historical_data or len(payload.historical_data) < 14:
            raise HTTPException(
                status_code=400, 
                detail="Need at least 14 days of historical data for training"
            )
        
        # Entraîner les modèles
        result = longterm_predictor.train_longterm_models(payload.historical_data)
        
        if result.get("status") == "trained":
            return {
                "status": "success",
                "message": "Modèles long terme entraînés avec succès",
                "metrics": result.get("metrics"),
                "samples_used": len(payload.historical_data),
            }
        else:
            return {
                "status": "failed",
                "message": result.get("message", "Échec de l'entraînement"),
            }
    except Exception as exc:
        LOGGER.error("Long-term training failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Long-term training failed: {exc}")

