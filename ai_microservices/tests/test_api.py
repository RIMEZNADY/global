from __future__ import annotations

import pandas as pd
from fastapi.testclient import TestClient

from src import data_prep, train_model
from src.api import app, ensure_artifacts_loaded
from src.utils import resolve_path_from_env


def _prepare_pipeline() -> None:
    data_prep.build_dataset()
    train_model.train_model()
    ensure_artifacts_loaded(force=True)


def test_health_endpoint() -> None:
    _prepare_pipeline()
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] in {"ok", "degraded"}
    assert isinstance(payload["model_loaded"], bool)


def test_predict_endpoint_returns_value() -> None:
    _prepare_pipeline()
    client = TestClient(app)
    clean_dir = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")
    history = pd.read_parquet(clean_dir / "merged.parquet")
    history = history.sort_index()
    dt_next = history.index.max() + pd.Timedelta(hours=6)
    fill_history = history.ffill()
    payload = {
        "datetime": dt_next.isoformat(),
        "temperature_C": float(fill_history.get("temperature_C", pd.Series([20.0])).iloc[-1]),
        "irradiance_kWh_m2": float(fill_history.get("irradiance_kWh_m2", pd.Series([0.1])).iloc[-1]),
        "pv_prod_kWh": float(fill_history.get("pv_prod_kWh", pd.Series([0.0])).iloc[-1]),
        "patients": float(fill_history.get("patients", pd.Series([10.0])).iloc[-1]),
        "soc_batterie_kWh": float(fill_history.get("soc_batterie_kWh", pd.Series([100.0])).iloc[-1]),
        "event": "maintenance",
    }
    response = client.post("/predict", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert "pred_kWh" in body
    assert isinstance(body["pred_kWh"], (int, float))


def test_retrain_endpoint() -> None:
    _prepare_pipeline()
    client = TestClient(app)
    response = client.post("/retrain")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"

