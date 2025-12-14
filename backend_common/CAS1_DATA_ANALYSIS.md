# Analyse des Données - Cas 1 : Établissement EXISTANT

## 📊 Vue d'ensemble

Ce document analyse les données **existantes** dans le système et les données **nécessaires** pour réaliser la logique complète du Cas 1 (établissement existant).

---

## 🔍 1. DONNÉES EXISTANTES (dans les CSV)

### 1.1 Fichiers CSV disponibles

| Fichier | Colonnes | Description |
|---------|----------|-------------|
| `casablanca_meteo_2024_6h.csv` | `datetime`, `temperature_C`, `irradiance_kWh_m2` | Données météorologiques (Casablanca) |
| `casablanca_pv_2024_6h.csv` | `datetime`, `pv_prod_kWh` | Production PV simulée (Casablanca) |
| `chu_critique_non_critique.csv` | `datetime`, `temperature_C`, `irradiance_kWh_m2`, `conso_critique_kWh`, `conso_non_critique_kWh` | Consommation critique/non-critique (CHU Casablanca) |
| `chu_events_casablanca_6h.csv` | `datetime`, `event` | Événements (maintenance, surconsommation, etc.) |
| `chu_patient.csv` | `datetime`, `patients` | Nombre de patients |
| `soc.csv` | `datetime`, `temperature_C`, `irradiance_kWh_m2`, `pv_prod_kWh`, `conso_critique_kWh`, `conso_non_critique_kWh`, `soc_batterie_kWh` | État de charge batterie |

### 1.2 Données utilisées par le modèle ML

**Features du modèle** (23 features) :
- `temperature_C` ✅
- `irradiance_kWh_m2` ✅
- `pv_prod_kWh` ✅
- `conso_critique_kWh` ✅
- `conso_non_critique_kWh` ✅
- `patients` ✅
- `soc_batterie_kWh` ✅
- `total_consumption_kWh` (calculé) ✅
- `event_maintenance`, `event_missing`, `event_other_event`, `event_surconso` ✅
- `hour`, `dayofweek`, `is_weekend`, `month`, `is_night` (temporelles) ✅
- `lag_6h`, `lag_12h`, `lag_24h` (historique) ✅
- `roll_mean_24h`, `roll_std_24h` (statistiques) ✅

**Target** : `target_total_consumption_kWh` (consommation future)

### 1.3 Endpoints API existants

1. **`/predict`** : Prédit la consommation future
   - Input : `datetime`, `temperature_C`, `irradiance_kWh_m2`, `pv_prod_kWh`, `patients`, `soc_batterie_kWh` (optionnel), `event` (optionnel)
   - Output : `predicted_consumption_kWh`, `confidence_interval`

2. **`/optimize`** : Optimise le dispatch énergétique
   - Input : `pred_kWh`, `pv_kWh`, `soc_kwh`, paramètres batterie (optionnels)
   - Output : `grid_import_kWh`, `battery_charge_kWh`, `battery_discharge_kWh`, `soc_next`, `note`

---

## 📝 2. DONNÉES COLLECTÉES (Formulaires Frontend)

### 2.1 Formulaire A1 - Identification
- ✅ Type d'établissement (hiérarchique)
- ✅ Nom de l'établissement
- ✅ Nombre de lits
- ✅ Localisation (GPS) → Classe d'irradiation (A, B, C, D)

### 2.2 Formulaire A2 - Informations énergétiques
- ✅ Surface installable pour panneaux solaires (m²) - valeur exacte ou intervalle
- ✅ Surface non critique disponible (m²)
- ✅ Consommation mensuelle actuelle (kWh)
- ❌ Panneaux solaires déjà installés ? (Oui/Non) - **MANQUANT dans FormA2**
- ❌ Si Oui → Puissance installée (kWc) - **MANQUANT dans FormA2**

### 2.3 Formulaire A3 - Graphiques (à vérifier)
- À analyser

### 2.4 Formulaire A5 - Sélection équipements
- ✅ Panneaux solaires sélectionnés
- ✅ Batteries sélectionnées
- ✅ Onduleurs sélectionnés
- ✅ Régulateurs sélectionnés

---

## 🎯 3. DONNÉES NÉCESSAIRES pour la logique Cas 1

### 3.1 Pour les PRÉDICTIONS de consommation

| Donnée | Source | Statut | Notes |
|--------|--------|--------|-------|
| `datetime` | Système | ✅ | Date/heure de prédiction |
| `temperature_C` | API météo ou CSV | ✅ | Selon localisation |
| `irradiance_kWh_m2` | API météo ou CSV | ✅ | Selon classe d'irradiation |
| `pv_prod_kWh` | Calculé | ⚠️ | Nécessite : surface PV, irradiance, efficacité |
| `patients` | Estimation | ⚠️ | Basé sur nombre de lits ou historique |
| `soc_batterie_kWh` | Simulation | ⚠️ | État initial ou historique |
| `event` | Optionnel | ✅ | Événements prévus |

