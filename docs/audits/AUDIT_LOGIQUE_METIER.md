# 🔍 AUDIT LOGIQUE MÉTIER - Application Microgrid

## 📊 PROBLÈMES DE LOGIQUE IDENTIFIÉS

---

## 🔴 1. INCOHÉRENCE DANS LES CALCULS DE COÛT D'INSTALLATION ⭐⭐⭐⭐⭐

### **Problème** :
Il y a **3 formules différentes** pour calculer le coût d'installation dans le code :

#### **Formule 1** : `ComprehensiveResultsService.estimateInstallationCost()`
```java
double pvCost = pvPower * 2500;        // 2500 DH/kW
double batteryCost = batteryCapacity * 4000;  // 4000 DH/kWh
double inverterCost = pvPower * 2000;  // 2000 DH/kW
double installationCost = (pvCost + batteryCost + inverterCost) * 0.2; // 20% installation
return pvCost + batteryCost + inverterCost + installationCost;
```
**Total** : `(pvPower * 2500) + (batteryCapacity * 4000) + (pvPower * 2000) + 20%`
**=** `pvPower * 5400 + batteryCapacity * 4000` (avec 20% installation)

#### **Formule 2** : `MlRecommendationService.getMlRecommendations()`
```java
double installationCost = (recommendedPvPower * 2500) + (recommendedBattery * 4000) + (recommendedPvPower * 2000) * 1.2;
```
**Total** : `(pvPower * 2500) + (batteryCapacity * 4000) + (pvPower * 2000 * 1.2)`
**=** `pvPower * 4900 + batteryCapacity * 4000`

#### **Formule 3** : `EstablishmentController.getRecommendations()`
```java
double installationCost = recommendedPvPower * 8000.0 + recommendedBattery * 4500.0;
```
**Total** : `pvPower * 8000 + batteryCapacity * 4500`

### **Impact** :
- ❌ **ROI différent** selon l'endpoint appelé
- ❌ **Recommandations incohérentes**
- ❌ **Confusion pour l'utilisateur**

### **Solution** :
**Standardiser sur UNE formule** :
```java
// Coûts unitaires (marché marocain 2024)
private static final double PV_COST_PER_KW = 2500.0;      // Panneaux solaires
private static final double BATTERY_COST_PER_KWH = 4500.0; // Batteries
private static final double INVERTER_COST_PER_KW = 2000.0;  // Onduleur
private static final double INSTALLATION_PERCENTAGE = 0.20;  // 20% installation

public double estimateInstallationCost(double pvPower, double batteryCapacity) {
    double pvCost = pvPower * PV_COST_PER_KW;
    double batteryCost = batteryCapacity * BATTERY_COST_PER_KWH;
    double inverterCost = pvPower * INVERTER_COST_PER_KW;
    double equipmentCost = pvCost + batteryCost + inverterCost;
    double installationCost = equipmentCost * INSTALLATION_PERCENTAGE;
    
    return equipmentCost + installationCost;
}
```

**Priorité** : 🔥 **URGENTE**

---

## 🔴 2. ÉQUIPEMENTS SÉLECTIONNÉS NON UTILISÉS ⭐⭐⭐⭐⭐

### **Problème** :
Dans `FormA5Page`, l'utilisateur sélectionne :
- Panneaux solaires (avec prix)
- Batterie (avec prix)
- Onduleur (avec prix)
- Régulateur (avec prix)

**MAIS** :
- ❌ Ces équipements ne sont **PAS sauvegardés** dans la base de données
- ❌ Le coût d'installation est calculé avec des **prix moyens** au lieu des équipements sélectionnés
- ❌ Les calculs ne reflètent **PAS** le choix réel de l'utilisateur

### **Impact** :
- ❌ Coût d'installation **incorrect**
- ❌ ROI **incorrect**
- ❌ L'utilisateur pense avoir choisi des équipements mais ils ne sont pas pris en compte

### **Solution** :

#### **Option A : Sauvegarder les équipements sélectionnés**
```java
// Nouvelle entité
@Entity
public class SelectedEquipment {
    @ManyToOne
    private Establishment establishment;
    private String panelId;
    private String batteryId;
    private String inverterId;
    private String controllerId;
    private Double totalCost; // Somme des prix réels
}
```

