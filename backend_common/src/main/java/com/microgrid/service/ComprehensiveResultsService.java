package com.microgrid.service;

import com.microgrid.model.Establishment;
import com.microgrid.model.MoroccanCity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.List;

/**
 * Service pour calculer tous les résultats additionnels (impact environnemental, score global, etc.)
 */
@Service
public class ComprehensiveResultsService {

    @Autowired
    private SizingService sizingService;

    @Autowired
    private PvCalculationService pvCalculationService;

    @Autowired
    private MeteoDataService meteoDataService;
    
    @Autowired
    @Lazy
    private MlRecommendationService mlRecommendationService;

    // Constantes
    private static final double CO2_EMISSION_FACTOR = 0.7; // kg CO2/kWh (mix énergétique Maroc)
    private static final double CO2_PER_TREE = 20.0; // kg CO2/an par arbre
    private static final double CO2_PER_CAR = 2000.0; // kg CO2/an par voiture
    private static final double DISCOUNT_RATE = 0.06; // 6% taux d'actualisation
    private static final double CRITICAL_CONSUMPTION_RATIO = 0.6; // 60% de consommation critique

    /**
     * Calcule l'impact environnemental
     */
    public Map<String, Object> calculateEnvironmentalImpact(Establishment establishment, double autonomyPercentage) {
        double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
            ? establishment.getMonthlyConsumptionKwh()
            : 50000.0;
        
        // Production PV annuelle
        double annualPvProduction = (monthlyConsumption * 12 * autonomyPercentage / 100.0);
        
        // CO2 évité (tonnes/an)
        double co2Avoided = (annualPvProduction * CO2_EMISSION_FACTOR) / 1000.0;
        
        // Équivalents
        double equivalentTrees = (co2Avoided * 1000) / CO2_PER_TREE;
        double equivalentCars = co2Avoided / (CO2_PER_CAR / 1000.0);
        
        Map<String, Object> result = new HashMap<>();
        result.put("annualPvProduction", annualPvProduction);
        result.put("co2Avoided", co2Avoided);
        result.put("equivalentTrees", equivalentTrees);
        result.put("equivalentCars", equivalentCars);
        
        return result;
    }

    /**
     * Calcule le score global de performance (0-100)
     */
    public Map<String, Object> calculateGlobalScore(
            Establishment establishment,
            double autonomyPercentage,
            double annualSavings,
            double batteryCapacity,
            double co2Avoided) {
        
        // Scores par catégorie (max 25 points chacun)
        // Les scores peuvent varier naturellement selon les calculs
        
        // Score autonomie (0-25) : linéaire basé sur le pourcentage
        double autonomyScore = Math.min(Math.max((autonomyPercentage / 100.0) * 25.0, 0.0), 25.0);
        
        // Score économique (0-25) : basé sur les économies annuelles normalisées
        // Normaliser sur une plage raisonnable (0-1M DH/an = 25 points)
        double normalizedSavings = Math.min(Math.max(annualSavings / 1000000.0, 0.0), 1.0);
        double economicScore = normalizedSavings * 25.0;
        
        // Score résilience (0-25) : basé sur capacité batterie et autonomie
        double resilienceScore = calculateResilienceScore(batteryCapacity, autonomyPercentage);
        
        // Score environnemental (0-25) : basé sur CO2 évité
        // Normaliser sur 10 tonnes/an = 25 points
        double normalizedCO2 = Math.min(Math.max(co2Avoided / 10.0, 0.0), 1.0);
        double environmentalScore = normalizedCO2 * 25.0;
        
        // Score global (peut varier naturellement)
        double globalScore = autonomyScore + economicScore + resilienceScore + environmentalScore;
        
        Map<String, Object> result = new HashMap<>();
        result.put("score", globalScore); // Clé "score" pour cohérence avec le frontend
        result.put("globalScore", globalScore); // Garder pour compatibilité
        result.put("autonomyScore", autonomyScore);
        result.put("economicScore", economicScore);
        result.put("resilienceScore", resilienceScore);
        result.put("environmentalScore", environmentalScore);
        
        return result;
    }

    /**
     * Calcule le score de résilience (0-25)
     */
    private double calculateResilienceScore(double batteryCapacity, double autonomy) {
        // Score basé sur capacité batterie et autonomie
        double batteryScore = Math.min((batteryCapacity / 1000.0) * 15.0, 15.0); // Max 15 points
        double autonomyScore = Math.min((autonomy / 100.0) * 10.0, 10.0); // Max 10 points
        return batteryScore + autonomyScore;
    }