**Gap identifié** : 
- `pv_prod_kWh` doit être calculé à partir de la surface installable et de l'irradiance
- `patients` peut être estimé à partir du nombre de lits

### 3.2 Pour l'OPTIMISATION énergétique

| Donnée | Source | Statut | Notes |
|--------|--------|--------|-------|
| `pred_kWh` | Modèle ML | ✅ | Résultat de `/predict` |
| `pv_kWh` | Calculé | ⚠️ | Production PV prévue |
| `soc_kwh` | Simulation | ⚠️ | État de charge actuel |
| Paramètres batterie | Configuration | ⚠️ | Capacité, limites, etc. |

**Gap identifié** :
- Paramètres de batterie doivent être configurés selon l'établissement

### 3.3 Pour les CALCULS de dimensionnement

| Donnée | Source | Statut | Notes |
|--------|--------|--------|-------|
| Consommation mensuelle | FormA2 | ✅ | `monthlyConsumptionKwh` |
| Surface installable | FormA2 | ✅ | `solarSurface` |
| Surface non critique | FormA2 | ✅ | `nonCriticalSurface` |
| Classe d'irradiation | FormA1 | ✅ | Déterminée automatiquement |
| Panneaux existants ? | FormA2 | ❌ | **MANQUANT** |
| Puissance PV existante | FormA2 | ❌ | **MANQUANT si panneaux existants** |

**Gap identifié** :
- Information sur panneaux existants manquante dans FormA2

### 3.4 Pour les GRAPHIQUES et RÉSULTATS

| Donnée | Source | Statut | Notes |
|--------|--------|--------|-------|
| Consommation réelle (critique/non critique) | Historique ou estimation | ⚠️ | Basé sur nombre de lits |
| Production solaire potentielle | Calculé | ⚠️ | Surface × Irradiance × Efficacité |
| SOC batterie simulé | Simulation | ⚠️ | Résultat de `/optimize` |
| Impact météo (irradiance) | API météo | ⚠️ | Données météo pour la localisation |
| Économie possible (DH/an) | Calculé | ⚠️ | Basé sur réduction facture |
| Pourcentage d'autonomie | Calculé | ⚠️ | Basé sur production/consommation |
| Puissance PV recommandée | Calculé | ⚠️ | Basé sur consommation et objectifs |
| Capacité batterie recommandée | Calculé | ⚠️ | Basé sur autonomie souhaitée |

---

## ⚠️ 4. GAPS IDENTIFIÉS

### 4.1 Données manquantes dans les formulaires

1. **FormA2** : 
   - ❌ Champ "Panneaux solaires déjà installés ?" (Oui/Non)
   - ❌ Champ "Puissance installée (kWc)" (si Oui)

### 4.2 Données à calculer/simuler

1. **Production PV** (`pv_prod_kWh`) :
   - Formule : `Surface_PV (m²) × Irradiance (kWh/m²/jour) × Efficacité_panneau × Facteur_performance`
   - Nécessite : surface installable, irradiance selon classe, efficacité panneau

2. **Nombre de patients** :
   - Estimation : `Nombre_de_lits × Taux_occupation` (ex: 0.7-0.9)
   - Ou utiliser historique si disponible

3. **Consommation critique/non-critique** :
   - Estimation basée sur nombre de lits et type d'établissement
   - Formules possibles :
     - `conso_critique = nombre_lits × facteur_critique × base_consommation`
     - `conso_non_critique = nombre_lits × facteur_non_critique × base_consommation`

4. **Données météorologiques** :
   - ✅ **RÉSOLU** : Données générées pour toutes les classes (A, B, C, D)
   - Fichiers créés :
     - `zone_a_sahara_meteo_2024_6h.csv` (Classe A - 6-7 kWh/m²/jour)
     - `zone_b_centre_meteo_2024_6h.csv` (Classe B - 5-6 kWh/m²/jour)
     - `casablanca_meteo_2024_6h.csv` (Classe C - 4-5 kWh/m²/jour) [existant]
     - `zone_d_rif_meteo_2024_6h.csv` (Classe D - 3-4 kWh/m²/jour)
   - Service backend créé : `MeteoDataService` pour mapper classe → fichier

### 4.3 Services/calculs à implémenter

1. **Service de calcul PV** :
   - Calculer production PV selon surface, irradiance, classe
   - Prendre en compte panneaux existants si présents

2. **Service d'estimation consommation** :
   - Estimer consommation critique/non-critique à partir de nombre de lits
   - Utiliser ratios par type d'établissement

3. **Service de simulation** :
   - Simuler SOC batterie sur une période
   - Calculer économies potentielles
   - Calculer autonomie énergétique

