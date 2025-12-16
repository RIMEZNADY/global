"""
Script pour générer et sauvegarder un dataset synthétique complet pour l'entraînement ROI
Ce dataset couvre tous les types d'établissements avec de nombreuses variantes
"""
from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Dict, List

import numpy as np
import pandas as pd

# Ajouter le répertoire src au path
project_root = Path(__file__).parent.parent
import sys
sys.path.insert(0, str(project_root / "src"))

from src.utils import get_logger, resolve_path_from_env

LOGGER = get_logger(__name__)
DATA_DIR = resolve_path_from_env("DATA_CLEAN_DIR", "data_clean")
OUTPUT_FILE = DATA_DIR / "roi_training_dataset.json"


def generate_synthetic_training_data(num_samples: int = 1000) -> List[Dict]:
    """
    Génère un dataset synthétique complet pour l'entraînement ROI
    Couvre TOUS les types d'établissements avec de nombreuses variantes
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
    
    # Générer des échantillons équilibrés par type
    samples_per_type = max(50, num_samples // len(establishment_types))
    
    for establishment_type in establishment_types:
        for _ in range(samples_per_type):
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
            
            # Surface installable (variation réaliste)
            installable_surface = random.uniform(
                100, 
                min(5000, monthly_consumption / 15)  # Ratio surface/consommation réaliste
            )
            
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
            autonomy_days = random.uniform(1.5, 3.0)  # Variation de l'autonomie
            recommended_battery = daily_consumption * autonomy_days * safety_factor
            
            # Autonomie énergétique (%)
            # Production mensuelle PV
            pv_surface = recommended_pv_power * 5.0  # ~5 m² par kWc
            monthly_pv_production = pv_surface * average_irradiance * panel_efficiency * performance_factor * 30
            
            autonomy = min(100.0, (monthly_pv_production / monthly_consumption) * 100.0) if monthly_consumption > 0 else 0.0
            
            # Calculer le ROI réel (avec variation réaliste)
            # Coût d'installation (DH) - variations selon le marché
            pv_cost_per_kw = random.uniform(7500.0, 8500.0)  # Variation des prix
            battery_cost_per_kwh = random.uniform(4200.0, 4800.0)
            installation_cost = recommended_pv_power * pv_cost_per_kw + recommended_battery * battery_cost_per_kwh
            
            # Économies annuelles (avec variation selon irradiation et type)
            energy_price_per_kwh = random.uniform(1.1, 1.3)  # Variation des prix d'électricité
            annual_savings = monthly_consumption * 12 * (autonomy / 100.0) * energy_price_per_kwh * roi_factor
            
            # Ajouter du bruit réaliste (±15%)
            annual_savings *= random.uniform(0.85, 1.15)
            
            # ROI en années
            roi_years = installation_cost / annual_savings if annual_savings > 0 else 999.0
            
            # Limiter ROI entre 2 et 30 ans (réaliste)
            roi_years = max(2.0, min(30.0, roi_years))
            
            training_data.append({
                "type": establishment_type,
                "numberOfBeds": number_of_beds,
                "monthlyConsumption": round(monthly_consumption, 2),
                "installableSurface": round(installable_surface, 2),
                "irradiationClass": irradiation_class,
                "recommendedPvPower": round(recommended_pv_power, 2),
                "recommendedBattery": round(recommended_battery, 2),
                "autonomy": round(autonomy, 2),
                "roi": round(roi_years, 2),
            })
    
    # Ajouter quelques échantillons supplémentaires aléatoires pour diversité
    remaining = num_samples - len(training_data)
    if remaining > 0:
        for _ in range(remaining):
            establishment_type = random.choice(establishment_types)
            if establishment_type in type_multipliers:
                params = type_multipliers[establishment_type]
                number_of_beds = random.randint(*params["beds"])
                monthly_consumption = random.uniform(*params["consumption"])
                roi_factor = params["roi_factor"]
            else:
                number_of_beds = random.randint(10, 500)
                monthly_consumption = random.uniform(3000, 100000)
                roi_factor = 0.90
            
            installable_surface = random.uniform(100, min(5000, monthly_consumption / 15))
            irradiation_class = random.choice(irradiation_classes)
            daily_consumption = monthly_consumption / 30.0
            irradiance_map = {"A": 7.0, "B": 6.0, "C": 5.0, "D": 4.0}
            average_irradiance = irradiance_map.get(irradiation_class, 5.0)
            
            panel_efficiency = 0.20
            performance_factor = 0.80
            safety_factor = 1.3
            recommended_pv_power = (daily_consumption / (average_irradiance * panel_efficiency * performance_factor)) * safety_factor
            recommended_battery = daily_consumption * random.uniform(1.5, 3.0) * safety_factor
            
            pv_surface = recommended_pv_power * 5.0
            monthly_pv_production = pv_surface * average_irradiance * panel_efficiency * performance_factor * 30
            autonomy = min(100.0, (monthly_pv_production / monthly_consumption) * 100.0) if monthly_consumption > 0 else 0.0
            
            installation_cost = recommended_pv_power * random.uniform(7500.0, 8500.0) + recommended_battery * random.uniform(4200.0, 4800.0)
            energy_price_per_kwh = random.uniform(1.1, 1.3)
            annual_savings = monthly_consumption * 12 * (autonomy / 100.0) * energy_price_per_kwh * roi_factor * random.uniform(0.85, 1.15)
            roi_years = max(2.0, min(30.0, installation_cost / annual_savings if annual_savings > 0 else 999.0))
            
            training_data.append({
                "type": establishment_type,
                "numberOfBeds": number_of_beds,
                "monthlyConsumption": round(monthly_consumption, 2),
                "installableSurface": round(installable_surface, 2),
                "irradiationClass": irradiation_class,
                "recommendedPvPower": round(recommended_pv_power, 2),
                "recommendedBattery": round(recommended_battery, 2),
                "autonomy": round(autonomy, 2),
                "roi": round(roi_years, 2),
            })
    
    return training_data


def main():
    """Génère et sauvegarde le dataset d'entraînement ROI"""
    LOGGER.info("Génération du dataset d'entraînement ROI...")
    
    # Générer 1200 échantillons (assez pour couvrir tous les types avec variantes)
    training_data = generate_synthetic_training_data(num_samples=1200)
    
    LOGGER.info("Dataset généré: %d échantillons", len(training_data))
    
    # Statistiques par type
    type_counts = {}
    roi_by_type = {}
    for data in training_data:
        t = data["type"]
        type_counts[t] = type_counts.get(t, 0) + 1
        if t not in roi_by_type:
            roi_by_type[t] = []
        roi_by_type[t].append(data["roi"])
    
    LOGGER.info("Répartition par type:")
    for t, count in sorted(type_counts.items()):
        avg_roi = np.mean(roi_by_type[t])
        min_roi = np.min(roi_by_type[t])
        max_roi = np.max(roi_by_type[t])
        LOGGER.info("  %s: %d échantillons, ROI moyen=%.2f ans (min=%.2f, max=%.2f)", 
                    t, count, avg_roi, min_roi, max_roi)
    
    # Statistiques globales
    roi_values = [d["roi"] for d in training_data]
    LOGGER.info("ROI global - Min: %.2f, Max: %.2f, Moyenne: %.2f, Médiane: %.2f", 
                min(roi_values), max(roi_values), np.mean(roi_values), np.median(roi_values))
    
    # Sauvegarder dans un fichier JSON
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(training_data, f, indent=2, ensure_ascii=False)
    
    LOGGER.info("Dataset sauvegardé dans: %s", OUTPUT_FILE)
    LOGGER.info("Taille du fichier: %.2f KB", OUTPUT_FILE.stat().st_size / 1024)
    
    # Aussi sauvegarder en Parquet pour meilleure performance
    df = pd.DataFrame(training_data)
    parquet_file = DATA_DIR / "roi_training_dataset.parquet"
    df.to_parquet(parquet_file, index=False)
    LOGGER.info("Dataset sauvegardé aussi en Parquet: %s (%.2f KB)", 
                parquet_file, parquet_file.stat().st_size / 1024)


if __name__ == "__main__":
    main()











