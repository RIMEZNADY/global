from __future__ import annotations

import pandas as pd

from src import data_prep
from src.utils import resolve_path_from_env


def test_build_dataset_creates_feature_store() -> None:
    X, y, feature_names = data_prep.build_dataset()
    assert len(X) > 100, "Expected more than 100 rows in feature matrix."
    assert X.isna().sum().sum() == 0, "Feature matrix contains NaN values."
    assert y.notna().all(), "Target series contains NaN values."
    assert feature_names, "Feature names should not be empty."

    clean_dir = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")
    merged_path = clean_dir / "merged.parquet"
    features_path = clean_dir / "features.parquet"
    assert merged_path.exists(), "Merged dataset not saved."
    assert features_path.exists(), "Features dataset not saved."

    features_df = pd.read_parquet(features_path)
    assert "target" in features_df.columns, "Target column missing in features parquet."

