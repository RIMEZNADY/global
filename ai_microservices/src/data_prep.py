from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from typing import Dict, List, Tuple

import numpy as np
import pandas as pd

from .utils import get_logger, resolve_path_from_env


LOGGER = get_logger(__name__)
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)

RAW_DIR = resolve_path_from_env("DATA_RAW_DIR", "data_raw")
CLEAN_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")


@dataclass(frozen=True)
class DatasetSpec:
    filename: str
    required_columns: Tuple[str, ...]


DATASETS: Dict[str, DatasetSpec] = {
    "meteo": DatasetSpec(
        "casablanca_meteo_2024_6h.csv",
        ("datetime", "temperature_C", "irradiance_kWh_m2"),
    ),
    "pv": DatasetSpec(
        "casablanca_pv_2024_6h.csv",
        ("datetime", "pv_prod_kWh"),
    ),
    "consumption": DatasetSpec(
        "chu_critique_non_critique.csv",
        (
            "datetime",
            "temperature_C",
            "irradiance_kWh_m2",
            "conso_critique_kWh",
            "conso_non_critique_kWh",
        ),
    ),
    "events": DatasetSpec(
        "chu_events_casablanca_6h.csv",
        ("datetime", "event"),
    ),
    "patients": DatasetSpec(
        "chu_patient.csv",
        ("datetime", "patients"),
    ),
    "soc": DatasetSpec(
        "soc.csv",
        (
            "datetime",
            "temperature_C",
            "irradiance_kWh_m2",
            "pv_prod_kWh",
            "conso_critique_kWh",
            "conso_non_critique_kWh",
            "soc_batterie_kWh",
        ),
    ),
}


def load_raw_frames() -> Dict[str, pd.DataFrame]:
    """Load raw CSV data frames using predefined schemas."""
    frames: Dict[str, pd.DataFrame] = {}
    for name, spec in DATASETS.items():
        path = RAW_DIR / spec.filename
        if not path.exists():
            LOGGER.warning("File missing for dataset '%s': %s", name, path)
            continue
        df = pd.read_csv(path)
        missing_cols = set(spec.required_columns) - set(df.columns)
        if missing_cols:
            raise ValueError(
                f"Dataset {name} at {path} missing columns: {sorted(missing_cols)}"
            )
        df = _prepare_datetime(df)
        frames[name] = df
        LOGGER.info("Loaded dataset '%s' with %d rows.", name, len(df))
    if not frames:
        raise FileNotFoundError(
            f"No raw datasets found in {RAW_DIR}. Expected files: "
            f"{', '.join(spec.filename for spec in DATASETS.values())}"
        )
    return frames


def _prepare_datetime(df: pd.DataFrame) -> pd.DataFrame:
    dt = pd.to_datetime(df["datetime"], utc=True, errors="coerce")
    if dt.isna().any():
        invalid = df.loc[dt.isna(), "datetime"].unique()
        raise ValueError(f"Invalid datetime entries encountered: {invalid[:5]}")
    df = df.copy()
    df["datetime"] = dt
    df = df.drop_duplicates(subset="datetime").sort_values("datetime")
    return df


