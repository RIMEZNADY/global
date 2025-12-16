# 🏗️ Organisation Fonctionnelle - Plateforme SMART MICROGRID

## 📋 Vue d'ensemble

La plateforme SMART MICROGRID est un système complet de gestion et d'optimisation de microgrids solaires pour établissements médicaux. Elle permet de dimensionner, simuler, analyser et optimiser des installations photovoltaïques avec stockage, en fournissant des analyses financières, environnementales et techniques détaillées.

---

## 🎯 Architecture Générale

### Structure en 3 Couches

```
┌─────────────────────────────────────────────────────────────┐
│                    COUCHE PRÉSENTATION                      │
│                  Frontend Flutter (Mobile/Web)              │
│  - Interface utilisateur (Flutter)                          │
│  - Formulaires de saisie                                    │
│  - Visualisation des résultats (7 onglets)                  │
│  - Navigation et gestion d'état                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTP/REST API (JWT Authentication)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  COUCHE MÉTIER                              │
│              Backend Spring Boot (Java)                     │
│  - Contrôleurs REST (API endpoints)                         │
│  - Services métier (calculs, logique)                       │
│  - Repositories (accès données)                             │
│  - Sécurité et authentification (JWT)                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTP/REST API (Internal)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│            COUCHE INTELLIGENCE ARTIFICIELLE                 │
│         AI Microservice FastAPI (Python)                    │
│  - Modèles de Machine Learning                              │
│  - Prédictions et recommandations                           │
│  - Détection d'anomalies                                    │
│  - Optimisation avancée                                     │
└─────────────────────────────────────────────────────────────┘
                       │
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                BASE DE DONNÉES                              │
│            PostgreSQL (Port 5434)                           │
│  - Utilisateurs                                             │
│  - Établissements                                           │
│  - Données historiques                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Stack Technique

### Vue d'ensemble

```
Frontend: Flutter/Dart
    ↓
Backend: Spring Boot/Java
    ↓
AI: FastAPI/Python
    ↓
