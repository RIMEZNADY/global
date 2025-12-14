package com.microgrid.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service pour la prédiction long terme (7-30 jours)
 */
@Service
public class LongTermPredictionService {

    @Value("${ai.microservice.url:http://localhost:8000}")
    private String aiMicroserviceUrl;

    private final RestTemplate restTemplate;
    private final ConsumptionEstimationService consumptionEstimationService;

    public LongTermPredictionService(ConsumptionEstimationService consumptionEstimationService) {
        this.restTemplate = new RestTemplate();
        this.consumptionEstimationService = consumptionEstimationService;
    }

    /**
     * Résultat de prédiction long terme
     */
    public static class LongTermPredictionResult {
        public final List<Map<String, Object>> predictions;
        public final List<Map<String, Object>> confidenceIntervals;
        public final String trend;
        public final String method;

        public LongTermPredictionResult(
                List<Map<String, Object>> predictions,
                List<Map<String, Object>> confidenceIntervals,
                String trend,
                String method) {
            this.predictions = predictions;
            this.confidenceIntervals = confidenceIntervals;
            this.trend = trend;
            this.method = method;
        }
        
        // Constructeur pour compatibilité (fallback)
        public LongTermPredictionResult(
                List<Map<String, Object>> predictions,
                List<Map<String, Object>> confidenceIntervals,
                String trend) {
            this(predictions, confidenceIntervals, trend, "simple_average_trend");
        }
    }

    /**
     * Prédit consommation et production PV sur plusieurs jours
     */
    public LongTermPredictionResult predictLongTerm(
            List<Map<String, Object>> historicalData,
            int horizonDays) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("historical_data", historicalData);
            requestBody.put("horizon_days", horizonDays);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/predict/longterm";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> predictions = (List<Map<String, Object>>) body.getOrDefault("predictions", List.of());
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> confidenceIntervals = (List<Map<String, Object>>) body.getOrDefault("confidence_intervals", List.of());
                String trend = (String) body.getOrDefault("trend", "stable");
                String method = (String) body.getOrDefault("method", "simple_average_trend");
                