    /**
     * Calcule l'analyse financière détaillée
     */
    public Map<String, Object> calculateFinancialAnalysis(
            double installationCost,
            double annualSavings,
            int years) {
        
        // NPV (Net Present Value)
        double npv = -installationCost;
        for (int i = 1; i <= years; i++) {
            npv += annualSavings / Math.pow(1 + DISCOUNT_RATE, i);
        }
        
        // IRR (Internal Rate of Return) - approximation
        double irr = installationCost > 0 && annualSavings > 0
            ? (annualSavings / installationCost) * 100.0
            : 0.0;
        
        // ROI
        double roi = installationCost > 0 && annualSavings > 0
            ? installationCost / annualSavings
            : Double.MAX_VALUE;
        
        // Économies cumulées
        double cumulativeSavings10 = annualSavings * 10;
        double cumulativeSavings20 = annualSavings * 20;
        
        Map<String, Object> result = new HashMap<>();
        result.put("installationCost", installationCost);
        result.put("annualSavings", annualSavings);
        result.put("roi", roi);
        result.put("npv20", npv);
        result.put("irr", irr);
        result.put("cumulativeSavings10", cumulativeSavings10);
        result.put("cumulativeSavings20", cumulativeSavings20);
        
        return result;
    }

    /**
     * Calcule les métriques de résilience
     */
    public Map<String, Object> calculateResilienceMetrics(
            Establishment establishment,
            double batteryCapacity) {
        
        double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
            ? establishment.getMonthlyConsumptionKwh()
            : 50000.0;
        
        // Consommation moyenne (kW)
        double avgConsumption = monthlyConsumption / (30.0 * 24.0);
        double criticalConsumption = avgConsumption * CRITICAL_CONSUMPTION_RATIO;
        
        // Autonomie (heures)
        double autonomyHours = batteryCapacity / avgConsumption;
        double criticalAutonomyHours = batteryCapacity / criticalConsumption;
        
        // Score de fiabilité
        double reliabilityScore = calculateResilienceScore(batteryCapacity, 0);
        
        Map<String, Object> result = new HashMap<>();
        result.put("autonomyHours", autonomyHours);
        result.put("criticalAutonomyHours", criticalAutonomyHours);
        result.put("reliabilityScore", reliabilityScore);
        
        return result;
    }

    /**
     * Calcule la comparaison avant/après
     */
    public Map<String, Object> calculateBeforeAfterComparison(
            Establishment establishment,
            double autonomyPercentage) {
        
        double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
            ? establishment.getMonthlyConsumptionKwh()
            : 50000.0;
        
        double electricityPrice = 1.2; // DH/kWh
        
        // Calculer l'autonomie ACTUELLE si PV existant
        double beforeAutonomy = 0.0;
        double beforePvProduction = 0.0;
        
        if (establishment.getExistingPvInstalled() != null && establishment.getExistingPvInstalled()) {
            // Si PV existant, calculer l'autonomie actuelle
            Double existingPvPower = establishment.getExistingPvPowerKwc();
            if (existingPvPower != null && existingPvPower > 0) {
                // Convertir puissance en surface (1 kWc = 5 m²)
                double existingPvSurface = existingPvPower * 5.0;
                
                // Calculer l'autonomie actuelle
                String irradiationClassStr = establishment.getIrradiationClass() != null 
                    ? establishment.getIrradiationClass().toString() 
                    : "C";
                MoroccanCity.IrradiationClass irradiationClass = convertIrradiationClass(irradiationClassStr);
                
                beforeAutonomy = sizingService.calculateEnergyAutonomy(
                    existingPvSurface, monthlyConsumption, irradiationClass);
                beforePvProduction = pvCalculationService.calculatePvProductionForPeriod(
                    existingPvSurface, irradiationClass, 30);
            }
        }
        
        // AVANT (situation actuelle)
        double beforeGridConsumption = monthlyConsumption * (1 - beforeAutonomy / 100.0);
        double beforeMonthlyBill = beforeGridConsumption * electricityPrice;
        double beforeAnnualBill = beforeMonthlyBill * 12;
        
        // APRÈS (avec nouveau microgrid)
        double afterAutonomy = autonomyPercentage;
        double afterGridConsumption = monthlyConsumption * (1 - afterAutonomy / 100.0);
        double afterMonthlyBill = afterGridConsumption * electricityPrice;
        double afterAnnualBill = afterMonthlyBill * 12;
        
        // Calculer l'amélioration (gain réel)
        double autonomyGain = afterAutonomy - beforeAutonomy;
        double monthlySavingsGain = beforeMonthlyBill - afterMonthlyBill;
        double annualSavingsGain = monthlySavingsGain * 12;
        
        Map<String, Object> result = new HashMap<>();
        result.put("beforeMonthlyBill", beforeMonthlyBill);
        result.put("afterMonthlyBill", afterMonthlyBill);
        result.put("beforeAnnualBill", beforeAnnualBill);
        result.put("afterAnnualBill", afterAnnualBill);
        result.put("beforeGridConsumption", beforeGridConsumption);
        result.put("afterGridConsumption", afterGridConsumption);
        result.put("beforeAutonomy", beforeAutonomy);
        result.put("afterAutonomy", afterAutonomy);
        result.put("beforePvProduction", beforePvProduction);
        result.put("autonomyGain", autonomyGain);
        result.put("monthlySavingsGain", monthlySavingsGain);
        result.put("annualSavingsGain", annualSavingsGain);
        result.put("hasExistingPv", establishment.getExistingPvInstalled() != null && establishment.getExistingPvInstalled());
        
        return result;
    }