Database: PostgreSQL
```

---

### 📱 Frontend (Couche Présentation)

#### Framework & Langage
- **Flutter** 3.0+ (Framework UI cross-platform)
- **Dart** SDK 3.0+ (Langage de programmation)

#### Bibliothèques Principales
- **fl_chart** ^0.66.0 - Graphiques interactifs (lignes, barres, radar)
- **google_fonts** ^6.1.0 - Polices Google
- **geolocator** ^13.0.1 - Géolocalisation GPS
- **permission_handler** ^11.3.1 - Gestion des permissions
- **flutter_map** ^7.0.2 - Cartes interactives (OpenStreetMap)
- **latlong2** ^0.9.1 - Coordonnées géographiques
- **http** ^1.5.0 - Requêtes HTTP/REST
- **shared_preferences** ^2.2.2 - Stockage local
- **printing** ^5.13.0 - Génération PDF
- **share_plus** ^10.0.0 - Partage de fichiers
- **path_provider** ^2.1.2 - Chemins de fichiers

#### Plateformes Supportées
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **Android** (Mobile & Tablette)
- ✅ **iOS** (iPhone & iPad)

---

### ⚙️ Backend (Couche Métier)

#### Framework & Langage
- **Spring Boot** 3.2.0 (Framework Java)
- **Java** 17+ (Langage de programmation)
- **Maven** (Gestion des dépendances)

#### Technologies Principales
- **Spring Boot Starter Web** - API REST
- **Spring Data JPA** - ORM et accès données
- **Spring Security** - Authentification et sécurité
- **Spring Boot Starter Validation** - Validation des données
- **PostgreSQL Driver** - Connecteur base de données

#### Sécurité
- **JWT (JSON Web Tokens)** v0.12.3
  - `jjwt-api` - API JWT
  - `jjwt-impl` - Implémentation JWT
  - `jjwt-jackson` - Sérialisation JSON

#### Outils de Développement
- **Lombok** - Réduction du code boilerplate
- **Spring Boot DevTools** - Outils de développement (hot reload)
- **Spring Boot Starter Test** - Tests unitaires et d'intégration
- **Spring Security Test** - Tests de sécurité

#### Architecture
- Architecture en couches (Controller → Service → Repository)
- Pattern REST API
- Injection de dépendances (Spring IoC)

---

### 🤖 AI Microservice (Couche Intelligence Artificielle)

#### Framework & Langage
- **FastAPI** 0.115.2 (Framework Python async)
- **Python** 3.8+ (Langage de programmation)
- **Uvicorn** 0.23.2 (Serveur ASGI)

#### Bibliothèques Data Science & ML
- **pandas** 2.1.2 - Manipulation de données
- **numpy** 1.26.1 - Calculs numériques
- **scikit-learn** 1.3.2 - Machine Learning
- **xgboost** 1.7.6 - Modèles de boosting (prédictions)
- **joblib** 1.3.2 - Sauvegarde/chargement modèles ML
- **pyarrow** 15.0.2 - Format Parquet (données)

#### Validation & Communication
- **pydantic** 2.9.2 - Validation de données
- **httpx** 0.24.1 - Client HTTP async
- **requests** 2.32.3 - Requêtes HTTP

#### Modèles ML Utilisés
- **XGBoost** - Prédictions de consommation
- **RandomForest** - Prévisions long terme
- **Isolation Forest** - Détection d'anomalies
- **GradientBoosting** - Prédictions production PV

#### Outils de Test
- **pytest** 7.4.2 - Framework de tests Python

---

### 🗄️ Base de Données

#### SGBD
- **PostgreSQL** 12+ (Base de données relationnelle)
- **Port** : 5434 (développement local)
- **ORM** : Hibernate/JPA (via Spring Data JPA)

#### Entités Principales
- **User** - Utilisateurs du système
- **Establishment** - Établissements médicaux

---

### 🐳 Infrastructure & Déploiement

#### Containerisation
- **Docker** - PostgreSQL en conteneur
- **Docker Compose** - Orchestration services

#### Scripts d'Automatisation
- **PowerShell** - Scripts de démarrage (`start-all-services-mobile.ps1`)
- Scripts de configuration et déploiement

#### Communication Inter-Services
- **HTTP/REST** - Communication API REST
- **JSON** - Format d'échange de données
- **JWT** - Authentification (Frontend ↔ Backend)

---

### 📊 Résumé de la Stack

| Couche | Technologie | Langage | Framework Principal |
|--------|-------------|---------|---------------------|
| **Frontend** | Flutter | Dart | Flutter 3.0+ |
| **Backend** | Spring Boot | Java 17+ | Spring Boot 3.2.0 |
| **AI** | FastAPI | Python 3.8+ | FastAPI 0.115.2 |
| **Base de Données** | PostgreSQL | SQL | PostgreSQL 12+ |
| **Authentification** | JWT | - | jjwt 0.12.3 |
| **ML** | scikit-learn, XGBoost | Python | scikit-learn 1.3.2, XGBoost 1.7.6 |

---

### 🔗 Intégrations Externes

#### Services Tiers
- **Nominatim API** - Géocodage inversé (OpenStreetMap)
- **OpenStreetMap** - Cartes et données géographiques

#### APIs REST
- Communication Frontend ↔ Backend via REST API
- Communication Backend ↔ AI Microservice via REST API interne

---

## 🔧 Organisation Fonctionnelle par Domaine

### 1. 🎨 COUCHE PRÉSENTATION (Frontend Flutter)

#### 1.1. Gestion de l'Authentification
- **Fonctionnalités** :
  - Inscription et connexion utilisateur
  - Gestion de session (JWT)
  - Profil utilisateur
- **Pages** : `LoginPage`, `RegisterPage`, `ProfilePage`

#### 1.2. Gestion des Établissements
- **Fonctionnalités** :
  - Création d'établissement (workflows EXISTANT/NEW)
  - Consultation des établissements
  - Modification et suppression
  - Liste des établissements de l'utilisateur
- **Pages** :
  - `EstablishmentsListPage` (Dashboard)
  - `InstitutionChoicePage` (Choix EXISTANT/NEW)
  - `FormA1Page` à `FormA5Page` (Workflow EXISTANT)
  - `FormB1Page` à `FormB4Page` (Workflow NEW)
  - `EstablishmentEditPage`

#### 1.3. Résultats et Analyses
- **Fonctionnalités** :
  - Affichage des résultats complets (7 onglets)
  - Visualisation de graphiques
  - Comparaisons avant/après
  - Scénarios What-If
- **Pages** :
  - `ComprehensiveResultsPage` (Page principale avec 7 onglets)
  - `AIPredictionPage`
  - `AutoLearningPage`

#### 1.4. Services Frontend
- **ApiService** : Communication avec le backend
- **EstablishmentService** : Gestion des établissements
- **DraftService** : Sauvegarde automatique des brouillons
- **PdfExportService** : Export PDF des résultats
- **LocationService** : Gestion GPS et géolocalisation

---

### 2. ⚙️ COUCHE MÉTIER (Backend Spring Boot)

#### 2.1. Contrôleurs (Couche API REST)

##### 2.1.1. AuthController
- **Responsabilité** : Gestion de l'authentification
- **Endpoints** :
  - `POST /api/auth/register` - Inscription
  - `POST /api/auth/login` - Connexion
  - `GET /api/auth/me` - Profil utilisateur
  - `PUT /api/auth/profile` - Modification profil

##### 2.1.2. EstablishmentController
- **Responsabilité** : Gestion des établissements
- **Endpoints** :
  - `GET /api/establishments` - Liste des établissements
  - `POST /api/establishments` - Création d'établissement
  - `GET /api/establishments/{id}` - Détails d'un établissement
  - `PUT /api/establishments/{id}` - Modification
  - `DELETE /api/establishments/{id}` - Suppression
  - `GET /api/establishments/{id}/comprehensive-results` - **Résultats complets**
  - `GET /api/establishments/{id}/recommendations` - Recommandations
  - `GET /api/establishments/{id}/forecast` - Prévisions IA
  - `GET /api/establishments/{id}/anomalies` - Anomalies
  - `POST /api/establishments/{id}/simulate` - Simulation What-If

##### 2.1.3. LocationController
- **Responsabilité** : Données géographiques
- **Endpoints** :
  - `GET /api/location/solar-zone` - Zone solaire depuis GPS
  - `GET /api/location/population-estimate` - Estimation population

#### 2.2. Services Métier

##### 2.2.1. AuthService
- **Responsabilité** : Logique d'authentification
- **Fonctionnalités** :
  - Validation des identifiants
  - Génération de tokens JWT
  - Gestion des rôles et permissions
  - Chiffrement des mots de passe

##### 2.2.2. EstablishmentService
- **Responsabilité** : Gestion métier des établissements
- **Fonctionnalités** :
  - Validation des données d'entrée
  - Création et mise à jour d'établissements
  - Calcul des recommandations de dimensionnement
  - Filtrage et recherche

##### 2.2.3. ComprehensiveResultsService ⭐
- **Responsabilité** : Orchestration des calculs et analyses complètes
- **Fonctionnalités principales** :
  - `calculateAllResults()` - Point d'entrée principal
  - `calculateEnvironmentalImpact()` - Impact environnemental
  - `calculateGlobalScore()` - Score global et par catégories
  - `calculateFinancialAnalysis()` - Analyse financière (NPV, IRR, ROI)
  - `calculateResilienceMetrics()` - Métriques de résilience
  - `calculateBeforeAfterComparison()` - Comparaison avant/après

##### 2.2.4. Services de Calcul (CalculationServices)

###### SizingService
- **Responsabilité** : Dimensionnement optimal des équipements
- **Fonctionnalités** :
  - `calculateRecommendedPvPower()` - Puissance PV recommandée
  - `calculateRecommendedBatteryCapacity()` - Capacité batterie
  - `calculateEnergyAutonomy()` - Autonomie énergétique
  - `calculateAnnualSavings()` - Économies annuelles
  - `calculateROI()` - Retour sur investissement

###### PvCalculationService
- **Responsabilité** : Calculs photovoltaïques
- **Fonctionnalités** :
  - `calculateMonthlyPvProduction()` - Production mensuelle
  - `calculateRequiredSurface()` - Surface nécessaire
  - `calculateDailyProduction()` - Production journalière
  - Prise en compte des zones d'irradiation (A, B, C, D)

###### SimulationService
- **Responsabilité** : Simulation du comportement énergétique
- **Fonctionnalités** :
  - Simulation horaire (24h)
  - Simulation mensuelle/annuelle
  - Gestion de l'état de charge (SOC) des batteries
  - Optimisation du dispatch énergétique

##### 2.2.5. Services d'Intelligence Artificielle (AIServices)

###### MlRecommendationService
- **Responsabilité** : Recommandations basées sur ML
- **Fonctionnalités** :
  - Recommandations optimisées à partir de modèles entraînés
  - Analyse de patterns similaires
  - Optimisation ROI via ML
- **Communication** : Appelle `AiMicroserviceClient` → `/recommendations/ml`

###### LongTermPredictionService
- **Responsabilité** : Prévisions à long terme
- **Fonctionnalités** :
  - Prévisions consommation (7, 14, 30, 90 jours)
  - Prévisions production PV
  - Prévisions météorologiques intégrées
- **Communication** : Appelle `AiMicroserviceClient` → `/forecast/longterm`

###### AnomalyDetectionService
- **Responsabilité** : Détection d'anomalies
- **Fonctionnalités** :
  - Détection de pics de consommation anormaux
  - Détection de production sous-optimale
  - Alertes automatiques
- **Communication** : Appelle `AiMicroserviceClient` → `/anomalies`

##### 2.2.6. LocationService
- **Responsabilité** : Services géographiques
- **Fonctionnalités** :
  - Détermination de la zone solaire (A, B, C, D) depuis GPS
  - Estimation de population
  - Intégration avec Nominatim (géocodage inversé)
  - Calcul de l'irradiation solaire moyenne

#### 2.3. Repositories (Couche Accès Données)

##### 2.3.1. UserRepository
- **Responsabilité** : Persistance des utilisateurs
- **Opérations** : CRUD sur entité `User`

##### 2.3.2. EstablishmentRepository
- **Responsabilité** : Persistance des établissements
- **Opérations** : CRUD sur entité `Establishment`
- **Requêtes personnalisées** :
  - Recherche par utilisateur
  - Filtrage par type
  - Tri et pagination

#### 2.4. Composants de Communication

##### 2.4.1. AiMicroserviceClient
- **Responsabilité** : Client HTTP pour communiquer avec le microservice IA
- **Endpoints utilisés** :
  - `POST /predict` - Prédiction consommation
  - `POST /optimize` - Optimisation dispatch
  - `POST /predict/pv` - Prédiction production PV
  - `POST /anomalies` - Détection anomalies
  - `POST /forecast/longterm` - Prévisions long terme
  - `POST /recommendations/ml` - Recommandations ML
  - `POST /cluster` - Clustering
  - `GET /health` - Health check

#### 2.5. Sécurité

##### 2.5.1. SecurityConfig
- **Responsabilité** : Configuration de sécurité
- **Fonctionnalités** :
  - Filtres JWT
  - Configuration CORS
  - Protection CSRF
  - Gestion des rôles

##### 2.5.2. JwtAuthenticationFilter
- **Responsabilité** : Filtrage et validation des tokens JWT
- **Fonctionnalités** :
  - Extraction du token depuis headers
  - Validation du token
  - Injection du contexte utilisateur

---

### 3. 🤖 COUCHE INTELLIGENCE ARTIFICIELLE (AI Microservice FastAPI)

#### 3.1. Endpoints Principaux

##### 3.1.1. Prédictions
- `POST /predict` - Prédiction de consommation
  - **Input** : Données historiques, caractéristiques établissement
  - **Output** : Prédictions consommation (24h, 7 jours)

##### 3.1.2. Optimisation
- `POST /optimize` - Optimisation du dispatch énergétique
  - **Input** : Production PV, consommation, capacité batterie
  - **Output** : Plan d'optimisation optimal

##### 3.1.3. Prédictions Photovoltaïques
- `POST /predict/pv` - Prédiction production PV
  - **Input** : Localisation, météo, caractéristiques panneaux
  - **Output** : Prédictions production solaire

##### 3.1.4. Prévisions Long Terme
- `POST /forecast/longterm` - Prévisions long terme
  - **Input** : `establishment_id`, `horizon_days` (7, 14, 30, 90)
  - **Output** : Prévisions consommation/production sur horizon

##### 3.1.5. Recommandations ML
- `POST /recommendations/ml` - Recommandations basées sur ML
  - **Input** : `establishment_id`
  - **Output** : Recommandations optimisées (ROI, dimensionnement)

##### 3.1.6. Détection d'Anomalies
- `POST /anomalies` - Détection d'anomalies
  - **Input** : `establishment_id`, `days` (période)
  - **Output** : Liste des anomalies détectées

##### 3.1.7. Clustering
- `POST /cluster` - Clustering d'établissements
  - **Input** : Caractéristiques établissements
  - **Output** : Groupes d'établissements similaires

#### 3.2. Modèles de Machine Learning

##### 3.2.1. Modèles de Prédiction
- **Modèles entraînés** (format `.joblib`)
  - Modèle consommation long terme
  - Modèle production PV
  - Modèle saisonnier

##### 3.2.2. Modèles de Recommandation
- **Modèles ROI** : Prédiction ROI optimal
- **Modèles de dimensionnement** : Dimensionnement optimisé

##### 3.2.3. Détection d'Anomalies
- **Algorithmes** : Isolation Forest, LSTM autoencoder

#### 3.3. Traitement des Données

##### 3.3.1. Préparation des Données
- **Scripts** : `train_model.py`, `train_longterm_models.py`, `train_roi_model.py`
- **Fonctionnalités** :
  - Nettoyage des données
  - Feature engineering
  - Normalisation

##### 3.3.2. Génération de Données
- **Scripts** : `generate_roi_training_dataset.py`, `inject_historical_data.py`
- **Fonctionnalités** :
  - Génération de données synthétiques pour entraînement
  - Injection de données historiques

---

## 📊 Flux de Données Principaux

### 1. Création d'Établissement (Workflow EXISTANT)

```
Utilisateur (Frontend)
  ↓
