package com.microgrid.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * Service pour détecter les anomalies avec ML
 */
@Service
public class AnomalyDetectionService {

    @Value("${ai.microservice.url:http://localhost:8000}")
    private String aiMicroserviceUrl;

    private final RestTemplate restTemplate;

    public AnomalyDetectionService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Résultat de la détection d'anomalie
     */
    public static class AnomalyResult {
        public final boolean isAnomaly;
        public final double anomalyScore;
        public final String anomalyType;
        public final String recommendation;

        public AnomalyResult(boolean isAnomaly, double anomalyScore, String anomalyType, String recommendation) {
            this.isAnomaly = isAnomaly;
            this.anomalyScore = anomalyScore;
            this.anomalyType = anomalyType;
            this.recommendation = recommendation;
        }
    }

    /**
     * Détecte une anomalie dans les données
     * 
     * @param consumption Consommation réelle en kWh
     * @param predictedConsumption Consommation prédite en kWh
     * @param pvProduction Production PV réelle en kWh
     * @param expectedPv Production PV attendue en kWh
     * @param soc État de charge batterie en kWh
     * @param temperatureC Température en °C
     * @param irradianceKwhM2 Irradiance en kWh/m²
     * @return Résultat de la détection
     */
    public AnomalyResult detectAnomaly(
            double consumption,
            double predictedConsumption,
            double pvProduction,
            double expectedPv,
            double soc,
            double temperatureC,
            double irradianceKwhM2) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("consumption", consumption);
            requestBody.put("predicted_consumption", predictedConsumption);
            requestBody.put("pv_production", pvProduction);
            requestBody.put("expected_pv", expectedPv);
            requestBody.put("soc", soc);
            requestBody.put("temperature_C", temperatureC);
            requestBody.put("irradiance_kWh_m2", irradianceKwhM2);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/detect/anomalies";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                boolean isAnomaly = (Boolean) body.getOrDefault("is_anomaly", false);
                double anomalyScore = ((Number) body.getOrDefault("anomaly_score", 0.0)).doubleValue();
                String anomalyType = (String) body.getOrDefault("anomaly_type", "normal");
                String recommendation = (String) body.getOrDefault("recommendation", "No action needed");
                
                return new AnomalyResult(isAnomaly, anomalyScore, anomalyType, recommendation);
            }
            
            throw new RuntimeException("Failed to get anomaly detection from AI microservice");
        } catch (Exception e) {
            // En cas d'erreur, retourner "pas d'anomalie" pour ne pas bloquer
            System.err.println("Error calling AI microservice /detect/anomalies: " + e.getMessage());
            return new AnomalyResult(false, 0.0, "normal", "Anomaly detection service unavailable");
        }
    }
}


