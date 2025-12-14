package com.microgrid.service;

import com.microgrid.model.Establishment;
import com.microgrid.model.MoroccanCity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service pour simuler la consommation, production PV et SOC batterie sur une période
 */
@Service
public class SimulationService {

    @Autowired
    private AiMicroserviceClient aiMicroserviceClient;

    @Autowired
    private PvCalculationService pvCalculationService;

    @Autowired
    private ConsumptionEstimationService consumptionEstimationService;

    @Autowired
    private MeteoDataService meteoDataService;

    @Autowired
    private CsvMeteoReaderService csvMeteoReaderService;

    @Autowired
    private AiResultValidator aiResultValidator;

    @Autowired
    private PvPredictionService pvPredictionService;

    @Autowired
    private AnomalyDetectionService anomalyDetectionService;

    /**
     * Résultat d'une simulation pour un pas de temps
     */
    public static class SimulationStep {
        public LocalDateTime datetime;
        public double predictedConsumption;
        public double pvProduction;
        public double socBattery;
        public double gridImport;
        public double batteryCharge;
        public double batteryDischarge;
        public String note;
        public Boolean hasAnomaly;
        public String anomalyType;
        public Double anomalyScore;
        public String anomalyRecommendation;
    }

    /**
     * Résultat complet d'une simulation
     */
    public static class SimulationResult {
        public List<SimulationStep> steps = new ArrayList<>();
        public double totalConsumption;
        public double totalPvProduction;
        public double totalGridImport;
        public double averageAutonomy;
        public double totalSavings;
    }