FormA1Page → FormA2Page → FormA3Page → FormA4Page → FormA5Page
  ↓
POST /api/establishments (EstablishmentController)
  ↓
EstablishmentService.createEstablishment()
  ↓
EstablishmentRepository.save() → PostgreSQL
  ↓
ComprehensiveResultsService.calculateAllResults()
  ├─→ SizingService (dimensionnement)
  ├─→ PvCalculationService (production PV)
  ├─→ SimulationService (simulation)
  ├─→ (Optionnel) AIServices → AiMicroserviceClient
  └─→ Retour JSON complet
  ↓
Frontend: ComprehensiveResultsPage (affichage 7 onglets)
```

### 2. Consultation des Résultats

```
Utilisateur clique sur établissement
  ↓
GET /api/establishments/{id}/comprehensive-results
  ↓
ComprehensiveResultsService.calculateAllResults()
  ├─→ Calculs environnementaux (CO₂, arbres, voitures)
  ├─→ Score global (0-100) et sous-scores
  ├─→ Analyse financière (NPV, IRR, ROI)
  ├─→ Métriques résilience (autonomie heures)
  └─→ Comparaison avant/après
  ↓
Retour JSON structuré
  ↓
Frontend: Affichage dans 7 onglets
```

### 3. Prévisions IA

```
Utilisateur demande prévisions (Onglet 7)
  ↓
