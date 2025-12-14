package com.microgrid.establishment.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO pour les graphiques d'anomalies
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AnomalyGraphResponse {
    
    private List<AnomalyDataPoint> anomalies;
    private AnomalyStatistics statistics;
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AnomalyDataPoint {
        private LocalDateTime datetime;
        private boolean isAnomaly;
        private String anomalyType;
        private double anomalyScore;
        private String recommendation;
        private double consumption;
        private double predictedConsumption;
        private double pvProduction;
        private double expectedPv;
        private double soc;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AnomalyStatistics {
        private int totalAnomalies;
        private int highConsumptionAnomalies;
        private int lowConsumptionAnomalies;
        private int pvMalfunctionAnomalies;
        private int batteryLowAnomalies;
        private double averageAnomalyScore;
        private String mostCommonAnomalyType;
    }
}


