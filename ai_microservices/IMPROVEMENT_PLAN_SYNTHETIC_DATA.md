# 🎯 Plan d'Amélioration : Données Synthétiques pour Tous les Types

## 📊 Problème Actuel

1. **Modèle ROI** : Seulement 7 types couverts sur 17
2. **Prédictions Long Terme** : Données factices non réalistes
3. **Nouveaux établissements** : IA indisponible car pas d'historique

## ✅ Solution : Génération de Données Synthétiques Complète

### 1. Améliorer `generate_synthetic_training_data()` pour ROI

**Ajouter TOUS les types manquants :**

```python
type_multipliers = {
    # Types existants (garder)
    "CHU": {"beds": (500, 2000), "consumption": (80000, 300000), "roi_factor": 0.85},
    "HOPITAL_REGIONAL": {"beds": (200, 800), "consumption": (30000, 120000), "roi_factor": 0.90},
    "HOPITAL_PROVINCIAL": {"beds": (30, 150), "consumption": (5000, 30000), "roi_factor": 0.95},
    "CENTRE_REGIONAL_ONCOLOGIE": {"beds": (50, 200), "consumption": (15000, 80000), "roi_factor": 0.88},
    "CENTRE_HEMODIALYSE": {"beds": (10, 50), "consumption": (5000, 20000), "roi_factor": 0.92},
    "CLINIQUE_PRIVEE": {"beds": (20, 150), "consumption": (8000, 40000), "roi_factor": 0.93},
    
    # NOUVEAUX TYPES À AJOUTER
    "HOPITAL_GENERAL": {"beds": (100, 400), "consumption": (15000, 60000), "roi_factor": 0.92},
    "HOPITAL_SPECIALISE": {"beds": (50, 300), "consumption": (12000, 50000), "roi_factor": 0.90},
    "HOPITAL_PREFECTORAL": {"beds": (50, 300), "consumption": (10000, 50000), "roi_factor": 0.95},
    "CENTRE_REEDUCATION": {"beds": (20, 100), "consumption": (3000, 15000), "roi_factor": 0.88},
    "CENTRE_ADDICTOLOGIE": {"beds": (15, 80), "consumption": (2500, 12000), "roi_factor": 0.85},
    "CENTRE_SOINS_PALLIATIFS": {"beds": (10, 50), "consumption": (2000, 10000), "roi_factor": 0.87},
    "UMH": {"beds": (30, 150), "consumption": (8000, 35000), "roi_factor": 0.91},
    "UMP": {"beds": (20, 100), "consumption": (5000, 25000), "roi_factor": 0.93},
    "UPH": {"beds": (10, 50), "consumption": (3000, 15000), "roi_factor": 0.94},
    "CENTRE_SANTE_PRIMAIRE": {"beds": (5, 30), "consumption": (1000, 8000), "roi_factor": 0.95},
    "AUTRE": {"beds": (10, 200), "consumption": (3000, 50000), "roi_factor": 0.90},
}
```

### 2. Créer `generate_synthetic_historical_data_by_type()` pour Prédictions Long Terme

**Nouvelle fonction qui génère 30 jours d'historique réaliste selon le type :**

```python
def generate_synthetic_historical_data_by_type(
    establishment_type: str,
    number_of_beds: int,
    monthly_consumption: float,
    irradiation_class: str,
    num_days: int = 30
) -> List[Dict]:
    """
    Génère des données historiques synthétiques réalistes basées sur :
    - Type d'établissement (ratios de consommation)
    - Nombre de lits
    - Classe d'irradiation
    - Patterns saisonniers et hebdomadaires
    """
    # Utiliser ConsumptionEstimationService ratios
    # Ajouter variations réalistes (weekend, saisons, anomalies occasionnelles)
    # Générer production PV selon irradiation
    pass
```

### 3. Utiliser les données synthétiques dans le backend

**Modifier `LongTermPredictionService.java` :**

```java
// Au lieu de données factices aléatoires
// Utiliser ConsumptionEstimationService pour générer des données réalistes
// Basées sur le type, nombre de lits, et irradiation
```

## 🎯 Résultat Attendu

- ✅ **Modèle ROI** : Fonctionne pour TOUS les types d'établissements
- ✅ **Prédictions Long Terme** : Disponibles même pour nouveaux établissements
- ✅ **Recommandations ML** : Plus précises avec plus de données d'entraînement
- ✅ **Pas de "IA indisponible"** : Toujours des prédictions (même si basées sur synthétique)

## 📈 Variantes à Générer par Type

Pour chaque type, générer des variantes avec :
- Différents nombres de lits (min, moyen, max)
- Différentes classes d'irradiation (A, B, C, D)
- Différentes surfaces installables
- Différents budgets
- **Total : ~50-100 échantillons par type = 850-1700 échantillons au total**