#### **Option B : Utiliser les prix des équipements dans les calculs**
```java
// Dans EstablishmentRequest, ajouter :
private Map<String, Double> selectedEquipmentPrices; // {"panel": 50000, "battery": 45000, ...}

// Dans estimateInstallationCost :
if (establishment.getSelectedEquipmentPrices() != null) {
    // Utiliser les prix réels
    double totalCost = selectedEquipmentPrices.values().stream().mapToDouble(Double::doubleValue).sum();
    return totalCost * 1.2; // + 20% installation
} else {
    // Fallback sur prix moyens
    return estimateInstallationCost(pvPower, batteryCapacity);
}
```

**Priorité** : 🔥 **URGENTE**

---

## 🔴 3. LOGIQUE PV EXISTANT INCOMPLÈTE ⭐⭐⭐⭐

### **Problème** :
Même si on a corrigé `calculateBeforeAfterComparison`, il reste des problèmes :

1. **Validation manquante** :
   - Si `existingPvInstalled = true` mais `existingPvPowerKwc = null` → Erreur silencieuse
   - Si `existingPvInstalled = false` mais `existingPvPowerKwc > 0` → Incohérence

2. **Calculs d'économies** :
   - Les économies affichées sont le "gain réel" (nouveau - actuel)
   - Mais le ROI est calculé sur le coût TOTAL du nouveau microgrid
   - **Incohérence** : ROI devrait être calculé sur le coût NET (nouveau - existant)

### **Exemple** :
```
Situation actuelle : PV 500 kWc (coût déjà amorti)
Nouveau microgrid : PV 1000 kWc (coût 2,500,000 DH)
Gain réel : +500 kWc

ROI actuel : 2,500,000 / économies_annuelles
ROI logique : (2,500,000 - coût_500kWc_existant) / économies_annuelles_gain
```

### **Solution** :
```java
// Dans calculateAllResults :
if (establishment.getExistingPvInstalled() && establishment.getExistingPvPowerKwc() != null) {
    // Coût du PV existant (amorti ou valeur résiduelle)
    double existingPvCost = calculateExistingPvCost(establishment.getExistingPvPowerKwc());
    
    // Coût NET du nouveau microgrid
    double netInstallationCost = installationCost - existingPvCost;
    
    // ROI sur investissement NET
    double netRoi = calculateROI(netInstallationCost, annualSavingsGain);
}
```

**Priorité** : 🔥 **HAUTE**

---

## 🔴 4. VALIDATION MÉTIER MANQUANTE ⭐⭐⭐⭐

### **Problèmes** :

#### **A. Cohérence des surfaces**
```java
// Problème : Pas de validation que installableSurfaceM2 <= totalAvailableSurfaceM2
if (request.getInstallableSurfaceM2() != null && request.getTotalAvailableSurfaceM2() != null) {
    if (request.getInstallableSurfaceM2() > request.getTotalAvailableSurfaceM2()) {
        throw new ValidationException("La surface installable ne peut pas dépasser la surface totale disponible");
    }
}
```

#### **B. Cohérence PV existant**
```java
// Problème : existingPvInstalled = true mais existingPvPowerKwc = null
if (request.getExistingPvInstalled() != null && request.getExistingPvInstalled()) {
    if (request.getExistingPvPowerKwc() == null || request.getExistingPvPowerKwc() <= 0) {
        throw new ValidationException("Si PV existant, la puissance doit être renseignée");
    }
}
```

#### **C. Cohérence workflow EXISTANT vs NEW**
```java
// EXISTANT doit avoir : monthlyConsumptionKwh, installableSurfaceM2
// NEW doit avoir : projectBudgetDh, totalAvailableSurfaceM2, populationServed

boolean isExisting = request.getMonthlyConsumptionKwh() != null;
boolean isNew = request.getProjectBudgetDh() != null;

if (isExisting && request.getMonthlyConsumptionKwh() == null) {
    throw new ValidationException("Workflow EXISTANT : consommation mensuelle requise");
}

if (isNew && request.getProjectBudgetDh() == null) {
    throw new ValidationException("Workflow NEW : budget projet requis");
}
```

**Priorité** : 🔥 **HAUTE**

---

## 🔴 5. CALCUL ROI SIMPLIFIÉ ⭐⭐⭐

### **Problème** :
Le ROI actuel est **trop simplifié** :
```java
ROI = Coût Installation / Économies Annuelles
```

**Manque** :
- ❌ Coûts de maintenance annuels
- ❌ Taux d'actualisation (valeur temporelle de l'argent)
- ❌ Durée de vie des équipements
- ❌ Dégradation des panneaux solaires
- ❌ Remplacement des batteries

