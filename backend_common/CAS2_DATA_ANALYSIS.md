# 📊 Analyse des Données - Cas 2 (Nouvel Établissement)

## 🎯 Vue d'ensemble

Le **Cas 2** concerne la création d'un **nouvel établissement** avec une infrastructure à construire. Contrairement au Cas 1 (établissement existant), on ne dispose pas de données historiques de consommation.

---

## 📋 Données Collectées dans les Formulaires

### **B1 - Localisation**
- ✅ **Position GPS** : `latitude`, `longitude`
- ✅ **Zone solaire** : `solarZone` (A, B, C, D) → `irradiationClass`
- ✅ **Détermination automatique** via backend `/api/location/irradiation`

### **B2 - Budget & Surface**
- ✅ **Budget global** : `globalBudget` (DH)
- ✅ **Surface totale disponible** : `totalSurface` (m²)
- ✅ **Surface solaire installable** : `solarSurface` (m²)
- ✅ **Population servie** : `population` (nombre de personnes)
- ⚠️ **Estimations automatiques** basées sur la zone solaire (frontend)

### **B3 - Type & Priorité**
- ✅ **Type d'hôpital** : `hospitalType` (ex: "Hôpital Régional", "CHU")
- ✅ **Priorité du projet** : `priority` (ex: "Haute", "Moyenne", "Basse")
  - Mappé vers backend : `MINIMIZE_COST`, `MAXIMIZE_AUTONOMY`, `BALANCED`

### **B4 - Évaluation**
- ⚠️ **Score de recommandation** : Calculé côté frontend uniquement
- ⚠️ **Logique simple** : Basée sur zone solaire, surface, budget

### **B5 - Résultats & Finalisation**
- ⚠️ **Calculs côté frontend** :
  - Consommation annuelle estimée
  - Puissance PV requise
  - Autonomie énergétique
  - Besoin batterie
  - ROI
  - Économies annuelles
  - Réduction CO₂

---

## 🔍 Données Existantes vs Nécessaires

### ✅ **Données Disponibles (après B5)**

| Donnée | Source | Disponible Backend |
|--------|--------|-------------------|
| Position GPS | B1 | ✅ `latitude`, `longitude` |
| Zone solaire | B1 | ✅ `irradiationClass` |
| Budget global | B2 | ✅ `projectBudgetDh` |
| Surface totale | B2 | ✅ `totalAvailableSurfaceM2` |
| Surface solaire | B2 | ✅ `installableSurfaceM2` |
| Population | B2 | ✅ `populationServed` |
| Type établissement | B3 | ✅ `type` (CHU, HOPITAL_REGIONAL, etc.) |
| Priorité projet | B3 | ✅ `projectPriority` |
| Nombre de lits | B5 (estimé) | ✅ `numberOfBeds` (estimé = population/100) |

### ❌ **Données Manquantes (calculées côté frontend uniquement)**

| Donnée | Calcul Frontend | Devrait être Backend |
|--------|----------------|---------------------|
| **Consommation mensuelle** | Estimation simple (population × 50 kWh/an × multiplicateur) | ❌ Devrait utiliser `ConsumptionEstimationService` |
| **Puissance PV recommandée** | `solarSurface × 0.2` (simple) | ❌ Devrait utiliser `SizingService.calculateRecommendedPvPower()` |
| **Capacité batterie recommandée** | `dailyConsumption × 2` (simple) | ❌ Devrait utiliser `SizingService.calculateRecommendedBatteryCapacity()` |
| **Autonomie énergétique** | Multiplicateur fixe par zone (0.55-0.85) | ❌ Devrait utiliser `SizingService.calculateEnergyAutonomy()` |
| **ROI** | `installationCost / annualSavings` (simple) | ❌ Devrait utiliser `SizingService.calculateROI()` |
| **Économies annuelles** | `annualConsumption × autonomy × gridPrice` (simple) | ❌ Devrait utiliser `SizingService.calculateAnnualSavings()` |
| **Réduction CO₂** | `annualConsumption × autonomy × 0.5` (simple) | ❌ Devrait utiliser calcul backend |

---

## 🧮 Logique Actuelle vs Logique Nécessaire

### **Logique Actuelle (Frontend - FormB5)**

```dart
// Estimation consommation (trop simple)
const baseConsumptionPerPerson = 50; // kWh per person per year
final hospitalMultiplier = widget.hospitalType.contains('Régional') ? 3.0 : 2.0;
final annualConsumption = widget.population * baseConsumptionPerPerson * hospitalMultiplier;

// Calcul PV (trop simple)
final requiredPVPower = widget.solarSurface * 0.2; // 200W/m² fixe

// Autonomie (trop simple)
final autonomyMultiplier = {
  SolarZone.zone1: 0.85,
  SolarZone.zone2: 0.75,
  SolarZone.zone3: 0.65,
  SolarZone.zone4: 0.55,
};
```

### **Logique Nécessaire (Backend)**

Le backend dispose déjà de services sophistiqués qui devraient être utilisés :

1. **`ConsumptionEstimationService`** :
   - Estime la consommation basée sur le type d'établissement et le nombre de lits
   - Utilise des formules plus précises que le frontend

2. **`SizingService`** :
   - `calculateRecommendedPvPower()` : Prend en compte consommation, zone solaire, priorité
   - `calculateRecommendedBatteryCapacity()` : Calcul optimisé
   - `calculateEnergyAutonomy()` : Calcul précis basé sur surface, consommation, zone
   - `calculateAnnualSavings()` : Économies réelles
   - `calculateROI()` : ROI précis

