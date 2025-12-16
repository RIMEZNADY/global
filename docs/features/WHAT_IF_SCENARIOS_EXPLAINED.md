# 🎮 Scénarios "What-If" : Principe et Fonctionnement

## 🎯 **QU'EST-CE QU'UN SCÉNARIO "WHAT-IF" ?**

**Principe :** "Et si..." - Simuler différents scénarios pour voir l'impact avant de décider.

### **Exemple Simple de la Vie Quotidienne :**
- ❓ "Et si j'achète une voiture électrique au lieu d'essence ?"
- ❓ "Et si j'augmente mon budget de 20% ?"
- ❓ "Et si j'ajoute une chambre à ma maison ?"

**Dans le contexte Microgrid :**
- ❓ "Et si j'ajoute 500 kW de panneaux solaires ?"
- ❓ "Et si je double la capacité de ma batterie ?"
- ❓ "Et si ma consommation augmente de 30% ?"

---

## 📊 **FONCTIONNEMENT DANS VOTRE APPLICATION**

### **1. Concept**

L'utilisateur ajuste des paramètres et voit instantanément l'impact sur :
- 💰 Coûts (ROI, économies, investissement)
- 🌍 Impact environnemental (CO2 évité)
- ⚡ Performance énergétique (autonomie, résilience)
- 📈 Graphiques (consommation, production, import réseau)

---

### **2. Exemple Concret**

#### **Scénario Actuel :**
```
Configuration actuelle :
- PV : 1000 kW
- Batterie : 500 kWh
- Consommation : 50,000 kWh/mois
- ROI : 8.5 ans
- Autonomie : 75%
- Économies : 60,000 DH/an
```

#### **Scénario "What-If" : "Et si j'ajoute 500 kW PV ?"**

**L'utilisateur fait :**
1. Glisse le slider "Puissance PV" : 1000 kW → 1500 kW
2. **Instantannément**, le système recalcule et affiche :

```
Nouveau scénario :
- PV : 1500 kW (+50%)
- Batterie : 500 kWh (inchangée)
- Consommation : 50,000 kWh/mois (inchangée)

RÉSULTATS :
✅ Autonomie : 75% → 90% (+15%)
✅ Économies : 60,000 → 85,000 DH/an (+25,000 DH)
✅ ROI : 8.5 ans → 7.2 ans (-1.3 ans)
✅ CO2 évité : 120 → 170 tonnes/an
✅ Investissement : +2,500,000 DH

COMPARAISON VISUELLE :
[Graphique côte à côte : Avant / Après]
```

---

### **3. Fonctionnalités Clés**

#### **A. Paramètres Ajustables (Sliders)**

L'utilisateur peut modifier :
- ⚡ **Puissance PV** (kW) : "Et si j'ajoute/réduis les panneaux ?"
- 🔋 **Capacité Batterie** (kWh) : "Et si j'augmente la batterie ?"
- 📊 **Consommation** (kWh/mois) : "Et si ma consommation change ?"
- 💧 **Classe d'Irradiation** : "Et si je déplace l'installation ?"
- 💰 **Prix Électricité** (DH/kWh) : "Et si les tarifs changent ?"

---

#### **B. Comparaison Instantanée**

**Affichage côte à côte :**
```
┌─────────────────────┬─────────────────────┐
│   CONFIG ACTUELLE   │   SCÉNARIO WHAT-IF  │
├─────────────────────┼─────────────────────┤
│ PV: 1000 kW         │ PV: 1500 kW         │
│ Batterie: 500 kWh   │ Batterie: 500 kWh   │
│                     │                     │
│ Autonomie: 75%      │ Autonomie: 90%  ⬆️  │
│ ROI: 8.5 ans        │ ROI: 7.2 ans    ⬆️  │
│ Économies: 60k DH   │ Économies: 85k DH⬆️ │
└─────────────────────┴─────────────────────┘
```

---

#### **C. Graphiques Interactifs**

**Mise à jour en temps réel :**
- 📊 Graphique consommation vs production
- 📈 Graphique SOC batterie
- 💰 Graphique coûts annuels
- 🌍 Graphique CO2 évité

**Quand l'utilisateur bouge le slider → Graphiques se mettent à jour instantanément**

---

#### **D. Indicateurs Visuels**

**Flèches et couleurs :**
- ⬆️ Vert : Amélioration (ex: ROI diminue, autonomie augmente)
- ⬇️ Rouge : Dégradation (ex: ROI augmente, autonomie diminue)
- ➡️ Gris : Pas de changement significatif

---

### **4. Avantages pour l'Utilisateur**

#### **A. Aide à la Décision**
- ✅ Voir l'impact avant d'investir
- ✅ Comparer différentes options
- ✅ Optimiser le budget

