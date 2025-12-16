"""
Module pour les prédictions saisonnières (été, hiver, printemps, automne)
"""
from __future__ import annotations

from datetime import datetime, timedelta
from typing import Dict, List
import numpy as np

from .longterm_predictor import predict_longterm
from .utils import get_logger

LOGGER = get_logger(__name__)


def get_season_dates(year: int, season: str) -> tuple[datetime, datetime]:
    """
    Retourne les dates de début et fin d'une saison
    """
    if season.lower() == "ete" or season.lower() == "summer":
        # Été: 21 juin - 22 septembre
        start = datetime(year, 6, 21)
        end = datetime(year, 9, 22)
    elif season.lower() == "hiver" or season.lower() == "winter":
        # Hiver: 21 décembre - 20 mars
        start = datetime(year, 12, 21)
        end = datetime(year + 1, 3, 20)
    elif season.lower() == "printemps" or season.lower() == "spring":
        # Printemps: 20 mars - 20 juin
        start = datetime(year, 3, 20)
        end = datetime(year, 6, 20)
    elif season.lower() == "automne" or season.lower() == "autumn" or season.lower() == "fall":
        # Automne: 22 septembre - 20 décembre
        start = datetime(year, 9, 22)
        end = datetime(year, 12, 20)
    else:
        raise ValueError(f"Saison inconnue: {season}")
    
    return start, end


def predict_seasonal(
    historical_data: List[Dict],
    season: str,
    year: int = None,
) -> Dict:
    """
    Prédit consommation et production PV pour une saison spécifique
    
    Args:
        historical_data: Données historiques
        season: Saison ("ete", "hiver", "printemps", "automne")
        year: Année pour la prédiction (défaut: année actuelle)
    
    Returns:
        Dict avec predictions pour toute la saison
    """
    if year is None:
        year = datetime.now().year
    
    start_date, end_date = get_season_dates(year, season)
    horizon_days = (end_date - start_date).days
    
    if horizon_days <= 0:
        # Si on est déjà dans la saison, prédire jusqu'à la fin
        if datetime.now() >= start_date and datetime.now() <= end_date:
            horizon_days = (end_date - datetime.now()).days
        else:
            # Prédire toute la saison
            horizon_days = (end_date - start_date).days
    
    # Filtrer les données historiques pour la même saison des années précédentes
    seasonal_historical = []
    for entry in historical_data:
        entry_date = datetime.fromisoformat(entry.get("datetime", "").replace("Z", "+00:00"))
        entry_date = entry_date.replace(tzinfo=None)
        
        # Vérifier si cette entrée correspond à la même saison
        entry_season = _get_season_from_date(entry_date)
        if entry_season.lower() == season.lower():
            seasonal_historical.append(entry)
    
    # Si pas assez de données saisonnières, utiliser toutes les données
    if len(seasonal_historical) < 7:
        seasonal_historical = historical_data
        LOGGER.info(f"Pas assez de données pour la saison {season}, utilisation de toutes les données historiques")
    
    # Ajuster les prédictions avec des facteurs saisonniers spécifiques
    result = predict_longterm(seasonal_historical, horizon_days=min(horizon_days, 90))
    
    # Appliquer des facteurs saisonniers supplémentaires
    season_factors = _get_seasonal_factors(season)
    
    adjusted_predictions = []
    for pred in result.get("predictions", []):
        day = pred.get("day", 1)
        pred_date = start_date + timedelta(days=day - 1)
        
        # Facteurs saisonniers pour consommation et PV
        cons_factor = season_factors["consumption"]
        pv_factor = season_factors["pv"]
        
        # Ajuster selon le jour de la semaine
        day_of_week = pred_date.weekday()
        weekday_factor = 0.85 if day_of_week >= 5 else 1.0
        
        adjusted_consumption = pred.get("predicted_consumption", 0.0) * cons_factor * weekday_factor
        adjusted_pv = pred.get("predicted_pv_production", 0.0) * pv_factor
        
        adjusted_predictions.append({
            "day": day,
            "date": pred_date.isoformat(),
            "predicted_consumption": float(adjusted_consumption),
            "predicted_pv_production": float(adjusted_pv),
        })
    
    return {
        "season": season,
        "year": year,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "predictions": adjusted_predictions,
        "confidence_intervals": result.get("confidence_intervals", []),
        "trend": result.get("trend", "stable"),
        "method": result.get("method", "seasonal_adjusted"),
        "seasonal_factors": season_factors,
    }


def _get_season_from_date(date: datetime) -> str:
    """Détermine la saison à partir d'une date"""
    month = date.month
    day = date.day
    
    if (month == 3 and day >= 20) or (month in [4, 5]) or (month == 6 and day < 21):
        return "printemps"
    elif (month == 6 and day >= 21) or (month in [7, 8]) or (month == 9 and day < 22):
        return "ete"
    elif (month == 9 and day >= 22) or (month in [10, 11]) or (month == 12 and day < 21):
        return "automne"
    else:
        return "hiver"


def _get_seasonal_factors(season: str) -> Dict[str, float]:
    """
    Retourne les facteurs de correction saisonniers
    Basés sur les patterns observés au Maroc
    """
    factors = {
        "ete": {
            "consumption": 1.15,  # +15% consommation (climatisation)
            "pv": 1.25,  # +25% production PV (plus de soleil)
        },
        "hiver": {
            "consumption": 1.05,  # +5% consommation (chauffage)
            "pv": 0.75,  # -25% production PV (moins de soleil, jours plus courts)
        },
        "printemps": {
            "consumption": 0.95,  # -5% consommation (température modérée)
            "pv": 1.10,  # +10% production PV (bon ensoleillement)
        },
        "automne": {
            "consumption": 0.98,  # Légèrement moins
            "pv": 0.90,  # -10% production PV (jours qui raccourcissent)
        },
    }
    
    season_key = season.lower()
    if season_key in factors:
        return factors[season_key]
    
    # Par défaut
    return {"consumption": 1.0, "pv": 1.0}














