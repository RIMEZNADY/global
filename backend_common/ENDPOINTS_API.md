# 📡 API Endpoints - Cas 1 (Établissement Existant)

## Endpoints Créés

### 1. Simulation d'Établissement
**POST** `/api/establishments/{id}/simulate`

**Description** : Simule le comportement énergétique sur une période

**Request Body** :
```json
{
  "startDate": "2024-01-01T00:00:00",
  "days": 7,
  "batteryCapacityKwh": 500.0,
  "initialSocKwh": 250.0
}
```

**Response** :
```json
{
  "steps": [
    {
      "datetime": "2024-01-01T00:00:00",
      "predictedConsumption": 1250.5,
      "pvProduction": 500.0,
      "socBattery": 250.0,
      "gridImport": 450.0,
      "batteryCharge": 0.0,
      "batteryDischarge": 300.5,
      "note": "Battery discharged to support demand."
    }
  ],
  "summary": {
    "totalConsumption": 21000.0,
    "totalPvProduction": 8400.0,
    "totalGridImport": 12600.0,
    "averageAutonomy": 40.0,
    "totalSavings": 10080.0,
    "recommendedPvPower": 1203.7,
    "recommendedBatteryCapacity": 4333.34
  }
}
```

---

### 2. Recommandations de Dimensionnement
**GET** `/api/establishments/{id}/recommendations`

**Description** : Calcule les recommandations PV et batterie

**Response** :
```json
{
  "recommendedPvPowerKwc": 1203.7,
  "recommendedPvSurfaceM2": 6018.5,
  "recommendedBatteryCapacityKwh": 4333.34,
  "estimatedEnergyAutonomy": 60.0,
  "estimatedAnnualSavings": 432000.0,
  "estimatedROI": 12.5,
  "description": "Recommandations basées sur une consommation mensuelle de 50000 kWh"
}
```

---

### 3. Calcul des Économies
**GET** `/api/establishments/{id}/savings?electricityPriceDhPerKwh=1.2`

**Description** : Calcule les économies et indicateurs économiques

**Response** :
```json
{
  "annualConsumption": 600000.0,
  "annualPvEnergy": 360000.0,
  "annualSavings": 432000.0,
  "autonomyPercentage": 60.0,
  "annualBillAfterPv": 288000.0
}
```

---

## Formules Utilisées

Voir le document `FORMULAS_AND_DATA_SOURCES.md` pour les détails complets.


