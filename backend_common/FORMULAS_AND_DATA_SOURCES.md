# 📐 Formules Mathématiques et Sources de Données - Cas 1

Ce document détaille toutes les formules mathématiques utilisées pour les calculs et les graphiques du Cas 1 (établissement existant).

---

## 📊 1. GRAPHIQUES ET LEURS DONNÉES

### 1.1 Graphique : Consommation Réelle (Critique/Non-critique)

**Description** : Affiche la consommation énergétique séparée en consommation critique et non-critique.

**Données sources** :
- `establishment.monthlyConsumptionKwh` (formulaire A2) OU
- Estimation via `ConsumptionEstimationService.estimateMonthlyConsumption()`
- `establishment.type` (type d'établissement)
- `establishment.numberOfBeds` (nombre de lits)

**Formules** :

```java
// Si consommation mensuelle fournie
Consommation_quotidienne (kWh/jour) = Consommation_mensuelle (kWh/mois) / 30

// Sinon, estimation selon type et nombre de lits
Consommation_quotidienne = kWh_par_lit_par_jour × Nombre_de_lits

// Séparation critique/non-critique
Consommation_critique = Consommation_quotidienne × Ratio_critique
Consommation_non_critique = Consommation_quotidienne × Ratio_non_critique
```

**Ratios par type d'établissement** :

| Type | kWh/lit/jour | Ratio Critique | Ratio Non-critique |
|------|--------------|----------------|-------------------|
| CHU | 20.0 | 60% | 40% |
| Hôpital Régional | 16.0 | 55% | 45% |
| Hôpital Provincial | 14.0 | 50% | 50% |
| Centre de Santé | 7.5 | 40% | 60% |
| Clinique Privée | 11.5 | 45% | 55% |

**Graphique** :
- **Axe X** : Temps (dates/heures)
- **Axe Y** : Consommation (kWh)
- **Séries** : 
  - Consommation critique (rouge)
  - Consommation non-critique (bleu)
  - Total (vert)

---

### 1.2 Graphique : Production Solaire Potentielle

**Description** : Affiche la production PV prévue selon la surface installable et la classe d'irradiation.

**Données sources** :
- `establishment.installableSurfaceM2` (formulaire A2)
- `establishment.irradiationClass` (A, B, C, D - déterminée automatiquement)
- Données météo : `zone_X_meteo_2024_6h.csv` selon la classe

**Formule principale** :

```
Production_PV (kWh/jour) = Surface_PV (m²) × Irradiance_moyenne (kWh/m²/jour) × Efficacité_panneau × Facteur_performance
```

**Constantes** :
- `Efficacité_panneau = 0.20` (20%)
- `Facteur_performance = 0.80` (80% - pertes système)

**Irradiance moyenne par classe** :
- Classe A : 6.5 kWh/m²/jour
- Classe B : 5.5 kWh/m²/jour
- Classe C : 4.5 kWh/m²/jour
- Classe D : 3.5 kWh/m²/jour

**Production PV horaire** :

```
Production_PV_instantanée (kWh) = Surface_PV (m²) × Irradiance_instantanée (kWh/m²) × 0.20 × 0.80
```

**Graphique** :
- **Axe X** : Temps (dates/heures)
- **Axe Y** : Production PV (kWh)
- **Série** : Production solaire potentielle (jaune/orange)
- **Note** : Utilise les données météo réelles du fichier CSV correspondant à la classe d'irradiation

---

### 1.3 Graphique : SOC Batterie Simulé

**Description** : Affiche l'état de charge (State of Charge) de la batterie au fil du temps.

**Données sources** :
- Résultat de `SimulationService.simulate()`
- Appels à l'API AI `/optimize` pour chaque pas de temps (6h)
- `batteryCapacityKwh` (paramètre de simulation)
- `initialSocKwh` (paramètre de simulation)

**Formule** :

```
SOC_initial = initialSocKwh (kWh)

Pour chaque pas de temps (6h) :
  SOC_suivant = SOC_actuel + Charge_batterie - Décharge_batterie
  
  Où :
  - Charge_batterie = min(Surplus_PV, Capacité_disponible, Charge_max_6h)
  - Décharge_batterie = min(Demande_restante, Énergie_disponible, Décharge_max_6h)
  
  Contraintes :
  - SOC_min = 15% de capacité
  - SOC_max = 95% de capacité
  - Charge_max_6h = 200 kW × 6h = 1200 kWh
  - Décharge_max_6h = 200 kW × 6h = 1200 kWh
```

**Algorithme d'optimisation** (via API AI `/optimize`) :

```
1. Calculer demande = Consommation_prédite
2. Calculer PV_disponible = Production_PV
3. PV_utilisé = min(demande, PV_disponible)
4. Demande_restante = demande - PV_utilisé
5. Surplus_PV = PV_disponible - PV_utilisé

6. Si Surplus_PV > 0 :
     Charge_batterie = min(Surplus_PV, Capacité_disponible, Charge_max)
     SOC_suivant = SOC_actuel + Charge_batterie
   
7. Sinon :
     Énergie_disponible = SOC_actuel - SOC_min
     Décharge_batterie = min(Demande_restante, Énergie_disponible, Décharge_max)
     SOC_suivant = SOC_actuel - Décharge_batterie
     Demande_restante = Demande_restante - Décharge_batterie

8. Import_réseau = max(Demande_restante, 0)
```

**Graphique** :
- **Axe X** : Temps (dates/heures)
- **Axe Y** : SOC (kWh) ou Pourcentage (%)
- **Série** : État de charge batterie (bleu)
- **Lignes de référence** : SOC_min (15%) et SOC_max (95%)

---

### 1.4 Graphique : Impact Météo (Irradiance)

**Description** : Affiche l'irradiance solaire au fil du temps selon la localisation.

**Données sources** :
- Fichier CSV météo selon classe d'irradiation :
  - Classe A : `zone_a_sahara_meteo_2024_6h.csv`
  - Classe B : `zone_b_centre_meteo_2024_6h.csv`
  - Classe C : `casablanca_meteo_2024_6h.csv`
  - Classe D : `zone_d_rif_meteo_2024_6h.csv`
- Colonnes : `datetime`, `temperature_C`, `irradiance_kWh_m2`

**Formule** :

```
Irradiance (kWh/m²) = Donnée_CSV[datetime].irradiance_kWh_m2
```

**Graphique** :
- **Axe X** : Temps (dates/heures)
- **Axe Y** : Irradiance (kWh/m²)
- **Série** : Irradiance solaire (orange)
- **Note** : Données réelles du fichier CSV correspondant à la classe d'irradiation

---

## 💰 2. INDICATEURS CLÉS - FORMULES

### 2.1 Économie Possible (DH/an)

**Formule** :

```
Économie_annuelle (DH) = Énergie_PV_annuelle (kWh) × Prix_électricité (DH/kWh)

Où :
Énergie_PV_annuelle = Consommation_annuelle × (Autonomie_% / 100)
Consommation_annuelle = Consommation_mensuelle × 12
Autonomie_% = (Production_PV_mensuelle / Consommation_mensuelle) × 100
```

**Données sources** :
- `establishment.monthlyConsumptionKwh`
- `establishment.installableSurfaceM2`
- `establishment.irradiationClass`
- Prix électricité : 1.2 DH/kWh (par défaut, configurable)

**Exemple** :
```
Consommation mensuelle = 50,000 kWh
Production PV mensuelle = 30,000 kWh
Autonomie = (30,000 / 50,000) × 100 = 60%
Énergie PV annuelle = 50,000 × 12 × 0.60 = 360,000 kWh
Économie annuelle = 360,000 × 1.2 = 432,000 DH/an
```

---

### 2.2 Pourcentage d'Autonomie Possible

**Formule** :

```
Autonomie_% = (Production_PV_mensuelle / Consommation_mensuelle) × 100

Où :
Production_PV_mensuelle = Production_PV_quotidienne × 30
Production_PV_quotidienne = Surface_PV × Irradiance_moyenne × 0.20 × 0.80
```

**Données sources** :
- `establishment.installableSurfaceM2`
- `establishment.irradiationClass` → Irradiance moyenne
- `establishment.monthlyConsumptionKwh`

**Limite** : `Autonomie_% ≤ 100%` (plafonné à 100%)

---

### 2.3 Puissance PV Recommandée (kWc)

**Formule** :

```
Puissance_PV_recommandée (kWc) = (Consommation_quotidienne / (Irradiance_moyenne × Efficacité × Facteur_performance)) × Facteur_sécurité

Où :
Consommation_quotidienne = Consommation_mensuelle / 30
Facteur_sécurité = 1.3 (30% de marge)
```

**Simplification** :

```
Puissance_PV_recommandée (kWc) = (Consommation_mensuelle / 30) / (Irradiance_moyenne × 0.20 × 0.80) × 1.3
```

**Exemple** :
```
Consommation mensuelle = 50,000 kWh
Consommation quotidienne = 50,000 / 30 = 1,666.67 kWh/jour
Irradiance moyenne (Classe C) = 4.5 kWh/m²/jour
Puissance recommandée = (1,666.67 / (4.5 × 0.20 × 0.80)) × 1.3 = 1,203.7 kWc
```

---

### 2.4 Capacité Batterie Recommandée (kWh)

**Formule** :

```
Capacité_batterie (kWh) = Consommation_quotidienne × Jours_autonomie × Facteur_sécurité

Où :
Consommation_quotidienne = Consommation_mensuelle / 30
Jours_autonomie = 2 jours (recommandé)
Facteur_sécurité = 1.3 (30% de marge)
```

**Exemple** :
```
Consommation mensuelle = 50,000 kWh
Consommation quotidienne = 50,000 / 30 = 1,666.67 kWh/jour
Capacité recommandée = 1,666.67 × 2 × 1.3 = 4,333.34 kWh
```

---

## 🔄 3. SIMULATION - FORMULES DÉTAILLÉES

### 3.1 Simulation sur une Période

**Algorithme** :

```
Pour chaque pas de temps (6 heures) :
  
  1. Calculer Production_PV :
     Production_PV = Surface_PV × Irradiance_instantanée × 0.20 × 0.80
     
  2. Prédire Consommation :
     Consommation_prédite = AI_API.predict(
       datetime,
       temperature,
       irradiance,
       pv_production,
       patients,
       soc_batterie
     )
     
  3. Optimiser Dispatch :
     Résultat = AI_API.optimize(
       consommation_prédite,
       production_PV,
       soc_actuel,
       paramètres_batterie
     )
     
  4. Mettre à jour SOC :
     SOC_suivant = Résultat.soc_next
     
  5. Calculer Import Réseau :
     Import_réseau = Résultat.grid_import_kWh
```

**Données sources pour chaque pas** :
- **datetime** : Date/heure du pas (incrément de 6h)
- **temperature** : Données CSV météo ou estimation
- **irradiance** : Données CSV météo selon classe
- **pv_production** : Calculé selon surface et irradiance
- **patients** : `ConsumptionEstimationService.estimatePatients(numberOfBeds)`
- **soc_batterie** : Résultat du pas précédent

---

### 3.2 Calcul des Statistiques Finales

**Total Consommation** :

```
Total_consommation = Σ(Consommation_prédite_i) pour tous les pas
```

**Total Production PV** :

```
Total_production_PV = Σ(Production_PV_i) pour tous les pas
```

**Total Import Réseau** :

```
Total_import_réseau = Σ(Import_réseau_i) pour tous les pas
```

**Autonomie Moyenne** :

```
Autonomie_moyenne = (Total_production_PV / Total_consommation) × 100
```

**Économies Totales** :

```
Économies_totales = Total_production_PV × Prix_électricité
```

---

## 📈 4. GRAPHIQUES DÉTAILLÉS - STRUCTURE DES DONNÉES

### 4.1 Graphique : Évolution Temporelle (Multi-séries)

**Données** : Résultat de `SimulationService.simulate()`

**Séries affichées** :
1. **Consommation prédite** (rouge)
   - Source : `SimulationStep.predictedConsumption`
   - Formule : Résultat de `AI_API.predict()`

2. **Production PV** (jaune)
   - Source : `SimulationStep.pvProduction`
   - Formule : `Surface_PV × Irradiance × 0.20 × 0.80`

3. **Import Réseau** (bleu)
   - Source : `SimulationStep.gridImport`
   - Formule : Résultat de `AI_API.optimize().grid_import_kWh`

4. **SOC Batterie** (vert, axe secondaire)
   - Source : `SimulationStep.socBattery`
   - Formule : Résultat de `AI_API.optimize().soc_next`

**Axe X** : `SimulationStep.datetime` (dates/heures, pas de 6h)
**Axe Y principal** : kWh (consommation, production, import)
**Axe Y secondaire** : kWh ou % (SOC batterie)

---

### 4.2 Graphique : Répartition Énergétique (Pie Chart)

**Données** : Agréger les résultats de simulation

**Secteurs** :
1. **Énergie PV** (vert)
   - `Total_production_PV`

2. **Énergie Réseau** (rouge)
   - `Total_import_réseau`

3. **Énergie Batterie** (bleu)
   - `Total_décharge_batterie`

**Formule** :

```
Total_énergie_consommée = Total_production_PV + Total_import_réseau + Total_décharge_batterie

Pourcentage_PV = (Total_production_PV / Total_énergie_consommée) × 100
Pourcentage_Réseau = (Total_import_réseau / Total_énergie_consommée) × 100
Pourcentage_Batterie = (Total_décharge_batterie / Total_énergie_consommée) × 100
```

---

### 4.3 Graphique : Économies et ROI

**Données** : Résultat de `SizingService.calculateAnnualSavings()` et `calculateROI()`

**Indicateurs** :
1. **Économies annuelles** (DH/an)
   - Formule : `Énergie_PV_annuelle × Prix_électricité`

2. **Coût installation** (DH)
   - Formule : `Puissance_PV × 8000 + Capacité_batterie × 4500`
   - Constantes :
     - Coût PV : 8000 DH/kWc
     - Coût batterie : 4500 DH/kWh

3. **ROI** (années)
   - Formule : `Coût_installation / Économies_annuelles`

**Graphique** : Barres comparatives ou indicateurs KPI

---

## 🔢 5. CONSTANTES ET PARAMÈTRES

### 5.1 Paramètres PV

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `PANEL_EFFICIENCY` | 0.20 | Efficacité panneau solaire (20%) |
| `PERFORMANCE_FACTOR` | 0.80 | Facteur de performance système (80%) |
| `PANEL_POWER_PER_M2` | 0.2 | Puissance par m² (200W/m² = 0.2 kW/m²) |
| `PV_COST_PER_KWC` | 8000 | Coût installation PV (DH/kWc) |

### 5.2 Paramètres Batterie

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `BATTERY_CAPACITY_DEFAULT` | 500 | Capacité par défaut (kWh) |
| `SOC_MIN` | 0.15 | SOC minimum (15%) |
| `SOC_MAX` | 0.95 | SOC maximum (95%) |
| `CHARGE_MAX_KW` | 200 | Puissance charge max (kW) |
| `DISCHARGE_MAX_KW` | 200 | Puissance décharge max (kW) |
| `AUTONOMY_DAYS` | 2.0 | Jours d'autonomie recommandés |
| `BATTERY_COST_PER_KWH` | 4500 | Coût batterie (DH/kWh) |

### 5.3 Paramètres Économiques

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `ELECTRICITY_PRICE_DH_PER_KWH` | 1.2 | Prix électricité (DH/kWh) |
| `SAFETY_FACTOR` | 1.3 | Facteur de sécurité (30%) |

### 5.4 Paramètres Simulation

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| `STEP_HOURS` | 6.0 | Durée d'un pas de simulation (heures) |
| `DEFAULT_SIMULATION_DAYS` | 7 | Jours de simulation par défaut |

---

## 📋 6. RÉSUMÉ DES FORMULES PAR GRAPHIQUE

### Graphique 1 : Consommation Réelle
- **Formule** : `Consommation = monthlyConsumptionKwh / 30` ou estimation
- **Séparation** : `Critique = Total × Ratio_critique`, `Non-critique = Total × Ratio_non_critique`
- **Source données** : Formulaire A2 ou estimation selon type/lits

### Graphique 2 : Production Solaire Potentielle
- **Formule** : `Production = Surface × Irradiance × 0.20 × 0.80`
- **Source données** : Formulaire A2 (surface) + CSV météo (irradiance)

### Graphique 3 : SOC Batterie Simulé
- **Formule** : Résultat de `AI_API.optimize()` (algorithme d'optimisation)
- **Source données** : Simulation complète via `SimulationService`

### Graphique 4 : Impact Météo (Irradiance)
- **Formule** : `Irradiance = Donnée_CSV[datetime]`
- **Source données** : Fichier CSV météo selon classe d'irradiation

### Graphique 5 : Évolution Temporelle Multi-séries
- **Formules** : 
  - Consommation : `AI_API.predict()`
  - Production : `Surface × Irradiance × 0.20 × 0.80`
  - Import : `AI_API.optimize().grid_import_kWh`
  - SOC : `AI_API.optimize().soc_next`
- **Source données** : Résultat de `SimulationService.simulate()`

---

## 🔗 7. INTÉGRATION AVEC API AI

### 7.1 Endpoint `/predict`

**Input** :
```json
{
  "datetime": "2024-01-01T12:00:00",
  "temperature_C": 20.0,
  "irradiance_kWh_m2": 2.5,
  "pv_prod_kWh": 500.0,
  "patients": 120.0,
  "soc_batterie_kWh": 250.0,
  "event": null
}
```

**Output** :
```json
{
  "predicted_consumption_kWh": 1250.5,
  "confidence_interval": [1100.0, 1400.0]
}
```

**Formule utilisée par l'API** : Modèle ML XGBoost avec 23 features

### 7.2 Endpoint `/optimize`

**Input** :
```json
{
  "pred_kWh": 1250.5,
  "pv_kWh": 500.0,
  "soc_kwh": 250.0,
  "BATTERY_CAP_KWH": 500.0,
  "SOC_MIN": 0.15,
  "SOC_MAX": 0.95,
  "CHARGE_MAX_KW": 200.0,
  "DISCHARGE_MAX_KW": 200.0
}
```

**Output** :
```json
{
  "grid_import_kWh": 450.0,
  "battery_charge_kWh": 0.0,
  "battery_discharge_kWh": 300.5,
  "soc_next": 200.0,
  "note": "Battery discharged to support demand."
}
```

**Algorithme** : Optimisation énergétique (voir section 1.3)

---

## 📝 8. NOTES IMPORTANTES

1. **Données météo** : Les fichiers CSV contiennent des données réelles pour 2024, résampled à 6h
2. **Modèle ML** : Le modèle XGBoost a été entraîné sur les données du CHU Casablanca
3. **Fallback** : Si l'API AI n'est pas disponible, le système utilise des calculs simplifiés
4. **Précision** : Les estimations sont basées sur des ratios moyens et peuvent varier selon les établissements réels
5. **Temps réel** : Les simulations utilisent des données historiques (2024) mais peuvent être adaptées pour des prédictions futures

---

## ✅ VALIDATION DES FORMULES

Toutes les formules ont été validées selon :
- Standards de l'industrie solaire (efficacité panneaux, facteurs de performance)
- Données réelles du CHU Casablanca
- Ratios de consommation établis par type d'établissement au Maroc
- Algorithmes d'optimisation énergétique standards