### **Solution** :
```java
public double calculateAdvancedROI(
    double installationCost,
    double annualSavings,
    int years,
    double discountRate,
    double annualMaintenanceCost,
    double batteryReplacementCost,
    int batteryLifespanYears
) {
    double npv = 0;
    double cumulativeSavings = 0;
    
    for (int year = 1; year <= years; year++) {
        // Dégradation panneaux : -0.5% par an
        double degradationFactor = 1 - (year * 0.005);
        double yearSavings = annualSavings * degradationFactor;
        
        // Coût maintenance
        double yearCost = annualMaintenanceCost;
        
        // Remplacement batterie
        if (year % batteryLifespanYears == 0) {
            yearCost += batteryReplacementCost;
        }
        
        // Net cash flow
        double netCashFlow = yearSavings - yearCost;
        
        // NPV avec taux d'actualisation
        double discountedCashFlow = netCashFlow / Math.pow(1 + discountRate, year);
        npv += discountedCashFlow;
        cumulativeSavings += netCashFlow;
        
        // ROI atteint ?
        if (cumulativeSavings >= installationCost) {
            return year; // ROI en années
        }
    }
    
    return Double.MAX_VALUE; // ROI non atteint
}
```

**Priorité** : ⚠️ **MOYENNE** (amélioration future)

---

## 🔴 6. CALCUL AUTONOMIE SIMPLIFIÉ ⭐⭐⭐

### **Problème** :
L'autonomie est calculée comme :
```java
autonomy = (monthlyPvProduction / monthlyConsumption) * 100
```

**Problèmes** :
- ❌ Ne tient pas compte de la **batterie** (stockage)
- ❌ Ne tient pas compte de la **variabilité** (jour/nuit, saisons)
- ❌ Autonomie = 100% si production > consommation, mais en réalité il y a des pertes

### **Solution** :
```java
// Autonomie réelle avec batterie
public double calculateRealAutonomy(
    double pvSurfaceM2,
    double monthlyConsumptionKwh,
    double batteryCapacityKwh,
    MoroccanCity.IrradiationClass irradiationClass
) {
    // Production mensuelle
    double monthlyPvProduction = pvCalculationService.calculateMonthlyPvProduction(pvSurfaceM2, irradiationClass);
    
    // Consommation quotidienne moyenne
    double dailyConsumption = monthlyConsumptionKwh / 30.0;
    
    // Production quotidienne moyenne
    double dailyPvProduction = monthlyPvProduction / 30.0;
    
    // Simulation sur 30 jours avec batterie
    double batterySoc = batteryCapacityKwh * 0.5; // 50% initial
    double totalEnergyFromPv = 0;
    double totalConsumption = 0;
    
    for (int day = 0; day < 30; day++) {
        // Production du jour (avec variation)
        double dayProduction = dailyPvProduction * (0.8 + Math.random() * 0.4); // ±20%
        
        // Consommation du jour (avec variation)
        double dayConsumption = dailyConsumption * (0.9 + Math.random() * 0.2); // ±10%
        
        // Utilisation batterie
        double netProduction = dayProduction - dayConsumption;
        
        if (netProduction > 0) {
            // Surplus → charge batterie
            double charge = Math.min(netProduction, batteryCapacityKwh * 0.95 - batterySoc);
            batterySoc += charge;
            totalEnergyFromPv += dayConsumption; // Consommation couverte
        } else {
            // Déficit → décharge batterie
            double deficit = -netProduction;
            double discharge = Math.min(deficit, batterySoc - batteryCapacityKwh * 0.15);
            batterySoc -= discharge;
            totalEnergyFromPv += dayConsumption - (deficit - discharge); // Partie couverte
        }
        
        totalConsumption += dayConsumption;
    }
    
    return (totalEnergyFromPv / totalConsumption) * 100.0;
}
```

**Priorité** : ⚠️ **MOYENNE** (amélioration future)

---

## 🔴 7. WORKFLOW EXISTANT vs NEW - LOGIQUE INCOMPLÈTE ⭐⭐⭐

### **Problème** :
La différenciation entre EXISTANT et NEW n'est pas claire dans le backend :

1. **Détection** : Basée sur `monthlyConsumptionKwh` et `projectBudgetDh`
   ```java
   boolean isNew = monthlyConsumptionKwh == null && projectBudgetDh != null;
   ```
   Mais cette logique est dans le **frontend**, pas dans le backend.

