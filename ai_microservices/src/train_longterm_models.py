"""
Script pour entraîner les modèles de prédiction long terme avec des données synthétiques
"""
from __future__ import annotations

import random
from datetime import datetime, timedelta
from typing import Dict, List

import numpy as np
from .longterm_predictor import train_longterm_models
from .utils import get_logger

LOGGER = get_logger(__name__)


def generate_synthetic_historical_data(num_days: int = 30) -> List[Dict]:
    """
    Génère des données historiques synthétiques pour entraîner les modèles long terme
    Simule des patterns réalistes de consommation et production PV
    """
    historical_data = []
    base_date = datetime.now() - timedelta(days=num_days)
    
    # Consommation de base selon le jour de la semaine (weekend plus faible)
    # Production PV selon la saison et l'irradiation
    
    for i in range(num_days):
        current_date = base_date + timedelta(days=i)
        day_of_week = current_date.weekday()
        is_weekend = day_of_week >= 5
        
        # Consommation avec variations réalistes
        # Base: 5000 kWh/jour, variations jour/nuit et jour semaine/weekend
        base_consumption = 5000.0
        weekend_factor = 0.85 if is_weekend else 1.0
        seasonal_factor = 1.0 + 0.2 * np.sin(2 * np.pi * current_date.timetuple().tm_yday / 365.0)
        daily_variation = random.uniform(0.9, 1.1)
        
        consumption = base_consumption * weekend_factor * seasonal_factor * daily_variation
        
        # Production PV avec variations réalistes
        # Base: 3000 kWh/jour, dépend de l'irradiation et des saisons
        base_pv = 3000.0
        # Plus de production en été (jour 180 = mi-année)
        summer_factor = 1.0 + 0.3 * np.sin(2 * np.pi * current_date.timetuple().tm_yday / 365.0 + np.pi/2)
        weather_factor = random.uniform(0.7, 1.0)  # Nuages, etc.
        daily_pv_variation = random.uniform(0.85, 1.15)
        
        pv_production = base_pv * summer_factor * weather_factor * daily_pv_variation
        
        # Température et irradiation
        temperature = 20.0 + 10.0 * np.sin(2 * np.pi * current_date.timetuple().tm_yday / 365.0) + random.uniform(-3, 3)
        irradiance = 5.0 * summer_factor * weather_factor * random.uniform(0.9, 1.1)
        
        historical_data.append({
            "consumption": float(consumption),
            "pv_production": float(pv_production),
            "temperature": float(temperature),
            "irradiance": float(irradiance),
            "datetime": current_date.isoformat(),
        })
    
    return historical_data


def main():
    """Génère des données et entraîne les modèles long terme"""
    LOGGER.info("Génération de données historiques synthétiques...")
    
    # Générer 30 jours de données historiques
    historical_data = generate_synthetic_historical_data(num_days=30)
    
    LOGGER.info("Données générées: %d jours", len(historical_data))
    
    # Afficher quelques statistiques
    consumption_values = [d["consumption"] for d in historical_data]
    pv_values = [d["pv_production"] for d in historical_data]
    LOGGER.info("Consommation - Min: %.2f, Max: %.2f, Moyenne: %.2f", 
                min(consumption_values), max(consumption_values), np.mean(consumption_values))
    LOGGER.info("Production PV - Min: %.2f, Max: %.2f, Moyenne: %.2f", 
                min(pv_values), max(pv_values), np.mean(pv_values))
    
    # Entraîner les modèles
    LOGGER.info("Entraînement des modèles long terme...")
    result = train_longterm_models(historical_data)
    
    if result.get("status") == "trained":
        LOGGER.info("Modèles long terme entraînés avec succès!")
        LOGGER.info("Métriques: %s", result.get("metrics"))
    else:
        LOGGER.error("Échec de l'entraînement: %s", result.get("message"))


if __name__ == "__main__":
    main()



