    /**
     * Simule le comportement énergétique sur une période
     * 
     * @param establishment Établissement
     * @param startDate Date de début
     * @param days Nombre de jours à simuler
     * @param batteryCapacityKwh Capacité batterie en kWh
     * @param initialSocKwh État de charge initial en kWh
     * @return Résultat de simulation
     */
    public SimulationResult simulate(
            Establishment establishment,
            LocalDateTime startDate,
            int days,
            double batteryCapacityKwh,
            double initialSocKwh) {
        
        SimulationResult result = new SimulationResult();
        double currentSoc = initialSocKwh;
        
        // Paramètres batterie
        Map<String, Double> batteryParams = new HashMap<>();
        batteryParams.put("BATTERY_CAP_KWH", batteryCapacityKwh);
        batteryParams.put("SOC_MIN", 0.15);
        batteryParams.put("SOC_MAX", 0.95);
        batteryParams.put("CHARGE_MAX_KW", 200.0);
        batteryParams.put("DISCHARGE_MAX_KW", 200.0);

        // Convertir IrradiationClass
        MoroccanCity.IrradiationClass irradiationClass = convertIrradiationClass(establishment.getIrradiationClass());
        
        // Estimation consommation quotidienne si non fournie
        double dailyConsumption = establishment.getMonthlyConsumptionKwh() != null 
            ? establishment.getMonthlyConsumptionKwh() / 30.0
            : consumptionEstimationService.estimateDailyConsumption(
                establishment.getType(), establishment.getNumberOfBeds());

        // Production PV quotidienne moyenne
        double dailyPvProduction = 0.0;
        if (establishment.getInstallableSurfaceM2() != null && establishment.getInstallableSurfaceM2() > 0) {
            dailyPvProduction = pvCalculationService.calculateDailyPvProduction(
                establishment.getInstallableSurfaceM2(), irradiationClass);
        }

        // Simuler chaque pas de 6 heures
        LocalDateTime currentDate = startDate;
        int totalSteps = days * 4; // 4 pas de 6h par jour
        
        for (int step = 0; step < totalSteps; step++) {
            SimulationStep simStep = new SimulationStep();
            simStep.datetime = currentDate;
            
            // Lire les données météo réelles depuis CSV
            double temperature;
            double irradiance;
            
            CsvMeteoReaderService.MeteoData meteoData = csvMeteoReaderService.getMeteoData(currentDate, irradiationClass);
            
            if (meteoData != null) {
                // Utiliser les données réelles du CSV
                temperature = meteoData.temperature;
                irradiance = meteoData.irradiance;
            } else {
                // Fallback sur estimation si CSV non disponible
                temperature = 20.0 + 5.0 * Math.sin(step * Math.PI / 12); // Variation jour/nuit
                irradiance = meteoDataService.getAverageIrradiance(irradiationClass) / 4.0; // Moyenne par pas
                if (currentDate.getHour() < 6 || currentDate.getHour() >= 18) {
                    irradiance = 0.0; // Nuit
                }
                System.out.println("Données météo CSV non disponibles pour " + currentDate + ", utilisation de l'estimation");
            }
            
            // Production PV pour ce pas - Utiliser ML si disponible, sinon formule
            double pvProduction = 0.0;
            if (establishment.getInstallableSurfaceM2() != null && establishment.getInstallableSurfaceM2() > 0) {
                try {
                    // Essayer prédiction ML
                    // Récupérer historique PV des pas précédents
                    java.util.List<Double> historicalPvList = result.steps.stream()
                        .map(s -> s.pvProduction)
                        .collect(java.util.stream.Collectors.toList());
                    
                    pvProduction = pvPredictionService.predictPvProduction(
                        currentDate,
                        irradiance,
                        temperature,
                        establishment.getInstallableSurfaceM2(),
                        historicalPvList.isEmpty() ? null : historicalPvList
                    );
                } catch (Exception e) {
                    // Fallback sur formule simple si ML non disponible
                    System.err.println("PV ML prediction failed, using formula: " + e.getMessage());
                    pvProduction = pvCalculationService.calculatePvProductionFromIrradiance(
                        establishment.getInstallableSurfaceM2(), irradiance);
                }
            }
            simStep.pvProduction = pvProduction;
            
            // Estimation patients
            double patients = consumptionEstimationService.estimatePatients(establishment.getNumberOfBeds());
            
            // Prédire consommation
            double predictedConsumption = dailyConsumption / 4.0; // Répartir sur 4 pas (fallback)
            try {
                double aiPrediction = aiMicroserviceClient.predictConsumption(
                    currentDate, temperature, irradiance, pvProduction, patients, currentSoc, null);
                
                // Valider la prédiction IA
                if (aiResultValidator.isValidConsumption(aiPrediction, dailyConsumption)) {
                    predictedConsumption = aiPrediction;
                } else {
                    // Corriger si invalide
                    predictedConsumption = aiResultValidator.correctConsumption(aiPrediction, dailyConsumption);
                    System.out.println("Prédiction IA corrigée: " + aiPrediction + " -> " + predictedConsumption);
                }
            } catch (Exception e) {
                // Fallback sur estimation si API non disponible
                System.err.println("AI microservice not available, using estimation: " + e.getMessage());
            }
            simStep.predictedConsumption = predictedConsumption;
            
            // Optimiser dispatch
            Map<String, Object> optimization = new HashMap<>();
            try {
                optimization = aiMicroserviceClient.optimizeDispatch(
                    predictedConsumption, pvProduction, currentSoc, batteryParams);
                
                // Extraire les valeurs
                double gridImport = getDoubleValue(optimization, "grid_import_kWh", 0.0);
                double batteryCharge = getDoubleValue(optimization, "battery_charge_kWh", 0.0);
                double batteryDischarge = getDoubleValue(optimization, "battery_discharge_kWh", 0.0);
                double socNext = getDoubleValue(optimization, "soc_next", currentSoc);
                
                // Valider les résultats d'optimisation
                if (!aiResultValidator.isValidOptimization(
                        gridImport, batteryCharge, batteryDischarge, socNext, batteryCapacityKwh)) {
                    // Utiliser le calcul simple si l'optimisation IA est invalide
                    System.out.println("Résultat d'optimisation IA invalide, utilisation du calcul simple");
                    optimization = calculateSimpleDispatch(predictedConsumption, pvProduction, currentSoc, batteryCapacityKwh);
                } else {
                    // Corriger le SOC si nécessaire
                    socNext = aiResultValidator.correctSoc(socNext, batteryCapacityKwh);
                    optimization.put("soc_next", socNext);
                }
            } catch (Exception e) {
                // Fallback sur calcul simple si API non disponible
                System.err.println("AI microservice not available, using simple calculation: " + e.getMessage());
                optimization = calculateSimpleDispatch(predictedConsumption, pvProduction, currentSoc, batteryCapacityKwh);
            }
            
            simStep.gridImport = getDoubleValue(optimization, "grid_import_kWh", 0.0);
            simStep.batteryCharge = getDoubleValue(optimization, "battery_charge_kWh", 0.0);
            simStep.batteryDischarge = getDoubleValue(optimization, "battery_discharge_kWh", 0.0);
            simStep.socBattery = getDoubleValue(optimization, "soc_next", currentSoc);
            simStep.note = (String) optimization.getOrDefault("note", "");
            
            // Détection d'anomalies
            try {
                double expectedPv = pvCalculationService.calculatePvProductionFromIrradiance(
                    establishment.getInstallableSurfaceM2() != null ? establishment.getInstallableSurfaceM2() : 0.0,
                    irradiance
                );
                
                AnomalyDetectionService.AnomalyResult anomalyResult = anomalyDetectionService.detectAnomaly(
                    predictedConsumption,
                    predictedConsumption, // Utiliser la même valeur pour l'instant
                    pvProduction,
                    expectedPv,
                    currentSoc,
                    temperature,
                    irradiance
                );
                
                simStep.hasAnomaly = anomalyResult.isAnomaly;
                simStep.anomalyType = anomalyResult.anomalyType;
                simStep.anomalyScore = anomalyResult.anomalyScore;
                simStep.anomalyRecommendation = anomalyResult.recommendation;
                
                if (anomalyResult.isAnomaly) {
                    simStep.note = (simStep.note.isEmpty() ? "" : simStep.note + " | ") +
                        "Anomaly detected: " + anomalyResult.anomalyType + " - " + anomalyResult.recommendation;
                    System.out.println("Anomaly detected at " + currentDate + ": " + anomalyResult.anomalyType);
                }
            } catch (Exception e) {
                // Ignorer erreurs de détection d'anomalies pour ne pas bloquer la simulation
                System.err.println("Anomaly detection failed: " + e.getMessage());
            }
            
            currentSoc = simStep.socBattery;
            
            result.steps.add(simStep);
            result.totalConsumption += predictedConsumption;
            result.totalPvProduction += pvProduction;
            result.totalGridImport += simStep.gridImport;
            
            // Passer au pas suivant (6 heures)
            currentDate = currentDate.plusHours(6);
        }
        
        // Calculer statistiques finales
        result.averageAutonomy = calculateAverageAutonomy(result);
        result.totalSavings = calculateTotalSavings(result, 1.2); // 1.2 DH/kWh
        
        return result;
    }

