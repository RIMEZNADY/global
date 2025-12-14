"""
Script pour générer des données d'entraînement et entraîner le modèle ROI
"""
from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Dict, List

import numpy as np
import pandas as pd
from .utils import get_logger, resolve_path_from_env

LOGGER = get_logger(__name__)
DATA_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")


def generate_synthetic_training_data(num_samples: int = 200) -> List[Dict]:
    """
    Génère des données d'entraînement synthétiques pour le modèle ROI
    Basé sur des scénarios réalistes d'hôpitaux marocains
    """
    establishment_types = [
        "CHU", "HOPITAL_REGIONAL", "HOPITAL_PREFECTORAL", "HOPITAL_PROVINCIAL",
        "HOPITAL_GENERAL", "HOPITAL_SPECIALISE", "CENTRE_REGIONAL_ONCOLOGIE",
        "CENTRE_HEMODIALYSE", "CENTRE_REEDUCATION", "CENTRE_ADDICTOLOGIE",
        "CENTRE_SOINS_PALLIATIFS", "UMH", "UMP", "UPH", "CENTRE_SANTE_PRIMAIRE",
        "CLINIQUE_PRIVEE", "AUTRE"
    ]
    
    irradiation_classes = ["A", "B", "C", "D"]
    
    # Coefficients de coût et d'efficacité selon le type (TOUS les types couverts)
    type_multipliers = {
        # Types existants
        "CHU": {"beds": (500, 2000), "consumption": (80000, 300000), "roi_factor": 0.85},
        "HOPITAL_REGIONAL": {"beds": (200, 800), "consumption": (30000, 120000), "roi_factor": 0.90},
        "HOPITAL_PREFECTORAL": {"beds": (50, 300), "consumption": (10000, 50000), "roi_factor": 0.95},
        "HOPITAL_PROVINCIAL": {"beds": (30, 150), "consumption": (5000, 30000), "roi_factor": 0.95},
        "HOPITAL_GENERAL": {"beds": (100, 400), "consumption": (15000, 60000), "roi_factor": 0.92},
        "HOPITAL_SPECIALISE": {"beds": (50, 300), "consumption": (12000, 50000), "roi_factor": 0.90},
        # Centres spécialisés
        "CENTRE_REGIONAL_ONCOLOGIE": {"beds": (50, 200), "consumption": (15000, 80000), "roi_factor": 0.88},
        "CENTRE_HEMODIALYSE": {"beds": (10, 50), "consumption": (5000, 20000), "roi_factor": 0.92},
        "CENTRE_REEDUCATION": {"beds": (20, 100), "consumption": (3000, 15000), "roi_factor": 0.88},
        "CENTRE_ADDICTOLOGIE": {"beds": (15, 80), "consumption": (2500, 12000), "roi_factor": 0.85},
        "CENTRE_SOINS_PALLIATIFS": {"beds": (10, 50), "consumption": (2000, 10000), "roi_factor": 0.87},
        # Urgences
        "UMH": {"beds": (30, 150), "consumption": (8000, 35000), "roi_factor": 0.91},
        "UMP": {"beds": (20, 100), "consumption": (5000, 25000), "roi_factor": 0.93},
        "UPH": {"beds": (10, 50), "consumption": (3000, 15000), "roi_factor": 0.94},
        # Soins primaires
        "CENTRE_SANTE_PRIMAIRE": {"beds": (5, 30), "consumption": (1000, 8000), "roi_factor": 0.95},
        # Privé
        "CLINIQUE_PRIVEE": {"beds": (20, 150), "consumption": (8000, 40000), "roi_factor": 0.93},
        # Autre
        "AUTRE": {"beds": (10, 200), "consumption": (3000, 50000), "roi_factor": 0.90},
    }
    
    training_data = []
    
    for i in range(num_samples):
        # Sélectionner un type d'établissement
        establishment_type = random.choice(establishment_types)
        
        # Déterminer les paramètres selon le type
        if establishment_type in type_multipliers:
            params = type_multipliers[establishment_type]
            number_of_beds = random.randint(*params["beds"])
            monthly_consumption = random.uniform(*params["consumption"])
            roi_factor = params["roi_factor"]
        else:
            number_of_beds = random.randint(10, 500)
            monthly_consumption = random.uniform(3000, 100000)
            roi_factor = 0.90
        
        # Surface installable (10-5000 m²)
        installable_surface = random.uniform(100, min(5000, monthly_consumption / 20))
        
        # Classe d'irradiation
        irradiation_class = random.choice(irradiation_classes)
        
        # Calculer les recommandations (similaire à SizingService)
        # Puissance PV recommandée (kWc)
        daily_consumption = monthly_consumption / 30.0
        
        # Irradiance moyenne selon la classe (kWh/m²/jour)
        irradiance_map = {"A": 7.0, "B": 6.0, "C": 5.0, "D": 4.0}
        average_irradiance = irradiance_map.get(irradiation_class, 5.0)
        
        panel_efficiency = 0.20
        performance_factor = 0.80
        safety_factor = 1.3
        
        required_daily_production = daily_consumption
        recommended_pv_power = (required_daily_production / (average_irradiance * panel_efficiency * performance_factor)) * safety_factor
        
        # Capacité batterie recommandée (kWh)
        autonomy_days = 2.0
        recommended_battery = daily_consumption * autonomy_days * safety_factor
        
        # Autonomie énergétique (%)
        # Production mensuelle PV
        pv_surface = recommended_pv_power * 5.0  # ~5 m² par kWc
        monthly_pv_production = pv_surface * average_irradiance * panel_efficiency * performance_factor * 30
        
        autonomy = min(100.0, (monthly_pv_production / monthly_consumption) * 100.0) if monthly_consumption > 0 else 0.0
        
        # Calculer le ROI réel (avec un peu de variation réaliste)
        # Coût d'installation (DH)
        installation_cost = recommended_pv_power * 8000.0 + recommended_battery * 4500.0
        
        # Économies annuelles (avec variation selon irradiation et type)
        energy_price_per_kwh = 1.2  # Prix moyen au Maroc
        annual_savings = monthly_consumption * 12 * (autonomy / 100.0) * energy_price_per_kwh * roi_factor
        
        # Ajouter du bruit réaliste (±20%)
        annual_savings *= random.uniform(0.8, 1.2)
        
        # ROI en années
        roi_years = installation_cost / annual_savings if annual_savings > 0 else 999.0
        
        # Limiter ROI entre 2 et 25 ans (réaliste)
        roi_years = max(2.0, min(25.0, roi_years))
        
        training_data.append({
            "type": establishment_type,
            "numberOfBeds": number_of_beds,
            "monthlyConsumption": monthly_consumption,
            "installableSurface": installable_surface,
            "irradiationClass": irradiation_class,
            "recommendedPvPower": recommended_pv_power,
            "recommendedBattery": recommended_battery,
            "autonomy": autonomy,
            "roi": roi_years,
        })
    
    return training_data