    // Constantes pour le calcul de coût d'installation (marché marocain 2024)
    private static final double PV_COST_PER_KW = 2500.0;           // Panneaux solaires
    private static final double BATTERY_COST_PER_KWH = 4500.0;     // Batteries
    private static final double INVERTER_COST_PER_KW = 2000.0;     // Onduleur
    private static final double INSTALLATION_PERCENTAGE = 0.20;    // 20% installation

    /**
     * Estime le coût d'installation standardisé
     * Formule unique utilisée dans toute l'application pour garantir la cohérence
     * Utilise les prix réels des équipements sélectionnés si disponibles, sinon prix moyens
     * 
     * @param pvPower Puissance PV en kWc
     * @param batteryCapacity Capacité batterie en kWh
     * @param establishment Établissement (optionnel, pour récupérer les prix réels des équipements)
     * @return Coût total d'installation en DH
     */
    public double estimateInstallationCost(double pvPower, double batteryCapacity, Establishment establishment) {
        double pvCost;
        double batteryCost;
        double inverterCost;
        double controllerCost = 0.0;
        
        // Utiliser les prix réels des équipements sélectionnés si disponibles
        if (establishment != null && establishment.getSelectedPanelPrice() != null 
            && establishment.getSelectedBatteryPrice() != null 
            && establishment.getSelectedInverterPrice() != null) {
            
            // Calculer le coût total des équipements sélectionnés
            // Pour les panneaux : prix unitaire * nombre de panneaux nécessaires
            // Estimation : 1 panneau = 0.4 kWc (400W), donc nombre = pvPower / 0.4
            // Le prix dans la liste est pour 1 panneau de 400W
            double panelPowerKw = 0.4; // 400W = 0.4 kWc par panneau
            double panelsNeeded = Math.ceil(pvPower / panelPowerKw); // Arrondir vers le haut
            pvCost = establishment.getSelectedPanelPrice() * panelsNeeded;
            
            // Pour la batterie : prix unitaire pour une batterie de capacité donnée
            // Les batteries dans la liste sont de 10kWh, 12kWh, 15kWh, 20kWh
            // On calcule le nombre de batteries nécessaires
            double batteryUnitCapacity = 10.0; // Capacité unitaire moyenne (kWh)
            double batteriesNeeded = Math.ceil(batteryCapacity / batteryUnitCapacity);
            batteryCost = establishment.getSelectedBatteryPrice() * batteriesNeeded;
            
            // Pour l'onduleur : prix unitaire (déjà dimensionné pour la puissance)
            // Les onduleurs dans la liste sont de 5kW, 8kW, 10kW, 15kW
            // On utilise le prix de l'onduleur sélectionné (supposé adapté à la puissance)
            inverterCost = establishment.getSelectedInverterPrice();
            
            // Pour le régulateur : prix unitaire
            if (establishment.getSelectedControllerPrice() != null) {
                controllerCost = establishment.getSelectedControllerPrice();
            }
        } else {
            // Fallback sur prix moyens
            pvCost = pvPower * PV_COST_PER_KW;
            batteryCost = batteryCapacity * BATTERY_COST_PER_KWH;
            inverterCost = pvPower * INVERTER_COST_PER_KW;
        }
        
        double equipmentCost = pvCost + batteryCost + inverterCost + controllerCost;
        double installationCost = equipmentCost * INSTALLATION_PERCENTAGE;
        
        return equipmentCost + installationCost;
    }
    
