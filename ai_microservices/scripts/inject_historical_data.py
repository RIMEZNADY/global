"""
Script pour injecter des données historiques réalistes pour améliorer les prédictions AI
"""
import sys
import os
from pathlib import Path
from datetime import datetime, timedelta
import random
import numpy as np
import pandas as pd

# Ajouter le répertoire src au path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(project_root / "src"))

# Imports après ajout au path
from src.data_prep import build_dataset


def generate_realistic_historical_data(
    base_consumption: float = 3000.0,  # kWh/jour de base
    base_pv: float = 2800.0,  # kWh/jour de base
    days: int = 30,
    start_date: datetime = None
) -> list:
    """
    Génère des données historiques réalistes avec variations journalières et hebdomadaires
    """
    if start_date is None:
        start_date = datetime.now() - timedelta(days=days)
    
    historical_data = []
    
    for day in range(days):
        current_date = start_date + timedelta(days=day)
        day_of_week = current_date.weekday()
        month = current_date.month
        
        # Variations hebdomadaires (weekend = moins de consommation)
        weekday_factor = 0.85 if day_of_week >= 5 else 1.0
        
        # Variations saisonnières (été = plus de consommation AC)
        seasonal_factor = 1.15 if month in [6, 7, 8] else 0.95 if month in [12, 1, 2] else 1.0
        
        # Variations aléatoires quotidiennes (±15%)
        daily_variation = random.uniform(0.85, 1.15)
        
        # Variation pour PV (basée sur météo simulée)
        weather_factor = random.uniform(0.7, 1.3)  # Nuages, soleil, etc.
        seasonal_pv_factor = 1.2 if month in [5, 6, 7] else 0.8 if month in [12, 1] else 1.0
        
        # Calculer consommation et production avec variations
        consumption = base_consumption * weekday_factor * seasonal_factor * daily_variation
        pv_production = base_pv * weather_factor * seasonal_pv_factor
        
        # Ajouter des variations horaires simulées (moyenne sur 24h)
        hourly_variations = np.random.normal(1.0, 0.1, 24)
        consumption = consumption * np.mean(hourly_variations)
        
        historical_data.append({
            "datetime": current_date.isoformat(),
            "consumption": round(consumption, 2),
            "pv_production": round(max(0, pv_production), 2),
            "temperature_C": round(random.uniform(15, 35), 1),
            "irradiance_kWh_m2": round(random.uniform(4.0, 7.0), 2),
            "patients": random.randint(80, 120),
            "soc_batterie_kWh": round(random.uniform(20, 80), 1),
        })
    
    return historical_data


def inject_data_to_parquet(output_path: Path = None):
    """
    Injecte des données historiques dans le fichier parquet
    """
    if output_path is None:
        output_path = Path(__file__).parent.parent / "data_clean" / "merged.parquet"
    
    # Générer plusieurs séries de données pour différents établissements
    all_data = []
    
    # Hôpital type 1: Grand établissement
    hospital1_data = generate_realistic_historical_data(
        base_consumption=5000.0,
        base_pv=4500.0,
        days=60,
        start_date=datetime.now() - timedelta(days=60)
    )
    for entry in hospital1_data:
        entry["establishment_type"] = "HOPITAL"
        entry["number_of_beds"] = 200
    all_data.extend(hospital1_data)
    
    # Hôpital type 2: Moyen établissement
    hospital2_data = generate_realistic_historical_data(
        base_consumption=3000.0,
        base_pv=2800.0,
        days=60,
        start_date=datetime.now() - timedelta(days=60)
    )
    for entry in hospital2_data:
        entry["establishment_type"] = "HOPITAL"
        entry["number_of_beds"] = 100
    all_data.extend(hospital2_data)
    
    # Centre de santé
    center_data = generate_realistic_historical_data(
        base_consumption=1500.0,
        base_pv=1400.0,
        days=60,
        start_date=datetime.now() - timedelta(days=60)
    )
    for entry in center_data:
        entry["establishment_type"] = "CENTRE_SANTE"
        entry["number_of_beds"] = 50
    all_data.extend(center_data)
    
    # Convertir en DataFrame
    df = pd.DataFrame(all_data)
    
    # Ajouter des colonnes nécessaires
    if "total_consumption_kWh" not in df.columns:
        df["total_consumption_kWh"] = df["consumption"]
    
    if "pv_prod_kWh" not in df.columns:
        df["pv_prod_kWh"] = df["pv_production"]
    
    # Sauvegarder
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(output_path, index=False)
    print(f"[OK] Donnees historiques injectees: {len(df)} entrees dans {output_path}")
    
    return df


def train_models_with_injected_data():
    """
    Entraîne les modèles avec les données injectées
    """
    print("[INFO] Entrainement des modeles avec les nouvelles donnees...")
    
    # Reconstruire le dataset
    build_dataset()
    
    # Importer et entraîner les modèles
    from src.train_model import train_model
    from src.train_longterm_models import train_longterm_models
    
    print("[INFO] Entrainement du modele principal...")
    train_model()
    
    print("[INFO] Entrainement des modeles long terme...")
    # Générer des données d'entraînement pour long terme
    training_data = []
    for i in range(30):
        training_data.append({
            "datetime": (datetime.now() - timedelta(days=30-i)).isoformat(),
            "consumption": random.uniform(2500, 3500),
            "pv_production": random.uniform(2300, 3200),
            "temperature_C": random.uniform(18, 32),
            "irradiance_kWh_m2": random.uniform(4.5, 6.5),
        })
    
    train_longterm_models(training_data)
    
    print("[OK] Modeles entraines avec succes!")


if __name__ == "__main__":
    print("[INFO] Injection de donnees historiques realistes...")
    
    # Injecter les données
    df = inject_data_to_parquet()
    
    # Entraîner les modèles
    train_models_with_injected_data()
    
    print("\n[OK] Processus termine! Les predictions devraient maintenant etre plus variees.")

