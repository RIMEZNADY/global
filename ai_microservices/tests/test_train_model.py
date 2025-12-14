from __future__ import annotations

from pathlib import Path

from src import train_model
from src.utils import resolve_path_from_env


def test_train_model_creates_artifacts() -> None:
    metrics = train_model.train_model()
    assert "train" in metrics and "test" in metrics
    model_dir = resolve_path_from_env("MODEL_DIR", "models")
    expected_files = [
        model_dir / "model.joblib",
        model_dir / "scaler.joblib",
        model_dir / "feature_list.json",
        model_dir / "metrics.json",
    ]
    for path in expected_files:
        assert Path(path).exists(), f"Expected artifact missing: {path}"

