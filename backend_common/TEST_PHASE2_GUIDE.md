# 🧪 Guide de Test - Phase 2

## 📋 Prérequis

### 1. Démarrer les Services

**Backend Spring Boot** :
```bash
cd backend
mvn spring-boot:run
```
Ou dans un terminal séparé.

**AI Microservice (Python)** :
```bash
cd ai_microservices
python -m uvicorn src.api:app --reload
```
Ou dans un terminal séparé.

### 2. Vérifier les Services

```powershell
.\check-services.ps1
```

---

## 🧪 Tests à Effectuer

### Test 1 : Clustering d'Établissements

**Endpoint AI** : `POST http://localhost:8000/cluster/establishments`

**Requête** :
```json
{
  "establishment_type": "CHU",
  "number_of_beds": 200,
  "monthly_consumption": 50000.0,
  "installable_surface": 1000.0,
  "irradiation_class": "C",
  "latitude": 33.5731,
  "longitude": -7.5898
}
```

**Réponse attendue** :
```json
{
  "cluster_id": 2,
  "distance_to_center": 0.45,
  "cluster_characteristics": {...}
}
```

**Vérification** :
- ✅ `cluster_id` entre 0 et 4
- ✅ `distance_to_center` >= 0

---

### Test 2 : Recommandations Intelligentes ML

**Endpoint Backend** : `GET http://localhost:8080/api/establishments/{id}/recommendations/ml`

**Headers** :
```
Authorization: Bearer {token}
```

**Réponse attendue** :
```json
{
  "cluster_id": 2,
  "predicted_roi_years": 8.5,
  "recommendations": [
    {
      "type": "success",
      "message": "ROI excellent (< 5 ans)",
      "suggestion": "Investissement très recommandé"
    }
  ],
  "confidence": "high"
}
```

**Vérification** :
- ✅ `predicted_roi_years` > 0
- ✅ `recommendations` non vide
- ✅ `confidence` = "high" ou "low"

---

### Test 3 : Prédiction Long Terme

**Endpoint Backend** : `GET http://localhost:8080/api/establishments/{id}/forecast?horizonDays=7`

**Headers** :
```
Authorization: Bearer {token}
```

**Réponse attendue** :
```json
{
  "predictions": [
    {
      "day": 1,
      "predictedConsumption": 500.0,
      "predictedPvProduction": 200.0
    },
    ...
  ],
  "confidenceIntervals": [...],
  "trend": "stable",
  "method": "simple_average_trend"
}
```

**Vérification** :
- ✅ `predictions` contient 7 éléments (si horizonDays=7)
- ✅ `trend` = "increasing", "decreasing", ou "stable"
- ✅ `confidenceIntervals` non vide

---

### Test 4 : Graphique Anomalies

**Endpoint Backend** : `GET http://localhost:8080/api/establishments/{id}/anomalies?days=7`

**Headers** :
```
Authorization: Bearer {token}
```

**Réponse attendue** :
```json
{
  "anomalies": [
    {
      "datetime": "2024-01-01T12:00:00",
      "isAnomaly": true,
      "anomalyType": "high_consumption",
      "anomalyScore": -0.15,
      "recommendation": "Check for equipment malfunction",
      "consumption": 600.0,
      "predictedConsumption": 500.0,
      "pvProduction": 200.0,
      "expectedPv": 300.0,
      "soc": 250.0
    },
    ...
  ],
  "statistics": {
    "totalAnomalies": 5,
    "highConsumptionAnomalies": 2,
    "lowConsumptionAnomalies": 1,
    "pvMalfunctionAnomalies": 1,
    "batteryLowAnomalies": 1,
    "averageAnomalyScore": -0.12,
    "mostCommonAnomalyType": "high_consumption"
  }
}
```

**Vérification** :
- ✅ `anomalies` contient des points de données
- ✅ `statistics` présente
- ✅ Types d'anomalies corrects

---

### Test 5 : Simulation avec Anomalies

**Endpoint Backend** : `POST http://localhost:8080/api/establishments/{id}/simulate`

**Headers** :
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Requête** :
```json
{
  "startDate": "2024-01-01T00:00:00",
  "days": 3,
  "batteryCapacityKwh": 500.0,
  "initialSocKwh": 250.0
}
```

**Réponse attendue** :
```json
{
  "steps": [
    {
      "datetime": "2024-01-01T00:00:00",
      "predictedConsumption": 416.67,
      "pvProduction": 90.0,
      "socBattery": 250.0,
      "gridImport": 326.67,
      "batteryCharge": 0.0,
      "batteryDischarge": 0.0,
      "note": "...",
      "hasAnomaly": false,
      "anomalyType": null,
      "anomalyScore": null,
      "anomalyRecommendation": null
    },
    ...
  ],
  "summary": {...}
}
```

**Vérification** :
- ✅ `steps` contient des données
- ✅ Champs `hasAnomaly`, `anomalyType`, etc. présents
- ✅ Anomalies détectées si présentes

---

## 🚀 Exécuter Tous les Tests

```powershell
.\test-phase2-endpoints.ps1
```

---

## ✅ Résultats Attendus

Tous les endpoints doivent retourner :
- ✅ Status 200 OK
- ✅ Données JSON valides
- ✅ Champs requis présents
- ✅ Pas d'erreurs serveur

---

## 🔍 Dépannage

### Backend non disponible
```bash
cd backend_common
mvn spring-boot:run
```

### AI Microservice non disponible
```bash
cd ai_microservices
python -m uvicorn src.api:app --reload
```

### Erreur 401 Unauthorized
- Vérifier que le token JWT est valide
- Se reconnecter si nécessaire

### Erreur 500 Internal Server Error
- Vérifier les logs du backend
- Vérifier que le microservice AI est démarré
- Vérifier que les modèles ML sont entraînés (première utilisation)

---

**Prêt pour les tests !** 🧪