                return new LongTermPredictionResult(predictions, confidenceIntervals, trend, method);
            }
            
            throw new RuntimeException("Failed to get long-term prediction from AI microservice");
        } catch (Exception e) {
            System.err.println("Error calling AI microservice /predict/longterm: " + e.getMessage());
            return new LongTermPredictionResult(List.of(), List.of(), "error", "simple_average_trend");
        }
    }

    /**
     * Obtient les prévisions long terme pour un établissement (wrapper)
     */
    public com.microgrid.establishment.dto.LongTermForecastResponse getForecast(
            com.microgrid.model.Establishment establishment,
            java.time.LocalDateTime startDate,
            int horizonDays) {
        
        // Générer des données historiques synthétiques réalistes basées sur le type d'établissement
        List<Map<String, Object>> historicalData = generateSyntheticHistoricalData(
            establishment, 7); // 7 jours minimum pour ML
        
        LongTermPredictionResult result = predictLongTerm(historicalData, horizonDays);
        
        // Convertir en DTO
        List<com.microgrid.establishment.dto.LongTermForecastResponse.ForecastDay> forecastDays = new java.util.ArrayList<>();
        for (int i = 0; i < result.predictions.size(); i++) {
            Map<String, Object> pred = result.predictions.get(i);
            forecastDays.add(new com.microgrid.establishment.dto.LongTermForecastResponse.ForecastDay(
                i + 1,
                ((Number) pred.getOrDefault("predicted_consumption", 500.0)).doubleValue(),
                ((Number) pred.getOrDefault("predicted_pv_production", 200.0)).doubleValue()
            ));
        }
        
        List<com.microgrid.establishment.dto.LongTermForecastResponse.ConfidenceInterval> intervals = new java.util.ArrayList<>();
        for (int i = 0; i < result.confidenceIntervals.size(); i++) {
            Map<String, Object> ci = result.confidenceIntervals.get(i);
            intervals.add(new com.microgrid.establishment.dto.LongTermForecastResponse.ConfidenceInterval(
                i + 1,
                ((Number) ci.getOrDefault("consumption_lower", 400.0)).doubleValue(),
                ((Number) ci.getOrDefault("consumption_upper", 600.0)).doubleValue(),
                ((Number) ci.getOrDefault("pv_lower", 150.0)).doubleValue(),
                ((Number) ci.getOrDefault("pv_upper", 250.0)).doubleValue()
            ));
        }
        
        return new com.microgrid.establishment.dto.LongTermForecastResponse(
            forecastDays,
            intervals,
            result.trend,
            result.method != null ? result.method : "simple_average_trend"
        );
    }

    /**
     * Prédit consommation et production PV pour une saison spécifique
     */
    public LongTermPredictionResult predictSeasonal(
            List<Map<String, Object>> historicalData,
            String season,
            int year) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("historical_data", historicalData);
            requestBody.put("season", season);
            requestBody.put("year", year);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/predict/seasonal";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> predictions = (List<Map<String, Object>>) body.getOrDefault("predictions", List.of());
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> confidenceIntervals = (List<Map<String, Object>>) body.getOrDefault("confidence_intervals", List.of());
                String trend = (String) body.getOrDefault("trend", "stable");
                String method = (String) body.getOrDefault("method", "seasonal_adjusted");
                
                return new LongTermPredictionResult(predictions, confidenceIntervals, trend, method);
            }
            
            throw new RuntimeException("Failed to get seasonal prediction from AI microservice");
        } catch (Exception e) {
            System.err.println("Error calling AI microservice /predict/seasonal: " + e.getMessage());
            return new LongTermPredictionResult(List.of(), List.of(), "error", "seasonal_adjusted");
        }
    }

    /**
     * Obtient les prévisions saisonnières pour un établissement
     */
    public com.microgrid.establishment.dto.LongTermForecastResponse getSeasonalForecast(
            com.microgrid.model.Establishment establishment,
            String season,
            int year) {
        
        // Générer des données historiques synthétiques réalistes basées sur le type d'établissement
        List<Map<String, Object>> historicalData = generateSyntheticHistoricalData(
            establishment, 30); // 30 jours pour prédictions saisonnières
        
        LongTermPredictionResult result = predictSeasonal(historicalData, season, year);
        
        // Convertir en DTO (même logique que getForecast)
        List<com.microgrid.establishment.dto.LongTermForecastResponse.ForecastDay> forecastDays = new java.util.ArrayList<>();
        for (int i = 0; i < result.predictions.size(); i++) {
            Map<String, Object> pred = result.predictions.get(i);
            forecastDays.add(new com.microgrid.establishment.dto.LongTermForecastResponse.ForecastDay(
                i + 1,
                ((Number) pred.getOrDefault("predicted_consumption", 500.0)).doubleValue(),
                ((Number) pred.getOrDefault("predicted_pv_production", 200.0)).doubleValue()
            ));
        }
        
        List<com.microgrid.establishment.dto.LongTermForecastResponse.ConfidenceInterval> intervals = new java.util.ArrayList<>();
        for (int i = 0; i < result.confidenceIntervals.size(); i++) {
            Map<String, Object> ci = result.confidenceIntervals.get(i);
            intervals.add(new com.microgrid.establishment.dto.LongTermForecastResponse.ConfidenceInterval(
                i + 1,
                ((Number) ci.getOrDefault("consumption_lower", 400.0)).doubleValue(),
                ((Number) ci.getOrDefault("consumption_upper", 600.0)).doubleValue(),
                ((Number) ci.getOrDefault("pv_lower", 150.0)).doubleValue(),
                ((Number) ci.getOrDefault("pv_upper", 250.0)).doubleValue()
            ));
        }
        
        return new com.microgrid.establishment.dto.LongTermForecastResponse(
            forecastDays,
            intervals,
            result.trend,
            result.method != null ? result.method : "seasonal_adjusted"
        );
    }

    /**
     * Génère des données historiques synthétiques réalistes basées sur le type d'établissement
     * Utilise les ratios de consommation par type pour créer des données cohérentes
     */
    private List<Map<String, Object>> generateSyntheticHistoricalData(
            com.microgrid.model.Establishment establishment,
            int numDays) {
        
        List<Map<String, Object>> historicalData = new java.util.ArrayList<>();
        
        // Estimer la consommation quotidienne basée sur le type et nombre de lits
        double baseDailyConsumption = establishment.getMonthlyConsumptionKwh() != null
            ? establishment.getMonthlyConsumptionKwh() / 30.0
            : consumptionEstimationService.estimateDailyConsumption(
                establishment.getType(), establishment.getNumberOfBeds());
        
        // Estimer la production PV basée sur la surface installable
        double baseDailyPvProduction = 0.0;
        if (establishment.getInstallableSurfaceM2() != null && establishment.getInstallableSurfaceM2() > 0) {
            // Irradiance moyenne selon la classe (kWh/m²/jour)
            double irradiance = switch (establishment.getIrradiationClass()) {
                case A -> 7.0;
                case B -> 6.0;
                case C -> 5.0;
                case D -> 4.0;
                default -> 5.0;
            };
            double panelEfficiency = 0.20;
            double performanceFactor = 0.80;
            baseDailyPvProduction = establishment.getInstallableSurfaceM2() 
                * irradiance * panelEfficiency * performanceFactor;
        } else {
            // Estimation par défaut : 50% de la consommation
            baseDailyPvProduction = baseDailyConsumption * 0.5;
        }
        
        java.time.LocalDateTime baseDate = java.time.LocalDateTime.now().minusDays(numDays);
        
        for (int i = 0; i < numDays; i++) {
            java.time.LocalDateTime currentDate = baseDate.plusDays(i);
            int dayOfWeek = currentDate.getDayOfWeek().getValue(); // 1=Lundi, 7=Dimanche
            boolean isWeekend = dayOfWeek >= 6;
            
            // Variations réalistes
            double weekendFactor = isWeekend ? 0.85 : 1.0; // Weekend -15%
            double dailyVariation = 0.9 + (Math.random() * 0.2); // ±10% variation aléatoire
            double seasonalFactor = 1.0 + 0.1 * Math.sin(2 * Math.PI * currentDate.getDayOfYear() / 365.0);
            
            // Consommation avec variations
            double consumption = baseDailyConsumption * weekendFactor * seasonalFactor * dailyVariation;
            
            // Production PV avec variations (plus élevée en été, affectée par météo)
            double summerFactor = 1.0 + 0.3 * Math.sin(2 * Math.PI * currentDate.getDayOfYear() / 365.0 + Math.PI/2);
            double weatherFactor = 0.7 + (Math.random() * 0.3); // Nuages, etc.
            double pvProduction = baseDailyPvProduction * summerFactor * weatherFactor * dailyVariation;
            
            // Température et irradiation
            double temperature = 20.0 + 10.0 * Math.sin(2 * Math.PI * currentDate.getDayOfYear() / 365.0) 
                + (Math.random() * 6 - 3); // ±3°C variation
            double irradiance = 5.0 * summerFactor * weatherFactor * (0.9 + Math.random() * 0.2);
            
            Map<String, Object> day = new HashMap<>();
            day.put("consumption", consumption);
            day.put("pv_production", pvProduction);
            day.put("temperature", temperature);
            day.put("irradiance", irradiance);
            day.put("datetime", currentDate.toString());
            historicalData.add(day);
        }
        
        return historicalData;
    }
}