GET /api/establishments/{id}/forecast?horizonDays=7
  ↓
LongTermPredictionService.getForecast()
  ↓
AiMicroserviceClient → POST /forecast/longterm
  ↓
AI Microservice (FastAPI)
  ├─→ Chargement modèle ML
  ├─→ Prédictions consommation/production
  └─→ Retour JSON
  ↓
Backend → Frontend
  ↓
Affichage graphiques avec bandes d'incertitude
```

### 4. Scénarios What-If

```
Utilisateur modifie paramètres (sliders)
  ↓
POST /api/establishments/{id}/simulate
  Body: { pvPower: X, batteryCapacity: Y, consumption: Z }
  ↓
SimulationService.simulate()
  ↓
AiMicroserviceClient → POST /optimize
  ↓
AI Microservice: Optimisation avec nouveaux paramètres
  ↓
ComprehensiveResultsService.calculateAllResults() (avec nouveaux paramètres)
  ↓
Retour résultats comparatifs
  ↓
Frontend: Affichage comparaison
```

---

## 🗄️ Base de Données

### Entités Principales

#### User (Utilisateur)
- `id` (Long, Primary Key)
- `email` (String, Unique, Not Null)
- `password` (String, Encrypted, Not Null)
- `firstName` (String)
- `lastName` (String)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)

#### Establishment (Établissement)
- `id` (Long, Primary Key)
- `userId` (Long, Foreign Key → User)
- `name` (String, Not Null)
- `type` (Enum, Not Null)
- `numberOfBeds` (Integer)
- `latitude` (Double, Not Null)
- `longitude` (Double, Not Null)
- `installableSurfaceM2` (Double)
- `nonCriticalSurfaceM2` (Double)
- `monthlyConsumptionKwh` (Double, Not Null)
- `existingPvInstalled` (Boolean)
- `solarZone` (Enum: A, B, C, D)
- `createdAt` (Timestamp)
- `updatedAt` (Timestamp)

### Relations
- **User 1 → N Establishment** : Un utilisateur peut posséder plusieurs établissements

---

## 🔐 Sécurité et Authentification

### Flux d'Authentification

```
1. Utilisateur s'inscrit → POST /api/auth/register
   ↓