def _resample_frame(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        return df
    df = df.set_index("datetime")
    aggregation = {
        col: _aggregation_strategy(col) for col in df.columns if col != "datetime"
    }
    if "event" in df.columns:
        aggregation["event"] = _mode_agg
    resampled = df.resample("6H").agg(aggregation)
    return resampled


def _aggregation_strategy(column: str) -> str:
    if column.endswith("_kWh") or column.endswith("_kW"):
        return "sum"
    if column in {"pv_prod_kWh"}:
        return "sum"
    if column in {"patients", "soc_batterie_kWh"}:
        return "mean"
    return "mean"


def _mode_agg(series: pd.Series) -> str | None:
    if series.dropna().empty:
        return None
    counts = Counter(series.dropna())
    return counts.most_common(1)[0][0]


def _merge_frames(frames: Dict[str, pd.DataFrame]) -> pd.DataFrame:
    merged: pd.DataFrame | None = None
    for name, frame in frames.items():
        resampled = _resample_frame(frame)
        LOGGER.info(
            "Resampled dataset '%s' to 6H frequency with %d rows.",
            name,
            len(resampled),
        )
        if merged is None:
            merged = resampled
            continue
        merged = merged.sort_index()
        resampled = resampled.reindex(merged.index.union(resampled.index)).sort_index()
        merged = merged.reindex(resampled.index)
        for col in resampled.columns:
            if col in merged.columns:
                merged[col] = merged[col].combine_first(resampled[col])
            else:
                merged[col] = resampled[col]
    if merged is None:
        raise ValueError("No frames available to merge.")
    merged = merged[~merged.index.duplicated()].sort_index()
    merged = _post_merge_cleaning(merged)
    return merged


def _post_merge_cleaning(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    for col in numeric_cols:
        if col.endswith("_kWh") or col.endswith("_kW"):
            df[col] = df[col].clip(lower=0)
    interpolate_cols = [
        col
        for col in df.columns
        if col in {"temperature_C", "irradiance_kWh_m2", "pv_prod_kWh"}
    ]
    for col in interpolate_cols:
        df[col] = df[col].interpolate(limit=1, limit_direction="both")
    consumption_cols = [
        col
        for col in df.columns
        if col in {"conso_critique_kWh", "conso_non_critique_kWh"}
    ]
    for col in consumption_cols:
        df[col] = _iqr_clip(df[col])
    if {"conso_critique_kWh", "conso_non_critique_kWh"}.intersection(df.columns):
        df["total_consumption_kWh"] = (
            df.get("conso_critique_kWh", 0).fillna(0)
            + df.get("conso_non_critique_kWh", 0).fillna(0)
        )
    return df


def _iqr_clip(series: pd.Series, factor: float = 1.5) -> pd.Series:
    q1 = series.quantile(0.25)
    q3 = series.quantile(0.75)
    iqr = q3 - q1
    lower = q1 - factor * iqr
    upper = q3 + factor * iqr
    return series.clip(lower=lower, upper=upper)


def _build_event_features(df: pd.DataFrame) -> pd.DataFrame:
    if "event" not in df.columns:
        return df
    events = df["event"].fillna("missing")
    top_events = events.value_counts().head(3).index.tolist()
    mapped = events.where(events.isin(top_events), other="other_event")
    dummies = pd.get_dummies(mapped, prefix="event", dtype=int)
    df = df.drop(columns=["event"])
    df = df.join(dummies)
    return df


def _add_time_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["total_consumption_kWh"] = (
        df.get("conso_critique_kWh", 0).fillna(0)
        + df.get("conso_non_critique_kWh", 0).fillna(0)
    )
    df["hour"] = df.index.hour
    df["dayofweek"] = df.index.dayofweek
    df["is_weekend"] = df["dayofweek"].isin([5, 6]).astype(int)
    df["month"] = df.index.month
    df["is_night"] = df["hour"].isin([22, 23, 0, 1, 2, 3, 4, 5]).astype(int)
    target = df["total_consumption_kWh"]
    df["lag_6h"] = target.shift(1)
    df["lag_12h"] = target.shift(2)
    df["lag_24h"] = target.shift(4)
    df["roll_mean_24h"] = target.shift(1).rolling(window=4, min_periods=1).mean()
    df["roll_std_24h"] = target.shift(1).rolling(window=4, min_periods=1).std()
    df["target_total_consumption_kWh"] = target.shift(-1)
    return df


def _select_features(df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series, List[str]]:
    df = _build_event_features(df)
    df = _add_time_features(df)
    df = df.dropna()
    target_col = "target_total_consumption_kWh"
    feature_cols = [
        col
        for col in df.columns
        if col not in {
            target_col,
        }
    ]
    X = df[feature_cols]
    y = df[target_col]
    return X, y, feature_cols


def build_dataset() -> Tuple[pd.DataFrame, pd.Series, List[str]]:
    """Build feature matrix and target series from raw data."""
    frames = load_raw_frames()
    merged = _merge_frames(frames)
    X, y, feature_cols = _select_features(merged)
    merged_path = CLEAN_DIR / "merged.parquet"
    features_path = CLEAN_DIR / "features.parquet"

    merged.to_parquet(merged_path, engine="pyarrow")
    features_df = X.copy()
    features_df["target"] = y
    features_df.to_parquet(features_path, engine="pyarrow")

    LOGGER.info(
        "Saved merged dataset to %s and features to %s. Rows: %d, Features: %d",
        merged_path,
        features_path,
        len(X),
        len(feature_cols),
    )
    return X, y, feature_cols


def main() -> None:
    try:
        build_dataset()
    except Exception as exc:
        LOGGER.error("Failed to build dataset: %s", exc)
        raise


if __name__ == "__main__":
    main()