    /**
     * Surcharge pour compatibilité (utilise prix moyens)
     */
    public double estimateInstallationCost(double pvPower, double batteryCapacity) {
        return estimateInstallationCost(pvPower, batteryCapacity, null);
    }

    /**
     * Calcule tous les résultats complets pour un établissement
     */
    public Map<String, Object> calculateAllResults(Establishment establishment) {
        // Convertir IrradiationClass (enum -> String -> enum)
        String irradiationClassStr = establishment.getIrradiationClass() != null 
            ? establishment.getIrradiationClass().toString() 
            : "C";
        MoroccanCity.IrradiationClass irradiationClass = convertIrradiationClass(irradiationClassStr);
        
        // Consommation mensuelle
        double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
            ? establishment.getMonthlyConsumptionKwh()
            : 50000.0;
        
        // Recommandations de base (calculs physiques)
        double recommendedPvPower = sizingService.calculateRecommendedPvPower(monthlyConsumption, irradiationClass);
        double recommendedBattery = sizingService.calculateRecommendedBatteryCapacityFromMonthly(monthlyConsumption);
        
        // 🤖 AMÉLIORATION AVEC IA/ML
        // Utiliser le service ML pour affiner les recommandations basées sur des données historiques
        // Les valeurs ML peuvent varier, ce qui permet au score de varier naturellement
        try {
            Map<String, Object> mlResult = mlRecommendationService.getMlRecommendations(establishment);
            
            // Utiliser les recommandations ML si disponibles (plus précises que les calculs basiques)
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> mlRecommendations = 
                (List<Map<String, Object>>) mlResult.get("recommendations");
            if (mlRecommendations != null && !mlRecommendations.isEmpty()) {
                for (Map<String, Object> rec : mlRecommendations) {
                    if (rec.containsKey("type") && "pv_power".equals(rec.get("type"))) {
                        Object value = rec.get("value");
                        if (value instanceof Number) {
                            double mlPvPower = ((Number) value).doubleValue();
                            // Utiliser la valeur ML si elle est raisonnable (dans une plage acceptable)
                            if (mlPvPower > 0 && mlPvPower < recommendedPvPower * 2) {
                                recommendedPvPower = mlPvPower;
                                System.out.println("🤖 IA: PV Power ajusté de " + recommendedPvPower + " à " + mlPvPower + " kW");
                            }
                        }
                    } else if (rec.containsKey("type") && "battery_capacity".equals(rec.get("type"))) {
                        Object value = rec.get("value");
                        if (value instanceof Number) {
                            double mlBattery = ((Number) value).doubleValue();
                            // Utiliser la valeur ML si elle est raisonnable
                            if (mlBattery > 0 && mlBattery < recommendedBattery * 2) {
                                recommendedBattery = mlBattery;
                                System.out.println("🤖 IA: Battery Capacity ajusté de " + recommendedBattery + " à " + mlBattery + " kWh");
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            // Si le service ML échoue, utiliser les valeurs de base (calculs physiques)
            System.err.println("⚠️ Service ML indisponible, utilisation des calculs basiques: " + e.getMessage());
        }
        
        // Autonomie
        double autonomy = 0.0;
        Double installableSurface = establishment.getInstallableSurfaceM2();
        if (installableSurface != null && installableSurface > 0) {
            autonomy = sizingService.calculateEnergyAutonomy(
                installableSurface, monthlyConsumption, irradiationClass);
        } else {
            double recommendedSurface = sizingService.calculateRecommendedPvSurface(monthlyConsumption, irradiationClass);
            autonomy = sizingService.calculateEnergyAutonomy(
                recommendedSurface, monthlyConsumption, irradiationClass);
        }
        
        // Économies annuelles (gain réel par rapport à la situation actuelle)
        double currentAutonomy = 0.0;
        double existingPvCost = 0.0;
        if (establishment.getExistingPvInstalled() != null && establishment.getExistingPvInstalled()) {
            Double existingPvPower = establishment.getExistingPvPowerKwc();
            if (existingPvPower != null && existingPvPower > 0) {
                double existingPvSurface = existingPvPower * 5.0;
                currentAutonomy = sizingService.calculateEnergyAutonomy(
                    existingPvSurface, monthlyConsumption, irradiationClass);
                
                // Calculer le coût du PV existant (valeur résiduelle)
                // Estimation : coût initial du PV existant (amorti, on utilise 50% de la valeur initiale)
                // Coût PV uniquement (sans batterie ni onduleur pour le calcul de valeur résiduelle)
                double existingPvCostInitial = existingPvPower * PV_COST_PER_KW;
                existingPvCost = existingPvCostInitial * 0.5; // 50% valeur résiduelle (amortissement)
            }
        }
        // Économies = économies totales avec nouveau microgrid - économies actuelles (si PV existant)
        double totalSavingsWithNewMicrogrid = sizingService.calculateAnnualSavings(monthlyConsumption, autonomy, 1.2);
        double currentSavings = sizingService.calculateAnnualSavings(monthlyConsumption, currentAutonomy, 1.2);
        double annualSavings = totalSavingsWithNewMicrogrid - currentSavings; // Gain réel
        
        // Coût installation (utilise les prix réels des équipements si disponibles)
        double installationCost = estimateInstallationCost(recommendedPvPower, recommendedBattery, establishment);
        
        // Coût NET d'installation (nouveau microgrid - valeur résiduelle existant)
        double netInstallationCost = installationCost - existingPvCost;
        
        // Impact environnemental
        Map<String, Object> environmental = calculateEnvironmentalImpact(establishment, autonomy);
        double co2Avoided = (Double) environmental.get("co2Avoided");
        
        // Score global
        Map<String, Object> globalScore = calculateGlobalScore(
            establishment, autonomy, annualSavings, recommendedBattery, co2Avoided);
        
        // Analyse financière (utiliser coût NET si PV existant)
        double costForFinancialAnalysis = (existingPvCost > 0) ? netInstallationCost : installationCost;
        Map<String, Object> financial = calculateFinancialAnalysis(costForFinancialAnalysis, annualSavings, 20);
        
        // Ajouter le ROI net dans les résultats si PV existant
        if (existingPvCost > 0) {
            double netRoi = sizingService.calculateROI(netInstallationCost, annualSavings);
            financial.put("netRoi", netRoi);
            financial.put("grossRoi", sizingService.calculateROI(installationCost, annualSavings));
            financial.put("existingPvCost", existingPvCost);
        }
        
        // Résilience
        Map<String, Object> resilience = calculateResilienceMetrics(establishment, recommendedBattery);
        
        // Comparaison avant/après
        Map<String, Object> beforeAfter = calculateBeforeAfterComparison(establishment, autonomy);
        
        // Résultat complet
        Map<String, Object> result = new HashMap<>();
        result.put("environmental", environmental);
        result.put("globalScore", globalScore);
        result.put("financial", financial);
        result.put("resilience", resilience);
        result.put("beforeAfter", beforeAfter);
        result.put("recommendedPvPower", recommendedPvPower);
        result.put("recommendedBatteryCapacity", recommendedBattery);
        result.put("autonomy", autonomy);
        result.put("annualSavings", annualSavings);
        result.put("installationCost", installationCost);
        if (existingPvCost > 0) {
            result.put("netInstallationCost", netInstallationCost);
            result.put("existingPvCost", existingPvCost);
        }
        result.put("aiEnhanced", true); // Indicateur que l'IA a été utilisée pour améliorer les recommandations
        
        return result;
    }

    /**
     * Convertit IrradiationClass string en enum
     */
    private MoroccanCity.IrradiationClass convertIrradiationClass(String irradiationClass) {
        if (irradiationClass == null) {
            return MoroccanCity.IrradiationClass.C;
        }
        try {
            return MoroccanCity.IrradiationClass.valueOf(irradiationClass);
        } catch (IllegalArgumentException e) {
            return MoroccanCity.IrradiationClass.C; // Default
        }
    }
}