2. Backend crée User (password hashé)
   ↓
3. Utilisateur se connecte → POST /api/auth/login
   ↓
4. Backend valide credentials
   ↓
5. Génération JWT Token (expiration configurée)
   ↓
6. Frontend stocke token (local storage / secure storage)
   ↓
7. Toutes les requêtes suivantes incluent: 
   Header: Authorization: Bearer <token>
   ↓
8. JwtAuthenticationFilter valide token
   ↓
9. Accès autorisé aux ressources utilisateur
```

### Protection des Endpoints
- **Public** : `/api/auth/register`, `/api/auth/login`, `/api/public/health`
- **Authentifié** : Tous les autres endpoints nécessitent un token JWT valide
- **Isolation** : Chaque utilisateur ne voit que ses propres établissements

---

## 📈 Calculs et Métriques Principales

### 1. Production Photovoltaïque

```java
// Irradiance moyenne selon zone (kWh/m²/jour)
Zone A: 6.0
Zone B: 5.5
Zone C: 5.0
Zone D: 4.5

monthlyProduction = surfaceM2 × irradiance × 30 × 0.20 × 0.80
// 0.20 = efficacité panneau (20%)
// 0.80 = facteur performance (80% pour pertes)
```

### 2. Autonomie Énergétique

```java
autonomy = (monthlyPvProduction / monthlyConsumption) × 100
autonomy = min(autonomy, 100)  // Plafonné à 100%
```

### 3. Analyse Financière

```java
// Coût installation
installationCost = (pvPower × 2500) + (batteryCapacity × 4000) + 
                   (inverterPower × 2000) + 20% installation

