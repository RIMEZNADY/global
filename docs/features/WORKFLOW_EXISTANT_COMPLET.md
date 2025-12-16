# 📋 WORKFLOW COMPLET - ÉTABLISSEMENT EXISTANT

## 🎯 Vue d'ensemble

Le workflow "EXISTANT" permet à un utilisateur de créer un profil pour un établissement médical existant en entrant ses données réelles de consommation et de configuration. Le système calcule ensuite les recommandations optimales pour un microgrid solaire, les économies potentielles, l'impact environnemental, et bien plus.

---

## 🔄 FLUX COMPLET DU WORKFLOW

```
Login/Register
  ↓
HomePage (Dashboard = EstablishmentsListPage)
  ↓
Créer un nouvel établissement
  ↓
InstitutionChoicePage → Choix "EXISTANT"
  ↓
FormA1Page → Identification
  ↓
FormA2Page → Informations techniques
  ↓
FormA3Page → Analyse et graphiques (prévisualisation)
  ↓
FormA4Page → Recommandations (prévisualisation)
  ↓
FormA5Page → Sélection des équipements
  ↓
Création de l'établissement dans le backend
  ↓
ComprehensiveResultsPage → Résultats complets (7 onglets)
  ↓
EstablishmentsListPage → Gestion (CRUD)
```

---

## 📝 ÉTAPE 1 : INSTITUTION CHOICE PAGE

### **Page**: `InstitutionChoicePage`

**Ce que voit l'utilisateur :**
- Question : "are you here to :"
- Deux boutons colorés :
  - **EXISTANT** (violet/bleu) avec icône 🏥
  - **NEW** (cyan) avec icône ➕

**Action utilisateur :**
- Clique sur "EXISTANT"

**Navigation :**
- → `FormA1Page`

---

## 📝 ÉTAPE 2 : FORMULAIRE A1 - IDENTIFICATION

### **Page**: `FormA1Page`

**Titre** : "Identification de l'établissement"

### **Indicateur de progression** :
```
[████░░░░░░] Étape 1/3
Identification | Technique | Équipements
```

### **Données collectées** :

#### 1. **Type d'établissement** (Obligatoire ✅)
- **Widget** : `HierarchicalTypeSelector`
- **Options disponibles** :
  - **CHU** (Centre Hospitalier Universitaire)
  - **Hôpitaux** :
    - Hôpital Régional
    - Hôpital Général
    - Hôpital Spécialisé
  - **Cliniques** :
    - Clinique Privée
    - Clinique Publique
  - **Centres de Santé** :
    - Centre de Santé Urbain
    - Centre de Santé Rural
  - **Autres** :
    - Dispensaire
    - Centre de Dialyse
    - Centre d'Imagerie Médicale
    - Laboratoire
    - Pharmacie
    - Centre de Rééducation
- **Format backend** : String (ex: `"CHU"`, `"HOPITAL_REGIONAL"`)
- **Valeur transmise** : `institutionType` (String)

#### 2. **Nom de l'établissement** (Obligatoire ✅)
- **Widget** : `TextFormField`
- **Exemple** : "Hôpital Ibn Sina"
- **Validation** : Ne peut pas être vide
- **Valeur transmise** : `institutionName` (String)

#### 3. **Nombre de lits** (Obligatoire ✅)
- **Widget** : `TextFormField`
- **Type** : Nombre entier (int)
- **Exemple** : 150
- **Validation** : Doit être un nombre valide > 0
- **Valeur transmise** : `numberOfBeds` (int)
- **Usage** : Utilisé par le backend pour estimer la consommation si non fournie

#### 4. **Localisation GPS** (Obligatoire ✅)
- **Widget** : Carte interactive (`FlutterMap`)

**Fonctionnalités :**
- **Activation GPS** :
  - Vérification automatique de la permission au démarrage
  - Si permission refusée : Bouton "Activer la localisation" affiché
  - Demande de permission explicite via `LocationService.requestLocationPermission()`
  - Vérification GPS activé (`Geolocator.isLocationServiceEnabled()`)
  - Récupération position actuelle via `LocationService.getCurrentLocation()`

- **Affichage** :
  - Carte OpenStreetMap centrée sur la position
  - Marqueur de position (cercle coloré selon la zone solaire)
  - Coordonnées précises affichées : `Lat: X.XXXXXX, Lng: Y.YYYYYY` (6 décimales)
  - Zone solaire déterminée automatiquement (A, B, C, D)
  - Message : "• Cliquez sur la carte pour changer"

- **Sélection manuelle** :
  - L'utilisateur peut cliquer n'importe où sur la carte
  - La position est mise à jour automatiquement
  - La zone solaire est recalculée via `SolarZoneService.getSolarZoneFromLocation()`

**Zones solaires au Maroc :**
- **Zone A** : Très fort rayonnement (Sud-Est, Sahara) - Couleur : Orange
- **Zone B** : Fort rayonnement (Centre, Sud) - Couleur : Jaune
- **Zone C** : Rayonnement moyen (Nord, Côtes) - Couleur : Bleu clair
- **Zone D** : Rayonnement modéré (Rif, Hautes altitudes) - Couleur : Bleu foncé