def load_training_data() -> List[Dict]:
    """
    Charge les données d'entraînement ROI depuis le fichier sauvegardé si disponible,
    sinon génère des données synthétiques
    """
    # Essayer de charger depuis le fichier Parquet (plus rapide)
    parquet_file = DATA_DIR / "roi_training_dataset.parquet"
    if parquet_file.exists():
        LOGGER.info("Chargement du dataset depuis: %s", parquet_file)
        df = pd.read_parquet(parquet_file)
        training_data = df.to_dict('records')
        LOGGER.info("Dataset chargé: %d échantillons", len(training_data))
        return training_data
    
    # Essayer de charger depuis le fichier JSON
    json_file = DATA_DIR / "roi_training_dataset.json"
    if json_file.exists():
        LOGGER.info("Chargement du dataset depuis: %s", json_file)
        with open(json_file, 'r', encoding='utf-8') as f:
            training_data = json.load(f)
        LOGGER.info("Dataset chargé: %d échantillons", len(training_data))
        return training_data
    
    # Sinon, générer des données synthétiques (fallback)
    LOGGER.warning("Aucun dataset sauvegardé trouvé. Génération de données synthétiques...")
    LOGGER.warning("Pour améliorer les performances, exécutez: python scripts/generate_roi_training_dataset.py")
    return generate_synthetic_training_data(num_samples=200)


def main():
    """Charge les données et entraîne le modèle ROI"""
    from .ml_recommendations import train_roi_model as train_model_fn
    
    LOGGER.info("Chargement des données d'entraînement ROI...")
    
    # Charger ou générer les données
    training_data = load_training_data()
    
    LOGGER.info("Données prêtes: %d échantillons", len(training_data))
    
    # Afficher quelques statistiques
    roi_values = [d["roi"] for d in training_data]
    LOGGER.info("ROI - Min: %.2f, Max: %.2f, Moyenne: %.2f, Médiane: %.2f", 
                min(roi_values), max(roi_values), np.mean(roi_values), np.median(roi_values))
    
    # Entraîner le modèle
    LOGGER.info("Entraînement du modèle ROI...")
    result = train_model_fn(training_data)
    
    if result.get("status") == "trained":
        LOGGER.info("Modèle ROI entraîné avec succès!")
        LOGGER.info("Métriques: %s", result.get("metrics"))
    else:
        LOGGER.error("Échec de l'entraînement: %s", result)


if __name__ == "__main__":
    main()

