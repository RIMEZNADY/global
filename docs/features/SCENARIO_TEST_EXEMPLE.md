# 📋 Scénario de Test - Établissement Existant

## 🏥 Données de l'Établissement

### **Formulaire A1 : Informations Générales**

```
Nom de l'établissement: "CHU Ibn Sina - Rabat"
Type d'établissement: CHU (Centre Hospitalier Universitaire)
Nombre de lits: 850
Localisation:
  - Latitude: 34.0131
  - Longitude: -6.8523
  - Ville: Rabat
  - Adresse: "Avenue Allal Ben Abdellah, Rabat"
Classe d'irradiation: C (Moyenne - Zone Rabat)
```

### **Formulaire A2 : Surfaces et Consommation**

```
Surface solaire disponible (installable): 3500 m²
Surface non-critique: 1200 m²
Consommation mensuelle: 85000 kWh/mois
```

### **Formulaire A5 : Choix du Matériel**

```
📦 Panneau Solaire:
   Sélection: "panel3" - Panneau Solaire Bifacial 450W
   - Puissance unitaire: 450W
   - Efficacité: 22.8%
   - Prix unitaire: 1100 DH
   - Nombre nécessaire (calculé): ~310 panneaux pour ~140 kWc

🔋 Batterie:
   Sélection: "battery2" - Batterie Lithium-ion 15kWh
   - Capacité: 15 kWh par batterie
   - Cycles: 6000
   - Prix unitaire: 65000 DH
   - Nombre nécessaire (calculé): ~13 batteries pour ~195 kWh

⚡ Onduleur:
   Sélection: "inv2" - Onduleur Hybride 10kW
   - Puissance: 10 kW
   - Type: Hybride
   - Prix: 22000 DH
   - Nombre nécessaire (calculé): ~14 onduleurs pour ~140 kWc

🎛️ Régulateur:
   Sélection: "ctrl3" - Régulateur MPPT 100A
   - Type: MPPT
   - Intensité: 100A
   - Prix: 6200 DH
   - Nombre nécessaire (calculé): ~4 régulateurs
```

---

## 📊 Résumé des Données pour Test

### **Payload Backend (EstablishmentRequest)**
```json
{
  "name": "CHU Ibn Sina - Rabat",
  "type": "CHU",
  "numberOfBeds": 850,
  "latitude": 34.0131,
  "longitude": -6.8523,
  "irradiationClass": "C",
  "installableSurfaceM2": 3500.0,
  "nonCriticalSurfaceM2": 1200.0,
  "monthlyConsumptionKwh": 85000.0,
  "existingPvInstalled": false
}
```

### **Paramètres Calculés (Estimations)**
```
Consommation journalière moyenne: 85000 / 30 = 2833 kWh/jour
Consommation annuelle: 85000 × 12 = 1,020,000 kWh/an

Puissance PV recommandée (approximative):
  - Surface disponible: 3500 m²
  - Puissance estimée: ~3500 m² × 0.2 kW/m² = 700 kWc
  - Mais avec surface limitée et rendement: ~140-200 kWc

Capacité batterie recommandée:
  - 2 jours d'autonomie: 2833 × 2 × 1.3 = 7366 kWh
  - Recommandé: ~200-250 kWh pour début
```

---

## 🎯 Résultats Attendus de l'IA

### **ROI Prédit (ML)**
```
Attendu: Entre 8 et 15 ans (réaliste pour CHU avec bonne surface)
Confidence: "high" (modèle ML entraîné)
```

### **Prévisions Long Terme (7 jours)**
```
Méthode: "ml_random_forest" (modèle ML)
Consommation quotidienne moyenne: ~2833 kWh/jour (±10%)
Production PV quotidienne moyenne: ~800-1200 kWh/jour (selon saison)
Tendance: "stable" ou légèrement "increasing"
Intervalles de confiance: Disponibles pour chaque jour
```

### **Recommandations ML**
```
Recommandations attendues:
  - Optimisation de la capacité batterie
  - Suggestions d'extension PV si rentable
  - Analyse de la consommation par zone
  - Prévisions d'économies annuelles
```

### **Détection d'Anomalies**
```
Anomalies détectées: 0-5 anomalies sur 7 jours
Types possibles:
  - Pic de consommation inhabituel
  - Production PV inférieure à la normale
  - SOC batterie bas
```

---

## 📝 Instructions de Test

1. **Créer l'établissement** avec les données du Formulaire A1
2. **Remplir A2** avec surfaces et consommation
3. **Sélectionner le matériel** dans A5 :
   - Panneau Bifacial 450W
   - Batterie Lithium-ion 15kWh
   - Onduleur Hybride 10kW
   - Régulateur MPPT 100A
4. **Choisir "IA"** dans ResultChoicePage
5. **Vérifier les résultats** sur la page AI Prediction

---

## ✅ Points à Vérifier

- [ ] ROI affiche une valeur réaliste (8-15 ans)
- [ ] Badge "🤖 ML" apparaît sur ROI si confidence="high"
- [ ] Prévisions long terme montrent badge "ML" (vert)
- [ ] Graphiques de prévisions avec intervalles de confiance
- [ ] Recommandations ML pertinentes
- [ ] Anomalies détectées (si présentes)
- [ ] Tous les calculs sont cohérents

---

## 🔍 Exemple de Réponse API Attendue

### **GET /api/establishments/{id}/recommendations/ml**
```json
{
  "predicted_roi_years": 11.5,
  "confidence": "high",
  "recommendations": [
    {
      "type": "optimization",
      "message": "Optimisation de la capacité batterie recommandée",
      "suggestion": "Augmenter à 250 kWh pour 3 jours d'autonomie"
    }
  ]
}
```

### **GET /api/establishments/{id}/forecast?horizonDays=7**
```json
{
  "predictions": [
    {
      "day": 1,
      "predictedConsumption": 2850.0,
      "predictedPvProduction": 1050.0
    },
    ...
  ],
  "confidenceIntervals": [...],
  "trend": "stable",
  "method": "ml_random_forest"
}
```

---

## 🎬 Prêt pour Test !

Utilise ces données pour créer un établissement complet et vérifier que l'IA retourne des résultats réalistes et pertinents.
