3. **`PvCalculationService`** :
   - Calcul de production PV basé sur données météo réelles
   - Utilise les CSV météo selon la zone solaire

4. **`SimulationService`** :
   - Simulation complète du microgrid
   - Prédictions avec ML
   - Détection d'anomalies

---

## 🎯 Ce qui doit être fait

### **1. Endpoints Backend à Créer/Utiliser**

#### **GET /api/establishments/{id}/sizing** (existe déjà)
- ✅ Utilise `SizingService` pour calculer :
  - Puissance PV recommandée
  - Capacité batterie recommandée
  - Autonomie énergétique
  - Économies annuelles
  - ROI

#### **GET /api/establishments/{id}/recommendations** (existe déjà)
- ✅ Retourne les recommandations de dimensionnement

#### **GET /api/establishments/{id}/savings** (existe déjà)
- ✅ Calcule les économies et indicateurs économiques

#### **POST /api/establishments/{id}/simulate** (existe déjà)
- ✅ Simulation complète avec prédictions ML et anomalies

### **2. Modifications Frontend**

#### **FormB5 - Remplacer calculs frontend par appels backend**

**Avant** (calculs frontend) :
```dart
void _calculateResults() {
  // Calculs simples côté frontend
  final annualConsumption = widget.population * 50 * 2.0;
  final requiredPVPower = widget.solarSurface * 0.2;
  // ...
}
```

**Après** (appels backend) :
```dart
Future<void> _loadBackendCalculations() async {
  // 1. Créer l'établissement
  final establishment = await EstablishmentService.createEstablishment(request);
  
  // 2. Récupérer les recommandations de dimensionnement
  final recommendations = await EstablishmentService.getRecommendations(establishment.id);
  
  // 3. Récupérer les économies
  final savings = await EstablishmentService.getSavings(establishment.id);
  
  // 4. Optionnel : Lancer une simulation
  final simulation = await AiService.simulate(establishment.id, ...);
}
```

### **3. Données CSV Nécessaires**

✅ **Déjà disponibles** :
- `zone_a_sahara_meteo_2024_6h.csv`
- `zone_a_sahara_pv_2024_6h.csv`
- `zone_b_centre_meteo_2024_6h.csv`
- `zone_b_centre_pv_2024_6h.csv`
- `zone_d_rif_meteo_2024_6h.csv`
- `zone_d_rif_pv_2024_6h.csv`
- `casablanca_meteo_2024_6h.csv` (Zone C)
- `casablanca_pv_2024_6h.csv` (Zone C)

✅ **Utilisées par** :
- `MeteoDataService` : Mappe zone → fichier CSV
- `CsvMeteoReaderService` : Lit les données réelles
- `SimulationService` : Utilise les données pour simulation

---

## 📊 Comparaison Cas 1 vs Cas 2

| Aspect | Cas 1 (Existant) | Cas 2 (Nouveau) |
|--------|------------------|-----------------|
| **Consommation** | ✅ Donnée réelle (`monthlyConsumptionKwh`) | ❌ Doit être estimée |
| **Surface PV** | ✅ Donnée réelle (`installableSurfaceM2`) | ✅ Donnée projet (`installableSurfaceM2`) |
| **Nombre de lits** | ✅ Donnée réelle (`numberOfBeds`) | ⚠️ Estimé (`population / 100`) |
| **Calculs** | ✅ Backend (services existants) | ❌ Frontend (calculs simples) |
| **Simulation** | ✅ Possible avec données réelles | ✅ Possible avec estimations |
| **Prédictions ML** | ✅ Basées sur historique | ⚠️ Basées sur estimations |
| **Recommandations** | ✅ Backend sophistiqué | ❌ Frontend simple |

---

## 🔧 Actions Recommandées

### **Phase 1 : Utiliser les Services Backend Existants**

1. **Modifier FormB5** pour :
   - Créer l'établissement d'abord
   - Appeler `/api/establishments/{id}/recommendations` pour dimensionnement
   - Appeler `/api/establishments/{id}/savings` pour économies
   - Afficher les résultats backend au lieu des calculs frontend

2. **Améliorer l'estimation de consommation** :
   - Utiliser `ConsumptionEstimationService.estimateMonthlyConsumption()` côté backend
   - Basé sur type d'établissement et nombre de lits (estimé)

### **Phase 2 : Ajouter Simulation (Optionnel)**

3. **Lancer une simulation après création** :
   - Appeler `/api/establishments/{id}/simulate`
   - Afficher les résultats dans FormB5 ou page dédiée

### **Phase 3 : Améliorer les Estimations**

4. **Estimation nombre de lits** :
   - Actuellement : `population / 100`
   - Améliorer avec formule basée sur type d'établissement

5. **Estimation consommation** :
   - Utiliser les services backend au lieu de calculs frontend simples

---

## 📝 Résumé

### ✅ **Ce qui fonctionne**
- Collecte des données (B1-B5)
- Création de l'établissement dans le backend
- Navigation vers page AI après création

### ❌ **Ce qui manque**
- Utilisation des services backend pour calculs (actuellement calculs frontend simples)
- Estimation précise de consommation (utiliser `ConsumptionEstimationService`)
- Dimensionnement précis (utiliser `SizingService`)
- Simulation optionnelle après création

### 🎯 **Objectif**
Remplacer les calculs simples du frontend par les services backend sophistiqués qui existent déjà, pour avoir des résultats cohérents entre Cas 1 et Cas 2.