4. **Service de dimensionnement** :
   - Recommander puissance PV optimale
   - Recommander capacité batterie optimale
   - Basé sur consommation, objectifs, contraintes

---

## ✅ 5. PLAN D'ACTION

### Phase 1 : Compléter les données manquantes

1. **Ajouter champs dans FormA2** :
   - [ ] Checkbox "Panneaux solaires déjà installés ?"
   - [ ] Champ conditionnel "Puissance installée (kWc)" si Oui

2. **Créer service de calcul PV** :
   - [ ] Calculer production PV selon surface et irradiance
   - [ ] Prendre en compte panneaux existants

### Phase 2 : Implémenter les calculs

1. **Service d'estimation consommation** :
   - [ ] Créer ratios par type d'établissement
   - [ ] Estimer consommation critique/non-critique

2. **Service de dimensionnement** :
   - [ ] Calculer puissance PV recommandée
   - [ ] Calculer capacité batterie recommandée

3. **Service de simulation** :
   - [ ] Simuler consommation future (utiliser `/predict`)
   - [ ] Simuler production PV
   - [ ] Simuler SOC batterie (utiliser `/optimize`)
   - [ ] Calculer économies et autonomie

### Phase 3 : Intégrer avec l'API AI

1. **Adapter les données pour `/predict`** :
   - [ ] Mapper données formulaire → format API
   - [ ] Calculer `pv_prod_kWh` avant appel
   - [ ] Estimer `patients` si nécessaire

2. **Utiliser `/optimize` pour simulation** :
   - [ ] Appeler `/optimize` pour chaque pas de temps
   - [ ] Agréger résultats pour graphiques

### Phase 4 : Données météorologiques

1. **Étendre données météo** :
   - [ ] Créer base de données météo pour toutes les classes
   - [ ] Ou intégrer API météo (OpenWeatherMap, etc.)

---

## 📋 6. RATIOS ET FORMULES PROPOSÉES

### 6.1 Estimation consommation par type d'établissement

| Type | Consommation/lit/jour (kWh) | Ratio Critique/Non-critique |
|------|----------------------------|----------------------------|
| CHU | 15-25 | 60/40 |
| Hôpital Régional | 12-20 | 55/45 |
| Hôpital Provincial | 10-18 | 50/50 |
| Centre de Santé | 5-10 | 40/60 |
| Clinique Privée | 8-15 | 45/55 |

### 6.2 Calcul production PV

```
Production_PV (kWh/jour) = Surface_PV (m²) × Irradiance (kWh/m²/jour) × Efficacité_panneau × Facteur_performance

Où:
- Efficacité_panneau ≈ 0.20 (20%)
- Facteur_performance ≈ 0.75-0.85 (pertes système)
```

### 6.3 Calcul dimensionnement PV recommandé

```
Puissance_PV_recommandée (kWc) = (Consommation_mensuelle (kWh) / 30) / (Irradiance_moyenne (kWh/m²/jour) × Efficacité × Facteur_performance)

Surface_PV_recommandée (m²) = Puissance_PV_recommandée (kWc) / (Puissance_panneau (kW/m²))
```

### 6.4 Calcul dimensionnement batterie

```
Capacité_batterie_recommandée (kWh) = Consommation_journée (kWh) × Jours_autonomie × Facteur_sécurité

Où:
- Jours_autonomie = 1-3 jours selon objectif
- Facteur_sécurité = 1.2-1.5
```

---

## 🔗 7. INTÉGRATION BACKEND-FRONTEND

### 7.1 Endpoints à créer dans Spring Boot

1. **`POST /api/establishments/{id}/simulate`** :
   - Simule consommation, production, SOC sur une période
   - Retourne données pour graphiques

2. **`POST /api/establishments/{id}/calculate-recommendations`** :
   - Calcule puissance PV recommandée
   - Calcule capacité batterie recommandée
   - Retourne recommandations

3. **`POST /api/establishments/{id}/calculate-savings`** :
   - Calcule économies potentielles
   - Calcule autonomie énergétique
   - Retourne indicateurs économiques

### 7.2 Appels à l'API AI

Le backend Spring Boot doit appeler le microservice AI :
- `/predict` pour chaque pas de temps
- `/optimize` pour chaque pas de temps

---

## 📊 8. RÉSUMÉ

### ✅ Données disponibles
- Données météo (Casablanca)
- Modèle ML entraîné
- API de prédiction et optimisation
- Données collectées dans formulaires (partiellement)

### ❌ Données manquantes
- ~~Données météo pour toutes les classes~~ ✅ **RÉSOLU** (données générées)
- Service de calcul PV
- Service d'estimation consommation
- Service de simulation complète

### 🎯 Prochaines étapes
1. Compléter FormA2 avec champs panneaux existants
2. Créer services de calcul dans le backend
3. Intégrer avec API AI
4. Implémenter simulation et graphiques

