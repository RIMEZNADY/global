# Documentation des Fichiers CSV Utilisés

Ce document liste tous les fichiers CSV utilisés dans le projet Smart Microgrid pour l'entraînement des modèles ML et la génération des résultats.

## 📁 Emplacement
Tous les fichiers CSV sont situés dans : `ai_microservices/data_raw/`

---

## 📊 Fichiers CSV Principaux (Casablanca - CHU)

### 1. **casablanca_meteo_2024_6h.csv**
- **Description** : Données météorologiques pour Casablanca (2024, résolution 6h)
- **Colonnes requises** :
  - `datetime` : Date et heure (format ISO)
  - `temperature_C` : Température en degrés Celsius
  - `irradiance_kWh_m2` : Irradiance solaire en kWh/m²
- **Utilisation** : 
  - Entraînement du modèle de prédiction de consommation
  - Prédiction de production PV
  - Calculs d'optimisation énergétique

### 2. **casablanca_pv_2024_6h.csv**
- **Description** : Production photovoltaïque pour Casablanca (2024, résolution 6h)
- **Colonnes requises** :
  - `datetime` : Date et heure
  - `pv_prod_kWh` : Production PV en kWh
- **Utilisation** :
  - Entraînement du modèle de prédiction PV
  - Prédictions de production solaire
  - Optimisation de l'utilisation de l'énergie

### 3. **chu_critique_non_critique.csv**
- **Description** : Consommation énergétique du CHU (Casablanca) - zones critiques et non-critiques
- **Colonnes requises** :
  - `datetime` : Date et heure
  - `temperature_C` : Température
  - `irradiance_kWh_m2` : Irradiance
  - `conso_critique_kWh` : Consommation des zones critiques (kWh)
  - `conso_non_critique_kWh` : Consommation des zones non-critiques (kWh)
- **Utilisation** :
  - Modèle principal de prédiction de consommation
  - Calculs d'optimisation énergétique
  - Détection d'anomalies

### 4. **chu_events_casablanca_6h.csv**
- **Description** : Événements spéciaux au CHU de Casablanca
- **Colonnes requises** :
  - `datetime` : Date et heure
  - `event` : Description de l'événement (ex: "urgence", "maintenance", etc.)
- **Utilisation** :
  - Prise en compte des événements dans les prédictions
  - Ajustement des modèles selon le contexte

### 5. **chu_patient.csv**
- **Description** : Nombre de patients au CHU
- **Colonnes requises** :
  - `datetime` : Date et heure
  - `patients` : Nombre de patients
- **Utilisation** :
  - Prédiction de consommation (corrélation avec le nombre de patients)
  - Optimisation selon la charge hospitalière

### 6. **soc.csv** (State of Charge)
- **Description** : État de charge de la batterie et données agrégées
- **Colonnes requises** :
  - `datetime` : Date et heure
  - `temperature_C` : Température
  - `irradiance_kWh_m2` : Irradiance
  - `pv_prod_kWh` : Production PV
  - `conso_critique_kWh` : Consommation critique
  - `conso_non_critique_kWh` : Consommation non-critique
  - `soc_batterie_kWh` : État de charge de la batterie (kWh)
- **Utilisation** :
  - Modèle principal d'entraînement (dataset complet)
  - Prédictions de consommation globale
  - Optimisation de la gestion de la batterie

---

## 🌍 Fichiers CSV par Zone Géographique

### Zone A - Sahara
- **zone_a_sahara_meteo_2024_6h.csv** : Données météorologiques
- **zone_a_sahara_pv_2024_6h.csv** : Production PV

### Zone B - Centre
- **zone_b_centre_meteo_2024_6h.csv** : Données météorologiques
- **zone_b_centre_pv_2024_6h.csv** : Production PV

### Zone D - Rif
- **zone_d_rif_meteo_2024_6h.csv** : Données météorologiques
- **zone_d_rif_pv_2024_6h.csv** : Production PV

**Utilisation des zones** :
- Entraînement du modèle de prédiction PV multi-zones
- Généralisation des modèles à différentes régions
- Prédictions régionales

---

## 🔄 Pipeline de Traitement

### 1. Chargement des données (`data_prep.py`)
```python
# Les fichiers CSV sont chargés via load_raw_frames()
# Vérification des colonnes requises
# Conversion des dates en format datetime
```

