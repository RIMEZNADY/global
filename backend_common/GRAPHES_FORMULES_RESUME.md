# 📊 Résumé des Graphiques et Formules - Cas 1

## 🎯 Vue d'Ensemble

Ce document résume tous les graphiques affichés dans le Cas 1 (établissement existant), les formules mathématiques utilisées, et les sources de données pour chaque graphique.

---

## 📈 GRAPHIQUE 1 : Consommation Réelle (Critique/Non-critique)

### Données Sources
- ✅ `establishment.monthlyConsumptionKwh` (Formulaire A2)
- ✅ OU estimation via `ConsumptionEstimationService` (type + nombre de lits)

### Formule Mathématique

```
Si consommation_mensuelle fournie :
  Consommation_quotidienne = Consommation_mensuelle / 30

Sinon (estimation) :
  Consommation_quotidienne = kWh_par_lit_par_jour × Nombre_de_lits
  
  Où kWh_par_lit_par_jour selon type :
  - CHU : 20.0 kWh/lit/jour
  - Hôpital Régional : 16.0 kWh/lit/jour
  - Hôpital Provincial : 14.0 kWh/lit/jour
  - Centre de Santé : 7.5 kWh/lit/jour
  - Clinique Privée : 11.5 kWh/lit/jour

Séparation :
  Consommation_critique = Consommation_quotidienne × Ratio_critique
  Consommation_non_critique = Consommation_quotidienne × Ratio_non_critique
```

### Ratios par Type

| Type | Ratio Critique | Ratio Non-critique |
|------|---------------|-------------------|
| CHU | 60% | 40% |
| Hôpital Régional | 55% | 45% |
| Hôpital Provincial | 50% | 50% |
| Centre de Santé | 40% | 60% |
| Clinique Privée | 45% | 55% |

### Structure Graphique
- **Axe X** : Temps (dates/heures)
- **Axe Y** : Consommation (kWh)
- **Séries** : Critique (rouge), Non-critique (bleu), Total (vert)

---

## ☀️ GRAPHIQUE 2 : Production Solaire Potentielle

### Données Sources
- ✅ `establishment.installableSurfaceM2` (Formulaire A2)
- ✅ `establishment.irradiationClass` (A, B, C, D - déterminée automatiquement)
- ✅ Fichier CSV météo : `zone_X_meteo_2024_6h.csv` selon classe

### Formule Mathématique

```
Production_PV_quotidienne (kWh/jour) = Surface_PV (m²) × Irradiance_moyenne (kWh/m²/jour) × 0.20 × 0.80

Production_PV_instantanée (kWh) = Surface_PV (m²) × Irradiance_instantanée (kWh/m²) × 0.20 × 0.80
```

**Constantes** :
- `Efficacité_panneau = 0.20` (20%)
- `Facteur_performance = 0.80` (80% - pertes système)

**Irradiance moyenne par classe** :
- Classe A : 6.5 kWh/m²/jour
- Classe B : 5.5 kWh/m²/jour
- Classe C : 4.5 kWh/m²/jour
- Classe D : 3.5 kWh/m²/jour

### Structure Graphique
- **Axe X** : Temps (dates/heures)
- **Axe Y** : Production PV (kWh)
- **Série** : Production solaire (jaune/orange)
- **Source données** : Fichier CSV météo correspondant à la classe d'irradiation

---

## 🔋 GRAPHIQUE 3 : SOC Batterie Simulé

### Données Sources
- ✅ Résultat de `SimulationService.simulate()`
- ✅ Appels à l'API AI `/optimize` pour chaque pas de temps (6h)
- ✅ `batteryCapacityKwh` (paramètre simulation)
- ✅ `initialSocKwh` (paramètre simulation)

### Formule Mathématique