2. **Calculs** : Les mêmes calculs sont utilisés pour EXISTANT et NEW
   - Pour NEW, on devrait utiliser `projectBudgetDh` pour limiter les recommandations
   - Pour EXISTANT, on devrait utiliser `monthlyConsumptionKwh` réelle

### **Solution** :
```java
// Dans EstablishmentService ou SizingService
public RecommendationsResponse getRecommendations(Establishment establishment) {
    boolean isNewEstablishment = establishment.getMonthlyConsumptionKwh() == null 
                                  && establishment.getProjectBudgetDh() != null;
    
    if (isNewEstablishment) {
        // Workflow NEW : Optimiser selon budget
        return optimizeForBudget(establishment);
    } else {
        // Workflow EXISTANT : Optimiser selon consommation réelle
        return optimizeForConsumption(establishment);
    }
}

private RecommendationsResponse optimizeForBudget(Establishment establishment) {
    double budget = establishment.getProjectBudgetDh();
    // Calculer PV et batterie maximum selon budget
    // Ajuster pour respecter le budget
}

private RecommendationsResponse optimizeForConsumption(Establishment establishment) {
    double consumption = establishment.getMonthlyConsumptionKwh();
    // Calculer PV et batterie selon consommation réelle
}
```

**Priorité** : ⚠️ **MOYENNE**

---

## 🔴 8. CALCUL ÉCONOMIES ANNUELLES SIMPLIFIÉ ⭐⭐

### **Problème** :
```java
annualSavings = annualConsumption * (autonomyPercentage / 100) * electricityPrice
```

**Manque** :
- ❌ Tarification progressive (plus on consomme, plus c'est cher)
- ❌ Heures creuses/pleines
- ❌ Coûts de maintenance
- ❌ Taxes et redevances

### **Solution** :
```java
public double calculateRealisticAnnualSavings(
    double monthlyConsumptionKwh,
    double autonomyPercentage,
    double electricityPriceBase
) {
    // Tarification progressive (exemple)
    double annualConsumption = monthlyConsumptionKwh * 12;
    double energyFromPv = annualConsumption * (autonomyPercentage / 100.0);
    
    // Économies avec tarification progressive
    double savings = 0;
    double remainingConsumption = annualConsumption - energyFromPv;
    
    // Tranche 1 : 0-1000 kWh/an à 0.9 DH/kWh
    if (remainingConsumption > 0) {
        double tranche1 = Math.min(remainingConsumption, 1000);
        savings += tranche1 * (electricityPriceBase - 0.9);
        remainingConsumption -= tranche1;
    }
    
    // Tranche 2 : 1000-5000 kWh/an à 1.2 DH/kWh
    if (remainingConsumption > 0) {
        double tranche2 = Math.min(remainingConsumption, 4000);
        savings += tranche2 * (electricityPriceBase - 1.2);
        remainingConsumption -= tranche2;
    }
    
    // Tranche 3 : >5000 kWh/an à 1.5 DH/kWh
    if (remainingConsumption > 0) {
        savings += remainingConsumption * (electricityPriceBase - 1.5);
    }
    
    return savings;
}
```

**Priorité** : ⚠️ **BASSE** (amélioration future)

---

## 📋 PLAN D'ACTION PRIORISÉ

### 🔥 **PHASE 1 - CRITIQUE (Urgent)**

1. ✅ **Standardiser calcul coût d'installation** (1h)
2. ✅ **Sauvegarder/utiliser équipements sélectionnés** (2-3h)
3. ✅ **Corriger logique PV existant (ROI net)** (1h)
4. ✅ **Ajouter validations métier** (2h)

### ⚠️ **PHASE 2 - IMPORTANT**

5. Améliorer calcul ROI (avec maintenance, NPV) (3-4h)
6. Améliorer calcul autonomie (avec batterie) (2-3h)
7. Différencier workflow EXISTANT vs NEW (2h)

### 📝 **PHASE 3 - AMÉLIORATION**

8. Calcul économies réaliste (tarification progressive) (2h)

---

## 🎯 RÉSUMÉ

**Problèmes critiques** : 4
**Problèmes importants** : 3
**Améliorations** : 1

**Temps estimé Phase 1** : 6-7 heures
**Impact** : 🔥 **TRÈS ÉLEVÉ** - Corrige les incohérences majeures