**Valeurs transmises :**
- `location` : `Position` (latitude, longitude)
- `solarZone` : `SolarZone` (calculé automatiquement, pas transmis directement)

**Sauvegarde automatique** :
- Les données sont sauvegardées dans un brouillon (`DraftService`) automatiquement

### **Navigation :**
- **Bouton "Suivant"** : Valide le formulaire et navigue vers `FormA2Page`
- **Validation** : Tous les champs doivent être remplis et la localisation doit être obtenue

---

## 📝 ÉTAPE 3 : FORMULAIRE A2 - INFORMATIONS TECHNIQUES

### **Page**: `FormA2Page`

**Titre** : "Informations techniques"

### **Indicateur de progression** :
```
[████████░░] Étape 2/3
Identification | Technique | Équipements
```

### **Données collectées** :

**Tous les champs supportent deux modes :**
1. **Valeur exacte** : L'utilisateur entre une seule valeur
2. **Intervalle** : L'utilisateur entre une valeur min et max (pour les cas d'incertitude)

#### 1. **Surface installable pour panneau solaire (m²)** (Obligatoire ✅)

**Mode Valeur exacte :**
- **Widget** : `TextFormField`
- **Exemple** : 500
- **Unité** : m²

**Mode Intervalle :**
- **Widgets** : Deux `TextFormField` (Min et Max)
- **Exemple** : Min: 400, Max: 600
- **Calcul** : Le système utilisera la moyenne : (Min + Max) / 2

**Aide contextuelle** (ℹ️) :
> "La surface installable représente l'espace disponible sur le toit ou le terrain de votre établissement pour installer des panneaux solaires photovoltaïques. Cette surface détermine directement la quantité d'énergie solaire que vous pouvez produire."

**Valeur transmise** : `solarSurface` (double)

**Alertes contextuelles** (calculées en temps réel) :
- Si autonomie < 50% et surface < 500 m² :
  > ⚠️ Surface solaire insuffisante: Avec cette configuration, votre production solaire couvrirait seulement X% de votre consommation mensuelle. Pour une autonomie > 50%, une surface d'au moins 500 m² est recommandée.

- Si autonomie ≥ 50% :
  > ✅ Bonne configuration: Votre production solaire pourrait couvrir X% de votre consommation mensuelle. Cela signifie que plus de la moitié de votre énergie proviendrait du solaire.

- Si autonomie > 100% :
  > ✅ Excellente configuration: Votre production solaire pourrait couvrir l'ensemble de vos besoins, voire produire un excédent d'énergie.

#### 2. **Surface non critiques (m²)** (Obligatoire ✅)

**Mode Valeur exacte :**
- **Widget** : `TextFormField`
- **Exemple** : 300

**Mode Intervalle :**
- **Widgets** : Min et Max

**Aide contextuelle** (ℹ️) :
> "La surface non critique représente la partie de votre surface installable qui peut être utilisée pour des équipements non essentiels au fonctionnement de l'établissement. Cette distinction permet d'optimiser l'installation pour garantir la continuité des services critiques en cas de panne."

**Valeur transmise** : `nonCriticalSurface` (double)

#### 3. **Consommation mensuelle (kWh)** (Obligatoire ✅)

**Mode Valeur exacte :**
- **Widget** : `TextFormField`
- **Exemple** : 50000
- **Unité** : kWh/mois

**Mode Intervalle :**
- **Widgets** : Min et Max

**Aide contextuelle** (ℹ️) :
> "La consommation mensuelle représente la quantité totale d'électricité consommée par votre établissement sur une période d'un mois. Cette valeur peut être trouvée sur votre facture d'électricité mensuelle. Si vous n'avez pas cette information exacte, vous pouvez utiliser un intervalle."

**Valeur transmise** : `monthlyConsumption` (double)

**Note** : Si non fournie, le backend peut estimer cette consommation à partir du type d'établissement et du nombre de lits via `ConsumptionEstimationService`.

### **Sauvegarde automatique** :
- Toutes les valeurs sont sauvegardées dans `DraftService.saveFormA2Draft()` automatiquement quand l'utilisateur tape
- Les brouillons sont chargés automatiquement au retour sur la page

### **Navigation :**
- **Bouton "Suivant"** : → `FormA3Page`

---

## 📝 ÉTAPE 4 : FORMULAIRE A3 - ANALYSE ET GRAPHIQUES

### **Page**: `FormA3Page`

**Titre** : "Analyse et Graphiques"

### **Ce que voit l'utilisateur :**

Cette page affiche une **prévisualisation** basée sur les données entrées. Les données sont générées localement dans le frontend (simulation simple), pas encore les calculs finaux du backend.