```
Algorithme d'optimisation (via API AI /optimize) :

1. Calculer demande = Consommation_prédite (via AI /predict)
2. Calculer PV_disponible = Production_PV
3. PV_utilisé = min(demande, PV_disponible)
4. Demande_restante = demande - PV_utilisé
5. Surplus_PV = PV_disponible - PV_utilisé

6. Si Surplus_PV > 0 :
     Capacité_disponible = SOC_max × Capacité_batterie - SOC_actuel
     Charge_batterie = min(Surplus_PV, Capacité_disponible, Charge_max_6h)
     SOC_suivant = SOC_actuel + Charge_batterie
   
7. Sinon :
     Énergie_disponible = SOC_actuel - SOC_min × Capacité_batterie
     Décharge_batterie = min(Demande_restante, Énergie_disponible, Décharge_max_6h)
     SOC_suivant = SOC_actuel - Décharge_batterie
     Demande_restante = Demande_restante - Décharge_batterie

8. Import_réseau = max(Demande_restante, 0)

Contraintes :
- SOC_min = 15% de capacité
- SOC_max = 95% de capacité
- Charge_max_6h = 200 kW × 6h = 1200 kWh
- Décharge_max_6h = 200 kW × 6h = 1200 kWh
```

### Structure Graphique
- **Axe X** : Temps (dates/heures, pas de 6h)
- **Axe Y** : SOC (kWh) ou Pourcentage (%)
- **Série** : État de charge batterie (bleu)
- **Lignes de référence** : SOC_min (15%) et SOC_max (95%)

---

## 🌤️ GRAPHIQUE 4 : Impact Météo (Irradiance)

### Données Sources
- ✅ Fichier CSV météo selon classe d'irradiation :
  - Classe A : `zone_a_sahara_meteo_2024_6h.csv`
  - Classe B : `zone_b_centre_meteo_2024_6h.csv`
  - Classe C : `casablanca_meteo_2024_6h.csv`
  - Classe D : `zone_d_rif_meteo_2024_6h.csv`
- ✅ Colonne : `irradiance_kWh_m2`

### Formule Mathématique

```
Irradiance (kWh/m²) = Donnée_CSV[datetime].irradiance_kWh_m2
```

**Pas de calcul** : Données directes du fichier CSV

### Structure Graphique
- **Axe X** : Temps (dates/heures)
- **Axe Y** : Irradiance (kWh/m²)
- **Série** : Irradiance solaire (orange)
- **Source** : Données réelles du fichier CSV

---

## 📊 GRAPHIQUE 5 : Évolution Temporelle Multi-séries

### Données Sources
- ✅ Résultat de `SimulationService.simulate()`
- ✅ Chaque pas de 6h contient :
  - `predictedConsumption` (via AI `/predict`)
  - `pvProduction` (calculé)
  - `gridImport` (via AI `/optimize`)
  - `socBattery` (via AI `/optimize`)

### Formules Mathématiques

**1. Consommation Prédite** :
```
Consommation_prédite = AI_API.predict(
  datetime,
  temperature,
  irradiance,
  pv_production,
  patients,
  soc_batterie
)
```
- **Source** : Modèle ML XGBoost (23 features)
- **Input** : Données météo + établissement

**2. Production PV** :
```
Production_PV = Surface_PV × Irradiance_instantanée × 0.20 × 0.80
```

**3. Import Réseau** :
```
Import_réseau = AI_API.optimize().grid_import_kWh
```
- **Source** : Algorithme d'optimisation énergétique

**4. SOC Batterie** :
```
SOC = AI_API.optimize().soc_next
```
- **Source** : Résultat de l'optimisation

### Structure Graphique
- **Axe X** : `SimulationStep.datetime` (dates/heures, pas de 6h)
- **Axe Y principal** : kWh (consommation, production, import)
- **Axe Y secondaire** : kWh ou % (SOC batterie)
- **Séries** :
  1. Consommation prédite (rouge)
  2. Production PV (jaune)
  3. Import Réseau (bleu)
  4. SOC Batterie (vert, axe secondaire)

---

## 💰 INDICATEURS CLÉS - FORMULES

### 1. Économie Possible (DH/an)

**Formule** :
```
Économie_annuelle = Énergie_PV_annuelle × Prix_électricité

Où :
Énergie_PV_annuelle = Consommation_annuelle × (Autonomie_% / 100)
Consommation_annuelle = Consommation_mensuelle × 12
Autonomie_% = (Production_PV_mensuelle / Consommation_mensuelle) × 100
Prix_électricité = 1.2 DH/kWh (par défaut)
```

