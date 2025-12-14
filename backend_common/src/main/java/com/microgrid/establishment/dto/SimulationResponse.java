package com.microgrid.establishment.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SimulationResponse {
    
    private List<SimulationStep> steps;
    private SimulationSummary summary;
    
    @Data
    @NoArgsConstructor
    public static class SimulationStep {
        private LocalDateTime datetime;
        private double predictedConsumption;
        private double pvProduction;
        private double socBattery;
        private double gridImport;
        private double batteryCharge;
        private double batteryDischarge;
        private String note;
        private Boolean hasAnomaly; // Nouveau champ pour anomalies
        private String anomalyType; // Type d'anomalie
        private Double anomalyScore; // Score d'anomalie
        private String anomalyRecommendation; // Recommandation
        
        // Constructeur avec tous les champs
        public SimulationStep(LocalDateTime datetime, double predictedConsumption, double pvProduction,
                             double socBattery, double gridImport, double batteryCharge, double batteryDischarge,
                             String note, Boolean hasAnomaly, String anomalyType, Double anomalyScore,
                             String anomalyRecommendation) {
            this.datetime = datetime;
            this.predictedConsumption = predictedConsumption;
            this.pvProduction = pvProduction;
            this.socBattery = socBattery;
            this.gridImport = gridImport;
            this.batteryCharge = batteryCharge;
            this.batteryDischarge = batteryDischarge;
            this.note = note;
            this.hasAnomaly = hasAnomaly;
            this.anomalyType = anomalyType;
            this.anomalyScore = anomalyScore;
            this.anomalyRecommendation = anomalyRecommendation;
        }
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SimulationSummary {
        private double totalConsumption;
        private double totalPvProduction;
        private double totalGridImport;
        private double averageAutonomy;
        private double totalSavings;
        private double recommendedPvPower;
        private double recommendedBatteryCapacity;
    }
}