// Économies annuelles
annualSavings = (monthlyConsumption × 12) × (autonomy / 100) × electricityPrice

// ROI
roi = installationCost / annualSavings  // années

// NPV (20 ans, taux 6%)
npv = -installationCost + Σ(annualSavings / (1.06^year)) pour year 1 à 20

// IRR
irr = (annualSavings / installationCost) × 100  // %
```

### 4. Impact Environnemental

```java
// CO₂ évité (tonnes/an)
CO2_EMISSION_FACTOR = 0.7  // kg CO2/kWh (mix énergétique Maroc)
co2Avoided = annualPvProduction × 0.7 / 1000

// Équivalent arbres
equivalentTrees = co2Avoided × 1000 / 20  // 20 kg CO2/an par arbre

// Équivalent voitures
equivalentCars = co2Avoided × 1000 / 2000  // 2000 kg CO2/an par voiture
```

### 5. Score Global (0-100)

```java
// Pondération
autonomyScore = (autonomy / 100) × 40      // 40%
economicScore = (normalizedROI) × 30        // 30%
resilienceScore = (reliability / 100) × 20  // 20%
environmentalScore = (normalizedCO2) × 10   // 10%

globalScore = autonomyScore + economicScore + resilienceScore + environmentalScore
```

---

## 🚀 Déploiement et Infrastructure

### Services et Ports

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| Backend Spring Boot | 8080 | http://localhost:8080 | API REST principale |
| AI Microservice | 8000 | http://localhost:8000 | Service IA FastAPI |
| PostgreSQL | 5434 | localhost:5434 | Base de données |
| Flutter Web | Dynamique | http://localhost:XXXXX | Frontend Web |

### Scripts de Démarrage

#### Script Automatique
```powershell
.\start-all-services-mobile.ps1
```
Lance automatiquement :
1. PostgreSQL (Docker)
2. Backend Spring Boot
3. AI Microservice
4. Frontend Flutter Web

#### Démarrage Manuel
1. **PostgreSQL** : `docker-compose up -d` (dans `backend_common/`)
2. **Backend** : `mvn spring-boot:run` (dans `backend_common/`)
3. **AI Microservice** : `python -m uvicorn src.api:app --port 8000` (dans `ai_microservices/`)
4. **Frontend** : `flutter run -d chrome` (dans `frontend_flutter_mobile/hospital-microgrid/`)

---

## 🎯 Domaines Fonctionnels Résumés

### 1. **Gestion Utilisateurs**
- Authentification (inscription, connexion)
- Gestion de profil
- Sécurité (JWT, chiffrement)

### 2. **Gestion Établissements**
- CRUD complet (Create, Read, Update, Delete)
- Deux workflows : EXISTANT (établissements existants) et NEW (nouveaux projets)
- Validation et vérification des données

### 3. **Calculs et Dimensionnement**
- Dimensionnement optimal PV et batteries
- Calculs de production solaire
- Simulation énergétique
- Analyse de résilience

### 4. **Analyses Financières**
- ROI, NPV, IRR
- Économies annuelles et cumulées
- Coûts d'installation
- Projections sur 10 et 20 ans

### 5. **Impact Environnemental**
- CO₂ évité
- Équivalents arbres/voitures
- Production énergétique verte

### 6. **Intelligence Artificielle**
- Prédictions long terme
- Recommandations ML optimisées
- Détection d'anomalies
- Optimisation avancée

### 7. **Visualisation et Reporting**
- 7 onglets de résultats détaillés
- Graphiques interactifs
- Export PDF
- Partage de résultats
- Scénarios What-If

---

## 📝 Points Clés de l'Architecture

### ✅ Avantages

1. **Séparation des responsabilités** : Chaque couche a un rôle clair
2. **Scalabilité** : Architecture modulaire permettant l'ajout de nouvelles fonctionnalités
3. **Maintenabilité** : Code organisé et bien structuré
4. **Flexibilité** : Services optionnels (IA) avec fallback
5. **Sécurité** : Authentification JWT, isolation des données utilisateur
6. **Performance** : Calculs optimisés côté serveur, mise en cache possible

### 🔄 Intégrations

- **Frontend ↔ Backend** : Communication via REST API avec authentification JWT
- **Backend ↔ AI Microservice** : Communication interne via HTTP (sans authentification)
- **Backend ↔ PostgreSQL** : Accès via JPA/Hibernate
- **LocationService ↔ Nominatim** : Géocodage inversé (optionnel)

### 🛡️ Résilience

- **Fallback** : Si le microservice IA n'est pas disponible, le backend utilise des calculs simples
- **Validation** : Validation des données à chaque étape
- **Gestion d'erreurs** : Gestion robuste des erreurs avec messages explicites
- **Logging** : Logs détaillés pour le débogage et le monitoring

---

**Cette organisation fonctionnelle garantit une architecture claire, modulaire et extensible pour la plateforme SMART MICROGRID.**

