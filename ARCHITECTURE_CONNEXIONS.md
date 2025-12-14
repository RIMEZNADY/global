# 🏗️ Architecture et Connexions - Frontend, Backend et AI Microservice

## 📊 Vue d'ensemble de l'Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND FLUTTER                              │
│  (Chrome Web / Android / iOS)                                   │
│                                                                  │
│  - ComprehensiveResultsPage                                     │
│  - FormA1Page → FormA5Page                                      │
│  - EstablishmentsListPage                                       │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       │ HTTP/REST API
                       │ (JWT Authentication)
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│              BACKEND SPRING BOOT                                │
│              (Port 8080)                                        │
│                                                                  │
│  - EstablishmentController                                      │
│  - ComprehensiveResultsService                                  │
│  - SimulationService                                            │
│  - AiMicroserviceClient ────────┐                              │
│  - AnomalyDetectionService ─────┤                              │
│  - LongTermPredictionService ───┤                              │
│  - MlRecommendationService ─────┤                              │
└──────────────────────────────────┼──────────────────────────────┘
                                   │
                                   │ HTTP/REST API
                                   │ (No Auth - Internal)
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│              AI MICROSERVICE (FastAPI)                          │
│              (Port 8000)                                        │
│                                                                  │
│  - /predict (Prédiction consommation)                          │
│  - /optimize (Optimisation dispatch)                           │
│  - /predict/pv (Prédiction production PV)                      │
│  - /anomalies (Détection d'anomalies)                          │
│  - /forecast/longterm (Prévisions long terme)                  │
│  - /recommendations/ml (Recommandations ML)                    │
│  - /cluster (Clustering)                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Flux de Données pour ComprehensiveResultsPage

### **1. Vue d'ensemble (Onglet 1)**

**Frontend → Backend :**
```
GET /api/establishments/{id}/comprehensive-results
```

**Backend → Calculs internes :**
- `ComprehensiveResultsService.calculateAllResults()`
  - Calcule impact environnemental
  - Calcule score global
  - Calcule analyse financière
  - Calcule résilience
  - Calcule comparaison avant/après

**Backend → AI Microservice (si nécessaire) :**
- Appels optionnels pour optimisations ML

---

### **2. Financier (Onglet 2)**

**Frontend → Backend :**
```
GET /api/establishments/{id}/comprehensive-results
```
→ Retourne `financial` avec : NPV, IRR, ROI, économies, etc.

**Calculs backend uniquement** (pas d'appel AI pour cet onglet)

---

### **3. Environnemental (Onglet 3)**

**Frontend → Backend :**
```
GET /api/establishments/{id}/comprehensive-results
```
→ Retourne `environmental` avec : CO₂ évité, équivalents arbres/voitures

**Calculs backend uniquement**

---

### **4. Technique (Onglet 4)**

**Frontend → Backend :**
```
GET /api/establishments/{id}/recommendations
```
→ Retourne recommandations de dimensionnement (PV, batterie, surface)

**Calculs backend uniquement** (SizingService)

---

### **5. Comparatif (Onglet 5)**

**Frontend → Backend :**
```
GET /api/establishments/{id}/comprehensive-results
```
→ Retourne `beforeAfter` avec comparaison avant/après

**Scénarios What-If :**
- Frontend → Backend → AI Microservice
```
POST /api/establishments/{id}/simulate
  → Backend appelle AI Microservice /optimize
```

---

### **6. Alertes (Onglet 6)**

**Frontend → Backend :**
```
GET /api/establishments/{id}/recommendations
```
→ Retourne recommandations avec alertes générées côté backend

**Calculs backend uniquement**

---

### **7. Prédictions IA (Onglet 7)**

**Frontend → Backend → AI Microservice :**

#### **a) Prévisions Long Terme :**
```
Frontend: GET /api/establishments/{id}/forecast?horizonDays=7
  ↓
Backend: LongTermPredictionService.getForecast()
  ↓
AI Microservice: POST /forecast/longterm
  {
    "establishment_id": id,
    "horizon_days": 7
  }
```

#### **b) Recommandations ML :**
```
Frontend: GET /api/establishments/{id}/recommendations/ml
  ↓
Backend: MlRecommendationService.getMlRecommendations()
  ↓
AI Microservice: POST /recommendations/ml
  {
    "establishment_id": id
  }
```

#### **c) Détection d'Anomalies :**
```
Frontend: GET /api/establishments/{id}/anomalies?days=7
  ↓
Backend: AnomalyDetectionService.getAnomalies()
  ↓
AI Microservice: POST /anomalies
  {
    "establishment_id": id,
    "days": 7
  }
```

---

## 🔧 Configuration des URLs

### **Frontend (Flutter)**

**Fichier :** `frontend_flutter_mobile/hospital-microgrid/lib/config/api_config.dart`

```dart
static const String backendUrl = 'http://10.0.2.2:8080/api'; // Android Emulator
// Pour Web: http://localhost:8080/api
// Pour iOS: http://localhost:8080/api

static const String aiServiceUrl = 'http://10.0.2.2:5000'; // Non utilisé directement
// Le frontend n'appelle PAS directement le microservice AI
// Tout passe par le backend
```

**Important :** Le frontend n'appelle **JAMAIS** directement le microservice AI. Tous les appels passent par le backend Spring Boot.

---

### **Backend (Spring Boot)**

**Fichier :** `backend_common/src/main/resources/application.properties`

```properties
# Backend Spring Boot
server.port=8080
server.address=0.0.0.0

# AI Microservice URL
ai.microservice.url=http://localhost:8000
```

**Services backend qui appellent le microservice AI :**
- `AiMicroserviceClient` → `/predict`, `/optimize`
- `AnomalyDetectionService` → `/anomalies`
- `LongTermPredictionService` → `/forecast/longterm`
- `MlRecommendationService` → `/recommendations/ml`
- `PvPredictionService` → `/predict/pv`
- `ClusteringService` → `/cluster`

---

### **AI Microservice (FastAPI)**

**Fichier :** `ai_microservices/src/api.py`

**Port :** 8000 (par défaut)

**Endpoints principaux :**
- `POST /predict` - Prédiction consommation
- `POST /optimize` - Optimisation dispatch énergétique
- `POST /predict/pv` - Prédiction production PV
- `POST /anomalies` - Détection d'anomalies
- `POST /forecast/longterm` - Prévisions long terme
- `POST /recommendations/ml` - Recommandations ML
- `POST /cluster` - Clustering
- `GET /health` - Health check

---

## 🚀 Démarrage des Services

### **Option 1 : Script automatique**

```powershell
.\start-all-services-mobile.ps1
```

Ce script lance :
1. ✅ PostgreSQL (Docker, port 5434)
2. ✅ Backend Spring Boot (port 8080)
3. ✅ AI Microservice (port 8000)
4. ✅ Frontend Flutter Web (port 3000)

### **Option 2 : Démarrage manuel**

#### **1. PostgreSQL**
```powershell
cd backend_common
docker-compose up -d
```

#### **2. Backend Spring Boot**
```powershell
cd backend_common
mvn spring-boot:run
```
→ Démarre sur `http://localhost:8080`

#### **3. AI Microservice**
```powershell
cd ai_microservices
python -m uvicorn src.api:app --host 0.0.0.0 --port 8000 --reload
```
→ Démarre sur `http://localhost:8000`

#### **4. Frontend Flutter**
```powershell
cd frontend_flutter_mobile/hospital-microgrid
flutter run -d chrome
```
→ Démarre sur `http://localhost:XXXXX` (port dynamique)

---

## 🔍 Vérification des Connexions

### **1. Vérifier Backend**
```powershell
curl http://localhost:8080/api/public/health
```
**Réponse attendue :**
```json
{
  "status": "UP",
  "service": "microgrid-backend",
  "timestamp": 1234567890
}
```

### **2. Vérifier AI Microservice**
```powershell
curl http://localhost:8000/health
```
**Réponse attendue :**
```json
{
  "status": "healthy",
  "models_loaded": true
}
```

### **3. Vérifier Connexion Backend → AI**
Le backend Spring Boot affichera dans les logs :
- ✅ `AI microservice available` si connecté
- ⚠️ `AI microservice not available, using simple calculation` si non connecté

---

## 📋 Endpoints Backend Utilisés par ComprehensiveResultsPage

### **1. Résultats Complets**
```
GET /api/establishments/{id}/comprehensive-results
```
**Réponse :**
```json
{
  "environmental": {
    "annualPvProduction": 120000.0,
    "co2Avoided": 84.0,
    "equivalentTrees": 4200,
    "equivalentCars": 42
  },
  "globalScore": {
    "score": 75.5,
    "autonomyScore": 30.0,
    "economicScore": 22.5,
    "resilienceScore": 15.0,
    "environmentalScore": 8.0
  },
  "financial": {
    "installationCost": 500000.0,
    "annualSavings": 144000.0,
    "roi": 3.5,
    "npv": 1200000.0,
    "irr": 28.8
  },
  "beforeAfter": {
    "beforeMonthlyBill": 60000.0,
    "afterMonthlyBill": 12000.0,
    "beforeAutonomy": 0.0,
    "afterAutonomy": 80.0
  },
  "resilience": {
    "autonomyHours": 48.0,
    "criticalAutonomyHours": 72.0,
    "reliabilityScore": 85.0
  }
}
```

### **2. Recommandations**
```
GET /api/establishments/{id}/recommendations
```
**Réponse :**
```json
{
  "recommendedPvPower": 100.0,
  "recommendedPvSurface": 500.0,
  "recommendedBatteryCapacity": 2000.0,
  "energyAutonomy": 80.0,
  "roi": 3.5,
  "annualSavings": 144000.0
}
```

### **3. Prévisions IA**
```
GET /api/establishments/{id}/forecast?horizonDays=7
```
**Backend appelle :** `AI Microservice POST /forecast/longterm`

### **4. Recommandations ML**
```
GET /api/establishments/{id}/recommendations/ml
```
**Backend appelle :** `AI Microservice POST /recommendations/ml`

### **5. Anomalies**
```
GET /api/establishments/{id}/anomalies?days=7
```
**Backend appelle :** `AI Microservice POST /anomalies`

---

## ⚠️ Points Importants

### **1. Le Frontend n'appelle JAMAIS directement le microservice AI**

❌ **INCORRECT :**
```dart
// Le frontend ne fait JAMAIS ça
final response = await http.get('http://localhost:8000/predict');
```

✅ **CORRECT :**
```dart
// Le frontend appelle toujours le backend
final response = await ApiService.get('/establishments/$id/forecast');
// Le backend appelle ensuite le microservice AI
```

### **2. Gestion des Erreurs**

Si le microservice AI n'est pas disponible :
- Le backend utilise des **calculs de fallback** (calculs simples)
- Les logs backend affichent : `AI microservice not available, using simple calculation`
- Le frontend continue de fonctionner mais avec des données moins précises

### **3. Authentification**

- **Frontend → Backend :** JWT Token (Bearer Token)
- **Backend → AI Microservice :** Aucune authentification (appels internes)

### **4. Ports**

| Service | Port | URL |
|---------|------|-----|
| Backend Spring Boot | 8080 | http://localhost:8080 |
| AI Microservice | 8000 | http://localhost:8000 |
| PostgreSQL | 5434 | localhost:5434 |
| Flutter Web | Dynamique | http://localhost:XXXXX |

---

## 🧪 Test de l'Architecture Complète

### **Test 1 : Backend seul**
```powershell
# Backend doit fonctionner même sans AI Microservice
curl http://localhost:8080/api/establishments/1/comprehensive-results
```
→ Devrait retourner les résultats (calculs simples si AI non disponible)

### **Test 2 : Backend + AI Microservice**
```powershell
# 1. Démarrer AI Microservice
cd ai_microservices
python -m uvicorn src.api:app --port 8000

# 2. Tester endpoint backend qui utilise AI
curl http://localhost:8080/api/establishments/1/forecast?horizonDays=7
```
→ Devrait retourner des prévisions ML

### **Test 3 : Frontend complet**
```powershell
# 1. Démarrer tous les services
.\start-all-services-mobile.ps1

# 2. Ouvrir Flutter app
# 3. Créer un établissement
# 4. Voir ComprehensiveResultsPage avec tous les onglets
```

---

## 📝 Résumé des Dépendances

### **ComprehensiveResultsPage dépend de :**

1. **Backend Spring Boot** (obligatoire)
   - `/api/establishments/{id}/comprehensive-results`
   - `/api/establishments/{id}/recommendations`
   - `/api/establishments/{id}`

2. **AI Microservice** (optionnel, mais recommandé)
   - Utilisé via backend pour :
     - Prévisions long terme (Onglet 7)
     - Recommandations ML (Onglet 7)
     - Détection d'anomalies (Onglet 7)
     - Optimisations What-If (Onglet 5)

3. **PostgreSQL** (obligatoire)
   - Stockage des établissements
   - Historique des données

---

## ✅ Checklist de Démarrage

Avant d'utiliser ComprehensiveResultsPage, vérifier :

- [ ] PostgreSQL démarré (port 5434)
- [ ] Backend Spring Boot démarré (port 8080)
- [ ] Backend accessible : `http://localhost:8080/api/public/health`
- [ ] AI Microservice démarré (port 8000) - **Optionnel mais recommandé**
- [ ] AI Microservice accessible : `http://localhost:8000/health`
- [ ] Frontend Flutter démarré
- [ ] Configuration des URLs correcte dans `api_config.dart`

---

## 🔧 Dépannage

### **Problème : "Erreur réseau" dans ComprehensiveResultsPage**

**Solutions :**
1. Vérifier que le backend est démarré : `http://localhost:8080/api/public/health`
2. Vérifier l'URL dans `api_config.dart` (pour Web: `localhost`, pour Android: `10.0.2.2`)
3. Vérifier les logs backend pour voir les erreurs

### **Problème : "Données IA non disponibles" dans l'onglet Prédictions IA**

**Solutions :**
1. Vérifier que l'AI Microservice est démarré : `http://localhost:8000/health`
2. Vérifier la configuration dans `application.properties` : `ai.microservice.url=http://localhost:8000`
3. Vérifier les logs backend pour voir les erreurs de connexion

### **Problème : "AI microservice not available" dans les logs backend**

**Solutions :**
1. Démarrer l'AI Microservice : `cd ai_microservices && python -m uvicorn src.api:app --port 8000`
2. Vérifier que le port 8000 n'est pas utilisé par un autre service
3. Le backend continuera de fonctionner avec des calculs simples (fallback)

---

**Cette architecture garantit que le frontend fonctionne même si le microservice AI n'est pas disponible, grâce aux mécanismes de fallback du backend.**