    private double getDoubleValue(Map<String, Object> map, String key, double defaultValue) {
        Object value = map.get(key);
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        return defaultValue;
    }

    private Map<String, Object> calculateSimpleDispatch(
            double consumption, double pvProduction, double soc, double batteryCapacity) {
        Map<String, Object> result = new HashMap<>();
        
        double demand = Math.max(consumption, 0.0);
        double pvAvailable = Math.max(pvProduction, 0.0);
        
        double pvUsed = Math.min(demand, pvAvailable);
        double remainingDemand = demand - pvUsed;
        double surplusPv = pvAvailable - pvUsed;
        
        double batteryCharge = 0.0;
        double batteryDischarge = 0.0;
        double socNext = soc;
        
        if (surplusPv > 0) {
            double availableCapacity = Math.max(0.95 * batteryCapacity - socNext, 0.0);
            batteryCharge = Math.min(surplusPv, availableCapacity);
            socNext += batteryCharge;
        } else {
            double availableDischarge = Math.max(socNext - 0.15 * batteryCapacity, 0.0);
            batteryDischarge = Math.min(remainingDemand, availableDischarge);
            socNext -= batteryDischarge;
            remainingDemand -= batteryDischarge;
        }
        
        result.put("grid_import_kWh", Math.max(remainingDemand, 0.0));
        result.put("battery_charge_kWh", batteryCharge);
        result.put("battery_discharge_kWh", batteryDischarge);
        result.put("soc_next", Math.max(0.15 * batteryCapacity, Math.min(socNext, batteryCapacity)));
        result.put("note", "Simple dispatch calculation");
        
        return result;
    }

    private double calculateAverageAutonomy(SimulationResult result) {
        if (result.totalConsumption == 0) {
            return 0.0;
        }
        return (result.totalPvProduction / result.totalConsumption) * 100.0;
    }

    private double calculateTotalSavings(SimulationResult result, double electricityPriceDhPerKwh) {
        double energyFromPv = result.totalPvProduction;
        return energyFromPv * electricityPriceDhPerKwh;
    }

    private MoroccanCity.IrradiationClass convertIrradiationClass(Establishment.IrradiationClass class_) {
        if (class_ == null) {
            return MoroccanCity.IrradiationClass.C;
        }
        return switch (class_) {
            case A -> MoroccanCity.IrradiationClass.A;
            case B -> MoroccanCity.IrradiationClass.B;
            case C -> MoroccanCity.IrradiationClass.C;
            case D -> MoroccanCity.IrradiationClass.D;
        };
    }
}

