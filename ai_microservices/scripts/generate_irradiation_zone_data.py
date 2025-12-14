"""
Script pour générer des données météorologiques et PV pour les zones d'irradiation A, B, D
basées sur les données existantes de Casablanca (zone C).
"""

import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime, timedelta

# Configuration des chemins
RAW_DIR = Path(__file__).parent.parent / "data_raw"
RAW_DIR.mkdir(parents=True, exist_ok=True)

# Charger les données de référence (Casablanca - Classe C)
print("Chargement des données de référence (Casablanca - Classe C)...")
casablanca_meteo = pd.read_csv(RAW_DIR / "casablanca_meteo_2024_6h.csv")
casablanca_pv = pd.read_csv(RAW_DIR / "casablanca_pv_2024_6h.csv")

# Convertir datetime
casablanca_meteo['datetime'] = pd.to_datetime(casablanca_meteo['datetime'])
casablanca_pv['datetime'] = pd.to_datetime(casablanca_pv['datetime'])

print(f"Données chargées: {len(casablanca_meteo)} lignes météo, {len(casablanca_pv)} lignes PV")

# Configuration des zones d'irradiation
ZONE_CONFIG = {
    'A': {
        'name': 'zone_a_sahara',
        'irradiance_multiplier': 1.5,  # 6-7 kWh/m²/jour vs 4-5 pour C
        'temp_offset': 8.0,  # Plus chaud (Sahara)
        'temp_variation': 1.2,  # Variations plus importantes
        'pv_multiplier': 1.5,  # Production PV proportionnelle à l'irradiance
    },
    'B': {
        'name': 'zone_b_centre',
        'irradiance_multiplier': 1.2,  # 5-6 kWh/m²/jour
        'temp_offset': 3.0,  # Légèrement plus chaud
        'temp_variation': 1.0,
        'pv_multiplier': 1.2,
    },
    'D': {
        'name': 'zone_d_rif',
        'irradiance_multiplier': 0.75,  # 3-4 kWh/m²/jour
        'temp_offset': -4.0,  # Plus froid (altitudes)
        'temp_variation': 1.1,  # Variations saisonnières plus importantes
        'pv_multiplier': 0.75,
    }
}

def generate_zone_data(zone_letter: str, config: dict):
    """Génère les données météo et PV pour une zone d'irradiation."""
    print(f"\n{'='*60}")
    print(f"Génération des données pour la Zone {zone_letter} ({config['name']})")
    print(f"{'='*60}")
    
    # Copier les données de base
    meteo = casablanca_meteo.copy()
    pv = casablanca_pv.copy()
    
    # Ajuster l'irradiance
    print(f"  - Ajustement de l'irradiance (multiplicateur: {config['irradiance_multiplier']:.2f})")
    meteo['irradiance_kWh_m2'] = meteo['irradiance_kWh_m2'] * config['irradiance_multiplier']
    
    # Ajuster la température
    print(f"  - Ajustement de la température (offset: {config['temp_offset']:.1f}°C)")
    meteo['temperature_C'] = meteo['temperature_C'] + config['temp_offset']
    
    # Ajouter des variations saisonnières pour la température
    if config['temp_variation'] != 1.0:
        meteo['month'] = meteo['datetime'].dt.month
        # Variations saisonnières plus importantes pour certaines zones
        seasonal_factor = 1 + (np.sin(2 * np.pi * (meteo['month'] - 1) / 12) * (config['temp_variation'] - 1))
        meteo['temperature_C'] = meteo['temperature_C'] * seasonal_factor
        meteo = meteo.drop('month', axis=1)
    
    # Ajuster la production PV proportionnellement à l'irradiance
    print(f"  - Ajustement de la production PV (multiplicateur: {config['pv_multiplier']:.2f})")
    pv['pv_prod_kWh'] = pv['pv_prod_kWh'] * config['pv_multiplier']
    
    # S'assurer que les valeurs sont positives
    meteo['irradiance_kWh_m2'] = meteo['irradiance_kWh_m2'].clip(lower=0)
    meteo['temperature_C'] = meteo['temperature_C'].clip(lower=-10, upper=50)  # Plage réaliste
    pv['pv_prod_kWh'] = pv['pv_prod_kWh'].clip(lower=0)
    
    # Sauvegarder les fichiers
    meteo_filename = f"{config['name']}_meteo_2024_6h.csv"
    pv_filename = f"{config['name']}_pv_2024_6h.csv"
    
    # Formater datetime pour la météo (format original)
    meteo_output = meteo.copy()
    meteo_output['datetime'] = meteo_output['datetime'].dt.strftime('%m/%d/%Y')
    
    # Formater datetime pour PV (format ISO)
    pv_output = pv.copy()
    pv_output['datetime'] = pv_output['datetime'].dt.strftime('%Y-%m-%d %H:%M:%S')
    
    meteo_path = RAW_DIR / meteo_filename
    pv_path = RAW_DIR / pv_filename
    
    meteo_output.to_csv(meteo_path, index=False)
    pv_output.to_csv(pv_path, index=False)
    
    print(f"  ✓ Fichier météo sauvegardé: {meteo_filename} ({len(meteo)} lignes)")
    print(f"  ✓ Fichier PV sauvegardé: {pv_filename} ({len(pv)} lignes)")
    
    # Statistiques
    print(f"\n  Statistiques Zone {zone_letter}:")
    print(f"    - Irradiance moyenne: {meteo['irradiance_kWh_m2'].mean():.2f} kWh/m²")
    print(f"    - Irradiance max: {meteo['irradiance_kWh_m2'].max():.2f} kWh/m²")
    print(f"    - Température moyenne: {meteo['temperature_C'].mean():.1f}°C")
    print(f"    - Température min/max: {meteo['temperature_C'].min():.1f}°C / {meteo['temperature_C'].max():.1f}°C")
    print(f"    - Production PV moyenne: {pv['pv_prod_kWh'].mean():.2f} kWh")
    print(f"    - Production PV max: {pv['pv_prod_kWh'].max():.2f} kWh")
    
    return meteo_path, pv_path

def main():
    """Génère les données pour toutes les zones."""
    print("\n" + "="*60)
    print("GÉNÉRATION DES DONNÉES POUR LES ZONES D'IRRADIATION")
    print("="*60)
    print("\nZones à générer:")
    print("  - Zone A: Très élevée (Sud-Est, Sahara) - 6-7 kWh/m²/jour")
    print("  - Zone B: Élevée (Centre, Sud) - 5-6 kWh/m²/jour")
    print("  - Zone C: Moyenne (Casablanca) - 4-5 kWh/m²/jour [DONNÉES EXISTANTES]")
    print("  - Zone D: Faible (Rif, Hautes altitudes) - 3-4 kWh/m²/jour")
    
    generated_files = []
    
    for zone_letter, config in ZONE_CONFIG.items():
        meteo_path, pv_path = generate_zone_data(zone_letter, config)
        generated_files.extend([meteo_path, pv_path])
    
    print("\n" + "="*60)
    print("GÉNÉRATION TERMINÉE")
    print("="*60)
    print(f"\nFichiers générés ({len(generated_files)} fichiers):")
    for file_path in generated_files:
        print(f"  ✓ {file_path.name}")
    
    print("\n" + "="*60)
    print("PROCHAINES ÉTAPES")
    print("="*60)
    print("1. Les fichiers CSV sont prêts dans le dossier 'data_raw'")
    print("2. Mettre à jour 'data_prep.py' pour charger les données selon la zone")
    print("3. Ou créer un service backend qui sélectionne les données selon la classe d'irradiation")

if __name__ == "__main__":
    main()