#### 1. **Graphique de Consommation (24h)**
- **Type** : Ligne (`LineChart`)
- **Données** : 24 points représentant la consommation horaire
- **Calcul** :
  ```dart
  baseHourly = monthlyConsumption / (30 * 24)
  variation = baseHourly * 0.3 * (1 + (hour % 12) / 12) // Pic pendant le jour
  hourlyConsumption = baseHourly + variation
  ```
- **Axe X** : Heures (0-23h)
- **Axe Y** : Consommation (kWh)

#### 2. **Graphique de Production Solaire (24h)**
- **Type** : Ligne (`LineChart`)
- **Données** : 24 points représentant la production solaire horaire
- **Calcul** :
  ```dart
  // Production uniquement entre 6h et 18h
  if (hour >= 6 && hour <= 18) {
    hourOfDay = hour - 6
    distanceFromPeak = abs(hourOfDay - 6)
    efficiency = 1 - (distanceFromPeak / 6) * 0.5
    production = solarSurface * 0.2 * efficiency // 200W/m² efficacité
  }
  ```
- **Axe X** : Heures (0-23h)
- **Axe Y** : Production (kWh)

#### 3. **Graphique d'État de Charge Batterie (24h)**
- **Type** : Ligne (`LineChart`)
- **Données** : 24 points représentant le SOC (State of Charge) de la batterie
- **Calcul** :
  ```dart
  batteryCapacity = monthlyConsumption * 0.1 // 10% de la consommation mensuelle
  currentSOC = 50% // Départ à 50%
  // Pour chaque heure :
  netEnergy = production - consumption
  if (netEnergy > 0) {
    currentSOC = currentSOC + (netEnergy / batteryCapacity * 100) // Charge
  } else {
    currentSOC = currentSOC + (netEnergy / batteryCapacity * 100) // Décharge
  }
  currentSOC = clamp(0, 100, currentSOC)
  ```
- **Axe X** : Heures (0-23h)
- **Axe Y** : SOC (%) (0-100%)

**Note** : Ces graphiques sont des simulations locales. Les données réelles seront calculées par le backend après création de l'établissement.

### **Navigation :**
- **Bouton "Suivant"** : → `FormA4Page`
- **Transmet** : `dailyConsumption`, `dailyProduction` (calculés localement)

---

## 📝 ÉTAPE 5 : FORMULAIRE A4 - RECOMMANDATIONS

### **Page**: `FormA4Page`

**Titre** : "Recommandations"

### **Ce que voit l'utilisateur :**

Cette page affiche des **recommandations préliminaires** calculées localement.

#### 1. **Économie possible**
- **Valeur** : X DH/an
- **Calcul** :
  ```dart
  autonomyPercentage = (dailyProduction / dailyConsumption * 100).clamp(0, 100)
  annualGridConsumption = monthlyConsumption * 12 * (1 - autonomyPercentage / 100)
  annualSavings = annualGridConsumption * 1.5 // Prix: 1.5 DH/kWh
  ```
- **Carte** : Fond vert dégradé

#### 2. **Pourcentage d'autonomie possible**
- **Valeur** : X %
- **Calcul** :
  ```dart
  autonomyPercentage = (dailyProduction / dailyConsumption * 100).clamp(0, 100)
  ```
- **Carte** : Fond bleu dégradé

#### 3. **Puissance PV recommandée**
- **Valeur** : X kW
- **Calcul** :
  ```dart
  recommendedPVPower = solarSurface * 0.2 // 200W par m²
  ```
- **Carte** : Fond orange dégradé

#### 4. **Capacité batterie recommandée**
- **Valeur** : X kWh
- **Calcul** :
  ```dart
  avgHourlyConsumption = monthlyConsumption / (30 * 24)
  recommendedBatteryCapacity = avgHourlyConsumption * 12 // 12 heures d'autonomie
  ```
- **Carte** : Fond violet dégradé

**Note** : Ces recommandations sont des estimations locales. Les calculs finaux (backend) utiliseront des formules plus précises avec données météorologiques réelles, classes d'irradiation, etc.

### **Navigation :**
- **Bouton "Suivant"** : → `FormA5Page`
- **Transmet** : `recommendedPVPower`, `recommendedBatteryCapacity`

---

## 📝 ÉTAPE 6 : FORMULAIRE A5 - SÉLECTION DES ÉQUIPEMENTS

### **Page**: `FormA5Page`

**Titre** : "Sélection des équipements"

### **Indicateur de progression** :
```
[████████████] Étape 3/3
Identification | Technique | Équipements
```

### **Données collectées** :

L'utilisateur doit sélectionner **4 équipements** (tous obligatoires ✅) :

#### 1. **Panneau Solaire**
- **Options disponibles** :
  - Panneau Solaire Monocristallin 400W - 850 DH - Efficacité: 21.5%
  - Panneau Solaire Polycristallin 380W - 720 DH - Efficacité: 19.2%
  - Panneau Solaire Bifacial 450W - 1100 DH - Efficacité: 22.8%
  - Panneau Solaire PERC 410W - 950 DH - Efficacité: 21.8%
