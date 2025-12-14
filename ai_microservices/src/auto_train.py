from __future__ import annotations

import os
from datetime import datetime, timedelta

import pandas as pd

from . import data_prep, train_model
from .utils import get_logger, resolve_path_from_env


LOGGER = get_logger(__name__)

RAW_DIR = resolve_path_from_env("DATA_RAW_DIR", "data_raw")
CLEAN_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")

CHECK_WINDOW_HOURS = float(os.environ.get("AUTOTRAIN_WINDOW_HOURS", 24))


def _latest_raw_timestamp() -> datetime | None:
    try:
        frames = data_prep.load_raw_frames()
    except FileNotFoundError:
        return None
    latest = None
    for frame in frames.values():
        if frame.empty:
            continue
        max_dt = frame["datetime"].max()
        if latest is None or max_dt > latest:
            latest = max_dt
    return latest


def _features_snapshot() -> tuple[pd.DataFrame | None, datetime | None]:
    features_path = CLEAN_DIR / "features.parquet"
    if not features_path.exists():
        return None, None
    features_df = pd.read_parquet(features_path)
    latest_dt = (
        features_df.index.max()
        if isinstance(features_df.index, pd.DatetimeIndex)
        else None
    )
    return features_df, latest_dt


def has_new_data() -> bool:
    features_df, features_latest = _features_snapshot()
    raw_latest = _latest_raw_timestamp()
    if features_df is None:
        LOGGER.info("No existing features snapshot. Retraining required.")
        return True
    if raw_latest and features_latest and raw_latest > features_latest:
        LOGGER.info(
            "Newer raw data detected. Raw latest: %s, features latest: %s",
            raw_latest,
            features_latest,
        )
        return True
    window_start = datetime.utcnow() - timedelta(hours=CHECK_WINDOW_HOURS)
    for csv_path in RAW_DIR.glob("*.csv"):
        modified = datetime.utcfromtimestamp(csv_path.stat().st_mtime)
        if modified >= window_start:
            LOGGER.info("Recent modification detected in %s.", csv_path.name)
            return True
    return False


def run_auto_train() -> bool:
    if not has_new_data():
        LOGGER.info("No new data detected. Skipping retraining.")
        return False
    LOGGER.info("New data found. Running data preparation and training.")
    data_prep.build_dataset()
    train_model.train_model()
    LOGGER.info("Auto-training pipeline completed.")
    return True


def main() -> None:
    try:
        run_auto_train()
    except Exception as exc:
        LOGGER.error("Auto-train pipeline failed: %s", exc)
        raise


if __name__ == "__main__":
    main()