### 2. Nettoyage et fusion (`data_prep.py`)
- Fusion des données par `datetime`
- Création de features (moyennes mobiles, dérivées, etc.)
- Export en format Parquet : `data_clean/features.parquet` et `data_clean/merged.parquet`

### 3. Entraînement des modèles (`train_model.py`, `pv_predictor.py`)
- Modèle de consommation : utilise `soc.csv` et `chu_critique_non_critique.csv`
- Modèle PV : utilise tous les fichiers `*_pv_2024_6h.csv` et `*_meteo_2024_6h.csv`
- Modèle ROI : utilise des données synthétiques générées

### 4. Prédictions (`api.py`)
- Les modèles entraînés utilisent les données historiques pour faire des prédictions
- Les fichiers CSV servent de base de référence pour les calculs

---

## 📈 Modèles Utilisant les CSV

| Modèle | Fichiers CSV Utilisés |
|--------|----------------------|
| **Prédiction Consommation** | `soc.csv`, `chu_critique_non_critique.csv`, `chu_patient.csv`, `chu_events_casablanca_6h.csv` |
| **Prédiction PV** | `casablanca_pv_2024_6h.csv`, `zone_*_pv_2024_6h.csv`, `*_meteo_2024_6h.csv` |
| **Optimisation Énergétique** | Tous les fichiers (via `soc.csv` et données fusionnées) |
| **Détection d'Anomalies** | `soc.csv`, `chu_critique_non_critique.csv` |
| **Prédiction Long Terme** | `soc.csv`, données historiques agrégées |

---

## 🎯 Résultats Générés

Les fichiers CSV permettent de générer :

1. **Prédictions de consommation** (kWh) pour les prochaines heures/jours
2. **Prédictions de production PV** (kWh) selon les conditions météo
3. **Recommandations d'optimisation** :
   - Quand charger/décharger la batterie
   - Quand utiliser le réseau électrique
   - Gestion des zones critiques vs non-critiques
4. **Détection d'anomalies** dans la consommation ou la production
5. **Calculs de ROI** (Return on Investment) pour les équipements
6. **Prédictions long terme** (semaines/mois) pour la planification

---

## 📝 Format des Données

### Structure commune :
- **Résolution temporelle** : 6 heures (données toutes les 6h)
- **Format datetime** : ISO 8601 (ex: `2024-01-01T00:00:00+00:00`)
- **Période** : 2024 (année complète)
- **Encodage** : UTF-8

### Exemple de ligne :
```csv
datetime,temperature_C,irradiance_kWh_m2,pv_prod_kWh,conso_critique_kWh,conso_non_critique_kWh,soc_batterie_kWh
2024-01-01T00:00:00+00:00,15.5,0.0,0.0,120.5,80.3,150.0
```

---

## ⚠️ Notes Importantes

1. **Tous les fichiers CSV doivent être présents** dans `data_raw/` pour que le pipeline fonctionne
2. **Les colonnes requises doivent être exactement nommées** comme spécifié
3. **Les dates doivent être au format ISO 8601** avec timezone UTC
4. **Les valeurs numériques** doivent être des nombres (pas de texte)
5. **Les fichiers sont traités automatiquement** lors de l'entraînement des modèles

---

## 🔧 Commandes pour Utiliser les Données

```bash
# Préparer les données (charge et nettoie les CSV)
python -m src.data_prep

# Entraîner le modèle principal
python -m src.train_model

# Entraîner le modèle PV
python -m src.pv_predictor

# Démarrer l'API (charge automatiquement les données si nécessaire)
python -m uvicorn src.api:app --reload
```

---

## 📊 Statistiques des Fichiers

| Fichier | Taille | Lignes (approx) |
|---------|--------|-----------------|
| `soc.csv` | 133 KB | ~1460 (année 2024, 6h) |
| `chu_critique_non_critique.csv` | 77 KB | ~1460 |
| `casablanca_meteo_2024_6h.csv` | 64 KB | ~1460 |
| `casablanca_pv_2024_6h.csv` | 52 KB | ~1460 |
| `chu_patient.csv` | 38 KB | ~1460 |
| `chu_events_casablanca_6h.csv` | 2 KB | ~50-100 événements |
| Fichiers zones | 52-66 KB chacun | ~1460 chacun |

**Total** : ~12 fichiers CSV, ~700 KB de données brutes

---

*Dernière mise à jour : Décembre 2024*