**Données sources** :
- `establishment.monthlyConsumptionKwh`
- `establishment.installableSurfaceM2`
- `establishment.irradiationClass`

---

### 2. Pourcentage d'Autonomie Possible

**Formule** :
```
Autonomie_% = (Production_PV_mensuelle / Consommation_mensuelle) × 100

Où :
Production_PV_mensuelle = Production_PV_quotidienne × 30
Production_PV_quotidienne = Surface_PV × Irradiance_moyenne × 0.20 × 0.80
```

**Limite** : `Autonomie_% ≤ 100%`

---

### 3. Puissance PV Recommandée (kWc)

**Formule** :
```
Puissance_PV_recommandée (kWc) = (Consommation_quotidienne / (Irradiance_moyenne × 0.20 × 0.80)) × 1.3

Où :
Consommation_quotidienne = Consommation_mensuelle / 30
Facteur_sécurité = 1.3 (30% de marge)
```

---

### 4. Capacité Batterie Recommandée (kWh)

**Formule** :
```
Capacité_batterie (kWh) = Consommation_quotidienne × 2 × 1.3

Où :
Consommation_quotidienne = Consommation_mensuelle / 30
Jours_autonomie = 2 jours
Facteur_sécurité = 1.3 (30% de marge)
```

---

## 🔄 SIMULATION - ALGORITHME COMPLET

### Algorithme de Simulation

```
Pour chaque pas de temps (6 heures) :
  
  1. Lire données météo :
     temperature = CSV[datetime].temperature_C
     irradiance = CSV[datetime].irradiance_kWh_m2
     
  2. Calculer Production_PV :
     Production_PV = Surface_PV × irradiance × 0.20 × 0.80
     
  3. Estimer Patients :
     Patients = Nombre_de_lits × 0.80 (taux occupation)
     
  4. Prédire Consommation :
     Consommation_prédite = AI_API.predict(
       datetime,
       temperature,
       irradiance,
       Production_PV,
       patients,
       SOC_actuel
     )
     
  5. Optimiser Dispatch :
     Résultat = AI_API.optimize(
       Consommation_prédite,
       Production_PV,
       SOC_actuel,
       paramètres_batterie
     )
     
  6. Mettre à jour SOC :
     SOC_suivant = Résultat.soc_next
     
  7. Enregistrer résultats :
     - Consommation_prédite
     - Production_PV
     - Import_réseau = Résultat.grid_import_kWh
     - SOC = SOC_suivant
     - Charge_batterie = Résultat.battery_charge_kWh
     - Décharge_batterie = Résultat.battery_discharge_kWh
```

### Statistiques Finales

```
Total_consommation = Σ(Consommation_prédite_i) pour tous les pas
Total_production_PV = Σ(Production_PV_i) pour tous les pas
Total_import_réseau = Σ(Import_réseau_i) pour tous les pas
Autonomie_moyenne = (Total_production_PV / Total_consommation) × 100
Économies_totales = Total_production_PV × Prix_électricité
```

---

## 📋 RÉSUMÉ PAR GRAPHIQUE

| Graphique | Formule Principale | Source Données |
|-----------|-------------------|----------------|
| **Consommation Réelle** | `Consommation = monthlyConsumptionKwh / 30` ou estimation | Formulaire A2 ou estimation |
| **Production Solaire** | `Production = Surface × Irradiance × 0.20 × 0.80` | Formulaire A2 + CSV météo |
| **SOC Batterie** | Résultat de `AI_API.optimize()` | Simulation complète |
| **Impact Météo** | `Irradiance = CSV[datetime]` | Fichier CSV météo |
| **Évolution Temporelle** | Multi-séries (consommation, production, import, SOC) | Résultat simulation |

---

## ✅ VALIDATION

Toutes les formules sont basées sur :
- ✅ Standards de l'industrie solaire
- ✅ Données réelles du CHU Casablanca
- ✅ Ratios établis par type d'établissement au Maroc
- ✅ Algorithmes d'optimisation énergétique standards

