package com.microgrid.establishment.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

/**
 * DTO pour la prédiction long terme
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LongTermForecastResponse {
    
    private List<ForecastDay> predictions;
    private List<ConfidenceInterval> confidenceIntervals;
    private String trend; // "increasing", "decreasing", "stable"
    private String method; // "simple_average_trend" ou "lstm"
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ForecastDay {
        private int day;
        private double predictedConsumption;
        private double predictedPvProduction;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConfidenceInterval {
        private int day;
        private double consumptionLower;
        private double consumptionUpper;
        private double pvLower;
        private double pvUpper;
    }
}