#### **B. Compréhension**
- ✅ Comprendre les relations entre paramètres
- ✅ Voir comment chaque changement affecte le système
- ✅ Apprendre les effets de chaque décision

#### **C. Flexibilité**
- ✅ Tester plusieurs scénarios rapidement
- ✅ Pas besoin de refaire des formulaires
- ✅ Résultats instantanés

---

## 🔧 **TECHNIQUE : COMMENT ÇA FONCTIONNE**

### **1. Backend (Déjà Disponible)**

**Le service de simulation existe déjà :**
```java
POST /api/establishments/{id}/simulate

Body :
{
  "startDate": "2024-01-01T00:00:00",
  "days": 7,
  "batteryCapacityKwh": 500.0,  // ← Peut être modifié
  "initialSocKwh": 250.0
}
```

**Pour un scénario "What-If", on pourrait ajouter :**
```java
POST /api/establishments/{id}/simulate/scenario

Body :
{
  "pvPowerKw": 1500.0,           // ← Nouveau paramètre
  "batteryCapacityKwh": 750.0,   // ← Modifié
  "monthlyConsumptionKwh": 60000.0, // ← Modifié
  "days": 30
}
```

---

### **2. Frontend (À Implémenter)**

#### **A. Interface avec Sliders**

```dart
class WhatIfScenarioPage extends StatefulWidget {
  // Sliders interactifs
  - Slider pour PV Power
  - Slider pour Battery Capacity
  - Slider pour Consumption
  - Dropdown pour Irradiation Class
  
  // Graphiques qui se mettent à jour
  - LineChart (Consommation vs Production)
  - BarChart (Coûts comparatifs)
  
  // Métriques comparatives
  - Carte "Configuration Actuelle"
  - Carte "Scénario What-If"
  - Indicateurs de différence
}
```

#### **B. Logique**

```dart
// Quand l'utilisateur bouge un slider
void _onSliderChanged(double newValue) {
  setState(() {
    // Mettre à jour le paramètre
    _scenarioPvPower = newValue;
    
    // Recalculer instantanément
    _simulateScenario();
  });
}

Future<void> _simulateScenario() async {
  // Appeler le backend avec nouveaux paramètres
  final result = await AiService.simulateScenario(
    establishmentId: widget.establishmentId,
    pvPower: _scenarioPvPower,
    batteryCapacity: _scenarioBatteryCapacity,
    // ...
  );
  
  // Mettre à jour les graphiques
  setState(() {
    _scenarioResults = result;
  });
}
```

---

### **3. Exemples de Scénarios Typiques**

#### **Scénario 1 : "Optimisation Coût"**
```
Objectif : Réduire l'investissement initial
Action : Réduire PV de 1000 kW → 800 kW
Résultat : 
- Investissement : -1,000,000 DH
- ROI : 8.5 ans → 9.2 ans (+0.7 ans)
- Autonomie : 75% → 65% (-10%)
```

#### **Scénario 2 : "Résilience Maximale"**
```
Objectif : Maximiser l'autonomie
Action : Doubler batterie 500 kWh → 1000 kWh
Résultat :
- Autonomie : 75% → 92% (+17%)
- Résilience : 48h → 96h
- Investissement : +2,000,000 DH
- ROI : 8.5 ans → 9.8 ans (+1.3 ans)
```

#### **Scénario 3 : "Croissance"**
```
Objectif : Préparer pour consommation future
Action : Consommation 50k → 70k kWh/mois
Résultat :
- Autonomie actuelle : 75% → 54% (-21%)
- Besoin PV supplémentaire : +600 kW recommandé
- Impact financier : +3,000,000 DH
```

---

## ✅ **RÉSUMÉ**

### **Principe :**
**"Simuler différents scénarios pour voir l'impact avant de décider"**

### **Fonctionnement :**
1. ✅ L'utilisateur ajuste des paramètres (sliders)
2. ✅ Le système recalcule instantanément
3. ✅ Affichage comparatif (Avant / Après)
4. ✅ Graphiques mis à jour en temps réel
5. ✅ Indicateurs visuels (amélioration/dégradation)

### **Avantages :**
- 🎯 Aide à la décision
- 📊 Compréhension des impacts
- ⚡ Résultats instantanés
- 🔄 Flexibilité (tester plusieurs scénarios)

### **Ce qui existe déjà :**
- ✅ Service de simulation backend (`SimulationService`)
- ✅ Endpoint `/simulate` (peut être utilisé pour What-If)
- ✅ Calculs financiers et environnementaux

### **Ce qui manque (à implémenter) :**
- ❌ Interface avec sliders interactifs
- ❌ Comparaison visuelle Avant/Après
- ❌ Mise à jour en temps réel des graphiques
- ❌ Endpoint dédié pour scénarios What-If (optionnel)

---

**Voulez-vous que j'implémente cette fonctionnalité "What-If" avec des sliders interactifs ?**