- **Prix moyen marché** : 1.8-2.6 DH/W
- **Valeur transmise** : `selectedPanel` (String: ID de l'équipement)

#### 2. **Batterie**
- **Options disponibles** :
  - Batterie Lithium-ion 10kWh - 45000 DH - 6000 cycles
  - Batterie Lithium-ion 15kWh - 65000 DH - 6000 cycles
  - Batterie Lithium Fer Phosphate 12kWh - 52000 DH - 8000 cycles
  - Batterie AGM 20kWh - 38000 DH - 1500 cycles
- **Prix moyen marché** : 1500-5000 DH/kWh
- **Valeur transmise** : `selectedBattery` (String: ID de l'équipement)

#### 3. **Onduleur (Inverter)**
- **Options disponibles** :
  - Onduleur Hybride 5kW - 12000 DH
  - Onduleur Hybride 10kW - 22000 DH
  - Onduleur Grid-Tie 8kW - 15000 DH
  - Onduleur Hybride 15kW - 32000 DH
- **Prix moyen marché** : 1500-2500 DH/kW
- **Valeur transmise** : `selectedInverter` (String: ID de l'équipement)

#### 4. **Régulateur (Controller)**
- **Options disponibles** :
  - Régulateur MPPT 60A - 3500 DH
  - Régulateur MPPT 80A - 4800 DH
  - Régulateur MPPT 100A - 6200 DH
  - Régulateur PWM 50A - 1800 DH
- **Prix moyen marché** : 30-65 DH/A
- **Valeur transmise** : `selectedController` (String: ID de l'équipement)

### **Action finale** :

Quand l'utilisateur clique sur **"Terminer"** :

1. **Validation** : Tous les équipements doivent être sélectionnés
2. **Création de l'établissement** :
   - Appel API : `EstablishmentService.createEstablishment(EstablishmentRequest)`
   - **Données envoyées au backend** :
     ```dart
     {
       "name": institutionName,
       "type": EstablishmentMapper.mapInstitutionTypeToBackend(institutionType),
       "numberOfBeds": numberOfBeds,
       "latitude": location.latitude,
       "longitude": location.longitude,
       "installableSurfaceM2": solarSurface,
       "nonCriticalSurfaceM2": nonCriticalSurface,
       "monthlyConsumptionKwh": monthlyConsumption,
       "existingPvInstalled": false
     }
     ```
   - **Réponse** : `EstablishmentResponse` avec `id` créé
3. **Nettoyage** : Suppression de tous les brouillons (`DraftService.clearAllDrafts()`)
4. **Navigation** : → `ComprehensiveResultsPage(establishmentId: created.id)`

---

## 📊 ÉTAPE 7 : RÉSULTATS COMPLETS

### **Page**: `ComprehensiveResultsPage`

**Titre** : "Résultats Complets"

Cette page est la **pièce maîtresse** du système. Elle affiche tous les résultats calculés par le backend, organisés en **7 onglets** :

### **Navigation par onglets** :

```
[Vue d'ensemble] [Financier] [Environnemental] [Technique] [Comparatif] [Alertes] [Prédictions IA]
```

### **Fonctionnalités générales** :

- **Mise à jour automatique** : Toutes les 30 secondes (configurable via bouton Play/Pause)
- **Bouton Actualiser** : Recharge manuelle des données
- **Actions disponibles** :
  - **Modifier** : Éditer l'établissement (`EstablishmentEditPage`)
  - **Exporter PDF** : Générer un rapport PDF complet
  - **Partager** : Partager les résultats via l'application de partage native
  - **Retour Dashboard** : Retourner à la liste des établissements

---

## 📊 ONGLET 1 : VUE D'ENSEMBLE

### **Métriques principales affichées** :

#### 1. **Score Global** (0-100)
- **Affichage** : Grande carte avec score, icône ⭐, gradient coloré
- **Calcul backend** (`ComprehensiveResultsService.calculateGlobalScore()`) :
  ```java
  // Pondération des 4 catégories
  autonomyScore = (autonomy / 100) * 40  // 40% du score
  economicScore = (normalizedROI) * 30     // 30% du score
  resilienceScore = (reliability / 100) * 20  // 20% du score
  environmentalScore = (normalizedCO2) * 10   // 10% du score
  
  globalScore = autonomyScore + economicScore + resilienceScore + environmentalScore
  ```
- **Explication** : Score composite évaluant la qualité globale du projet de microgrid

#### 2. **Autonomie Énergétique** (%)
- **Calcul backend** (`SizingService.calculateEnergyAutonomy()`) :
  ```java
  monthlyPvProduction = PvCalculationService.calculateMonthlyPvProduction(
    pvSurfaceM2, 
    irradiationClass
  )
  autonomy = (monthlyPvProduction / monthlyConsumption) * 100
  autonomy = min(autonomy, 100)  // Limité à 100%
  ```
- **Explication** : Pourcentage de la consommation mensuelle couverte par la production solaire

#### 3. **Économies Annuelles** (DH/an)
- **Calcul backend** (`SizingService.calculateAnnualSavings()`) :
  ```java
  annualConsumption = monthlyConsumption * 12
  energyFromPv = annualConsumption * (autonomyPercentage / 100)
  annualSavings = energyFromPv * electricityPriceDhPerKwh  // 1.2 DH/kWh par défaut
  ```
- **Explication** : Montant économisé chaque année sur la facture d'électricité

#### 4. **ROI (Retour sur Investissement)** (années)
- **Calcul backend** (`SizingService.calculateROI()`) :
  ```java
  installationCost = estimateInstallationCost(recommendedPvPower, recommendedBattery)
  // Coût = (PV * 2500) + (Batterie * 4000) + (Inverter * 2000) + 20% installation
  roi = installationCost / annualSavings
  ```
- **Explication** : Nombre d'années nécessaires pour récupérer l'investissement initial

#### 5. **Score par Catégorie**
- **4 sous-scores** affichés en cartes :
  - **Autonomie** : 0-100 (40% du score global)
  - **Économique** : 0-100 (30% du score global)
  - **Résilience** : 0-100 (20% du score global)
  - **Environnemental** : 0-100 (10% du score global)

#### 6. **Graphique Comparatif (Avant/Après)**
- **Type** : Graphique à barres (`BarChart`)
- **Données** :
  - Consommation mensuelle avant/après (kWh)
  - Facture mensuelle avant/après (DH)
  - Autonomie avant (0%) / après (%)

---

## 💰 ONGLET 2 : FINANCIER

### **Métriques financières détaillées** :

#### 1. **Coût d'Installation** (DH)
- **Calcul backend** (`ComprehensiveResultsService.estimateInstallationCost()`) :
  ```java
  pvCost = pvPower * 2500        // 2500 DH/kW
  batteryCost = batteryCapacity * 4000  // 4000 DH/kWh
  inverterCost = pvPower * 2000  // 2000 DH/kW
  installationCost = (pvCost + batteryCost + inverterCost) * 0.2  // 20%
  
  totalCost = pvCost + batteryCost + inverterCost + installationCost
  ```
- **Explication** : Coût total d'installation du microgrid (équipements + installation)

#### 2. **Économies Annuelles** (DH/an)
- (Voir Vue d'ensemble)

#### 3. **ROI** (années)
- (Voir Vue d'ensemble)

#### 4. **NPV (Net Present Value) sur 20 ans** (DH)
- **Calcul backend** (`ComprehensiveResultsService.calculateFinancialAnalysis()`) :
  ```java
  DISCOUNT_RATE = 0.06  // 6% taux d'actualisation
  npv = -installationCost
  for (int year = 1; year <= 20; year++) {
    npv += annualSavings / Math.pow(1 + DISCOUNT_RATE, year)
  }
  ```
- **Explication** : Valeur actuelle nette du projet sur 20 ans, tenant compte de la valeur temporelle de l'argent

#### 5. **IRR (Internal Rate of Return)** (%)
- **Calcul backend** :
  ```java
  irr = (annualSavings / installationCost) * 100
  ```
- **Explication** : Taux de rendement interne du projet

#### 6. **Économies Cumulées**
- **10 ans** : `annualSavings * 10` (DH)
- **20 ans** : `annualSavings * 20` (DH)

#### 7. **Graphique d'Évolution Financière**
- **Type** : Ligne (`LineChart`)
- **Données** : Économies cumulées par année (sur 20 ans)
- **Axe X** : Années (1-20)
- **Axe Y** : Économies cumulées (DH)

---

## 🌍 ONGLET 3 : ENVIRONNEMENTAL

### **Impact environnemental** :

#### 1. **Production PV Annuelle** (kWh/an)
- **Calcul backend** :
  ```java
  annualPvProduction = monthlyPvProduction * 12
  ```
- **Explication** : Quantité totale d'énergie solaire produite sur une année

#### 2. **CO₂ Évité** (tonnes/an)
- **Calcul backend** (`ComprehensiveResultsService.calculateEnvironmentalImpact()`) :
  ```java
  CO2_EMISSION_FACTOR = 0.7  // kg CO2/kWh (mix énergétique Maroc)
  co2Avoided = annualPvProduction * CO2_EMISSION_FACTOR / 1000  // Conversion en tonnes
  ```
- **Explication** : Quantité de dioxyde de carbone non émis grâce à l'énergie solaire

#### 3. **Équivalent Arbres** (nombre)
- **Calcul backend** :
  ```java
  CO2_PER_TREE = 20.0  // kg CO2/an par arbre
  equivalentTrees = co2Avoided * 1000 / CO2_PER_TREE
  ```
- **Explication** : Nombre d'arbres nécessaires pour absorber la même quantité de CO₂

#### 4. **Équivalent Voitures** (nombre)
- **Calcul backend** :
  ```java
  CO2_PER_CAR = 2000.0  // kg CO2/an par voiture
  equivalentCars = co2Avoided * 1000 / CO2_PER_CAR
  ```
- **Explication** : Nombre de voitures retirées de la route pour équivaloir à la réduction de CO₂

#### 5. **Graphique d'Émissions Évitées**
- **Type** : Ligne (`LineChart`)
- **Données** : Émissions évitées par mois (sur 12 mois)

---

## 🔧 ONGLET 4 : TECHNIQUE

### **Recommandations techniques** :

#### 1. **Puissance PV Recommandée** (kW)
- **Calcul backend** (`SizingService.calculateRecommendedPvPower()`) :
  ```java
  PANEL_EFFICIENCY = 0.20
  PERFORMANCE_FACTOR = 0.80
  SAFETY_FACTOR = 1.3
  
  dailyConsumption = monthlyConsumption / 30
  averageIrradiance = MeteoDataService.getAverageIrradiance(irradiationClass)
  // Irradiance selon zone: A=6.0, B=5.5, C=5.0, D=4.5 kWh/m²/jour
  
  requiredDailyProduction = dailyConsumption
  pvPowerKwc = requiredDailyProduction / (averageIrradiance * PANEL_EFFICIENCY * PERFORMANCE_FACTOR)
  pvPowerKwc = pvPowerKwc * SAFETY_FACTOR  // Facteur de sécurité 30%
  ```
- **Explication** : Puissance photovoltaïque optimale pour couvrir la consommation

#### 2. **Capacité Batterie Recommandée** (kWh)
- **Calcul backend** (`SizingService.calculateRecommendedBatteryCapacityFromMonthly()`) :
  ```java
  AUTONOMY_DAYS = 2.0  // 2 jours d'autonomie recommandés
  SAFETY_FACTOR = 1.3
  
  dailyConsumption = monthlyConsumption / 30
  batteryCapacity = dailyConsumption * AUTONOMY_DAYS * SAFETY_FACTOR
  ```
- **Explication** : Capacité de stockage nécessaire pour assurer 2 jours d'autonomie

#### 3. **Surface PV Nécessaire** (m²)
- **Calcul backend** :
  ```java
  surface = PvCalculationService.calculateRequiredSurface(pvPowerKwc)
  // Environ 5 m² par kWc
  ```

#### 4. **Production Mensuelle Estimée** (kWh/mois)
- **Calcul backend** :
  ```java
  monthlyPvProduction = PvCalculationService.calculateMonthlyPvProduction(
    pvSurfaceM2, 
    irradiationClass
  )
  ```

#### 5. **Graphique de Production vs Consommation**
- **Type** : Ligne (`LineChart`)
- **Données** : Production et consommation par mois (sur 12 mois)

---

## 📊 ONGLET 5 : COMPARATIF

### **Comparaison Avant/Après Installation** :

#### **Section Comparaison** :

| Métrique | Avant | Après |
|----------|-------|-------|
| **Consommation mensuelle** | X kWh/mois | Y kWh/mois |
| **Facture mensuelle** | X DH/mois | Y DH/mois |
| **Facture annuelle** | X DH/an | Y DH/an |
| **Consommation réseau** | X kWh/mois | Y kWh/mois |
| **Autonomie énergétique** | 0% | X% |

**Calcul backend** (`ComprehensiveResultsService.calculateBeforeAfterComparison()`) :
```java
// AVANT
beforeMonthlyBill = monthlyConsumption * electricityPrice  // 1.2 DH/kWh
beforeAnnualBill = beforeMonthlyBill * 12
beforeGridConsumption = monthlyConsumption
beforeAutonomy = 0.0

// APRÈS
afterAutonomy = calculateEnergyAutonomy(...)
afterGridConsumption = monthlyConsumption * (1 - afterAutonomy / 100)
afterMonthlyBill = afterGridConsumption * electricityPrice
afterAnnualBill = afterMonthlyBill * 12
```

#### **Scénarios "What-If" Interactifs** :

L'utilisateur peut cliquer sur des scénarios pour simuler différents cas :

1. **Scénario 1 : Augmentation de 20% de la consommation**
   - Simulation avec `consumption * 1.2`
   - Comparaison des résultats

2. **Scénario 2 : Ajout de 100 m² de panneaux**
   - Simulation avec `solarSurface + 100`
   - Comparaison des résultats

3. **Scénario 3 : Réduction de 30% de la facture**
   - Calcul de la surface nécessaire
   - Comparaison des résultats

**Fonctionnement** :
- Clic sur un scénario → Appel `AiService.simulate()` avec nouveaux paramètres
- Affichage des résultats comparatifs dans un dialog

---

## 🚨 ONGLET 6 : ALERTES

### **Alertes et recommandations** :

Les alertes sont générées par `EstablishmentService.getRecommendations()`.

#### **Types d'alertes** :

1. **Alertes de Performance** :
   - Autonomie < 30% → Recommandation d'augmenter la surface PV
   - ROI > 15 ans → Recommandation d'optimiser la configuration
   - Production < 50% consommation → Recommandation d'ajouter des panneaux

2. **Alertes Financières** :
   - Coût installation élevé → Recommandation d'équipements alternatifs
   - Économies faibles → Analyse de rentabilité

3. **Alertes Techniques** :
   - Capacité batterie insuffisante → Recommandation d'augmenter la capacité
   - Surface non critique élevée → Optimisation de la configuration

#### **Affichage** :
- Cartes d'alerte avec icônes (⚠️, ✅, ℹ️)
- Couleurs selon sévérité (rouge, orange, vert, bleu)
- Actions recommandées cliquables

---

## 🤖 ONGLET 7 : PRÉDICTIONS IA

### **Données générées par Machine Learning** :

#### **1. Prévisions Long Terme** (`AiService.getForecast()`)
- **Horizon** : 7, 14, 30, 90 jours (sélectionnable)
- **Données** :
  - Prévision de consommation (kWh/jour)
  - Prévision de production PV (kWh/jour)
  - Prévision météorologique
- **Graphique** : Ligne avec bande d'incertitude

#### **2. Recommandations ML** (`AiService.getMlRecommendations()`)
- **Recommandations optimisées** basées sur :
  - Données historiques similaires
  - Modèles de ROI entraînés
  - Patterns de consommation
- **Affichage** : Liste de recommandations avec explications

#### **3. Détection d'Anomalies** (`AiService.getAnomalies()`)
- **Période** : 7 derniers jours
- **Détection** :
  - Pic de consommation anormal
  - Production PV sous-optimale
  - Anomalies dans les patterns
- **Graphique** : Timeline avec points d'anomalies marqués

**Note** : Ces données nécessitent un historique suffisant ou des données d'entraînement. Si indisponibles, un message informatif est affiché.

---

## 👤 PROFIL UTILISATEUR

### **Page** : `EstablishmentsListPage` (Dashboard)

**Ce que voit l'utilisateur** :

#### **En-tête** :
- **Email utilisateur** : Affiché en haut (ex: `user@example.com`)
- **Titre** : "Mes Établissements"

#### **Bouton principal** :
- **"Créer un nouvel établissement"** :
  - Grand bouton avec icône ➕
  - Navigation → `InstitutionChoicePage`

#### **Liste des établissements** :

Chaque établissement est affiché dans une **carte** avec :

1. **Informations de base** :
   - Nom de l'établissement
   - Type d'établissement
   - Nombre de lits
   - Consommation mensuelle (kWh)
   - Date de création

2. **Actions disponibles** :
   - **Clic sur la carte** : Navigue vers `ComprehensiveResultsPage`
   - **Bouton "Modifier"** : Navigue vers `EstablishmentEditPage`
   - **Menu (3 points)** :
     - Modifier
     - Supprimer (avec confirmation)

#### **Opérations CRUD** :

- **CREATE** : Via bouton "Créer un nouvel établissement"
- **READ** : Liste chargée automatiquement via `EstablishmentService.getUserEstablishments()`
- **UPDATE** : Via `EstablishmentEditPage` → `EstablishmentService.updateEstablishment()`
- **DELETE** : Via menu → Confirmation → `EstablishmentService.deleteEstablishment()`

---

## 🔄 FONCTIONNALITÉS ADDITIONNELLES

### **1. Sauvegarde automatique (Brouillons)**
- **Service** : `DraftService`
- **Fonctionnement** :
  - Les données de `FormA2Page` sont sauvegardées automatiquement quand l'utilisateur tape
  - Chargement automatique au retour sur la page
  - Suppression après création réussie de l'établissement
- **Utilité** : Évite la perte de données si l'utilisateur quitte l'application

### **2. Export PDF**
- **Service** : `PdfExportService`
- **Contenu** :
  - Informations de l'établissement
  - Recommandations complètes
  - Métriques financières et environnementales
  - Graphiques
- **Format** : PDF téléchargeable

### **3. Partage**
- **Service** : `Share` (package `share_plus`)
- **Contenu** : Résumé textuel des résultats clés
- **Méthodes** : Partage via applications natives (email, SMS, etc.)

### **4. Mise à jour automatique**
- **Fréquence** : Toutes les 30 secondes
- **Bouton Play/Pause** : Active/désactive la mise à jour
- **Bouton Actualiser** : Recharge manuelle immédiate
- **Utilité** : Permet de voir les données en temps réel (si disponibles)

### **5. Édition d'établissement**
- **Page** : `EstablishmentEditPage`
- **Fonctionnalités** :
  - Modification de tous les champs (nom, type, lits, surface, consommation)
  - Mise à jour GPS/localisation
  - Sauvegarde → Recalcul automatique des résultats

### **6. Navigation fluide**
- **Transitions** : Animations slide/fade entre pages
- **Retour** : Bouton retour dans AppBar
- **Breadcrumbs** : Indicateur de progression dans les formulaires

---

## 📐 FORMULES DE CALCUL DÉTAILLÉES

### **1. Production PV Mensuelle**
```java
// Backend: PvCalculationService.calculateMonthlyPvProduction()

// Irradiance moyenne selon zone solaire (kWh/m²/jour)
irradiance = {
  Zone A: 6.0,
  Zone B: 5.5,
  Zone C: 5.0,
  Zone D: 4.5
}

// Production mensuelle (kWh/mois)
monthlyProduction = surfaceM2 * irradiance * 30 * panelEfficiency * performanceFactor
// panelEfficiency = 0.20 (20%)
// performanceFactor = 0.80 (80% pour pertes)
```

### **2. Autonomie Énergétique**
```java
autonomy = (monthlyPvProduction / monthlyConsumption) * 100
autonomy = min(autonomy, 100)  // Plafonné à 100%
```

### **3. Économies Annuelles**
```java
annualConsumption = monthlyConsumption * 12
energyFromPv = annualConsumption * (autonomy / 100)
annualSavings = energyFromPv * electricityPrice  // 1.2 DH/kWh
```

### **4. ROI**
```java
installationCost = (pvPower * 2500) + (batteryCapacity * 4000) + (inverterPower * 2000) * 1.2
roi = installationCost / annualSavings  // années
```

### **5. NPV (20 ans)**
```java
discountRate = 0.06  // 6%
npv = -installationCost
for (year = 1 to 20) {
  npv += annualSavings / (1 + discountRate)^year
}
```

### **6. CO₂ Évité**
```java
co2EmissionFactor = 0.7  // kg CO2/kWh (mix énergétique Maroc)
co2Avoided = annualPvProduction * co2EmissionFactor / 1000  // tonnes/an
```

---

## 🎨 EXPÉRIENCE UTILISATEUR

### **Design** :
- **Palette de couleurs** : Bleu confiance (#2563EB), Vert énergie (#059669), Violet moderne (#7C3AED)
- **Thème** : Mode clair/sombre disponible
- **Responsive** : Adapté mobile et desktop
- **Accessibilité** : Contrastes optimisés, tooltips explicatifs

### **Interactions** :
- **Tooltips d'aide** : Icône ℹ️ sur chaque métrique pour explication détaillée
- **Feedback visuel** : SnackBars pour succès/erreurs
- **Chargement** : Indicateurs de progression
- **Validation** : Messages d'erreur clairs

### **Performance** :
- **Chargement parallèle** : Données chargées en parallèle (`Future.wait`)
- **Mise en cache** : Résultats mis en cache localement
- **Optimisation** : Images et graphiques optimisés

---

## 🔒 SÉCURITÉ ET AUTHENTIFICATION

- **Authentification requise** : Toutes les opérations nécessitent un token JWT valide
- **Vérification session** : Vérification automatique au chargement des données
- **Redirection** : Si session expirée → Redirection vers page de login
- **Isolation des données** : Chaque utilisateur voit uniquement ses établissements

---

## 📱 PAGES ET NAVIGATION

### **Structure de navigation** :

```
HomePage (Bottom Navigation)
├─ EstablishmentsListPage (Dashboard)
│  ├─ → ComprehensiveResultsPage
│  ├─ → EstablishmentEditPage
│  └─ → InstitutionChoicePage
├─ AIPredictionPage
└─ AutoLearningPage
```

### **Workflow EXISTANT complet** :

```
Login/Register
  ↓
EstablishmentsListPage
  ↓ (Créer nouvel établissement)
InstitutionChoicePage
  ↓ (EXISTANT)
FormA1Page
  ↓
FormA2Page
  ↓
FormA3Page (prévisualisation)
  ↓
FormA4Page (prévisualisation)
  ↓
FormA5Page
  ↓ (Création)
ComprehensiveResultsPage (7 onglets)
  ↓ (Retour)
EstablishmentsListPage
```

---

## ✅ RÉSUMÉ DES DONNÉES

### **Données d'entrée utilisateur** :

1. **FormA1** :
   - Type d'établissement (String)
   - Nom (String)
   - Nombre de lits (int)
   - Localisation GPS (double, double)

2. **FormA2** :
   - Surface installable (double, m²)
   - Surface non critique (double, m²)
   - Consommation mensuelle (double, kWh)

3. **FormA5** :
   - Panneau solaire sélectionné (String: ID)
   - Batterie sélectionnée (String: ID)
   - Onduleur sélectionné (String: ID)
   - Régulateur sélectionné (String: ID)

### **Données calculées backend** :

- Recommandations de dimensionnement
- Métriques financières (ROI, NPV, IRR, économies)
- Impact environnemental (CO₂, équivalents)
- Scores et évaluations
- Prévisions IA (si disponibles)
- Alertes et recommandations

### **Données affichées** :

- **7 onglets** de résultats détaillés
- **Graphiques** interactifs (lignes, barres, cercles)
- **Métriques** avec explications (tooltips)
- **Comparaisons** avant/après
- **Scénarios** What-If interactifs

---

**Ce document couvre l'intégralité du workflow "EXISTANT" avec tous les détails techniques, calculs, et fonctionnalités. Chaque étape est documentée avec précision pour garantir une compréhension complète du système.**









