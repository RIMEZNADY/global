package com.microgrid.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service pour prédire la production PV avec ML
 */
@Service
public class PvPredictionService {

    @Value("${ai.microservice.url:http://localhost:8000}")
    private String aiMicroserviceUrl;

    private final RestTemplate restTemplate;

    public PvPredictionService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Prédit la production PV avec ML
     * 
     * @param datetime Date/heure
     * @param irradianceKwhM2 Irradiance en kWh/m²
     * @param temperatureC Température en °C
     * @param surfaceM2 Surface PV en m²
     * @param historicalPv Historique de production PV (optionnel)
     * @return Prédiction de production PV en kWh
     */
    public double predictPvProduction(
            LocalDateTime datetime,
            double irradianceKwhM2,
            double temperatureC,
            double surfaceM2,
            List<Double> historicalPv) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("datetime", datetime.format(DateTimeFormatter.ISO_DATE_TIME));
            requestBody.put("irradiance_kWh_m2", irradianceKwhM2);
            requestBody.put("temperature_C", temperatureC);
            requestBody.put("surface_m2", surfaceM2);
            
            if (historicalPv != null && !historicalPv.isEmpty()) {
                requestBody.put("historical_pv", historicalPv);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/predict/pv";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                Object predictedValue = body.get("predicted_pv_kWh");
                if (predictedValue instanceof Number) {
                    return ((Number) predictedValue).doubleValue();
                }
            }
            
            throw new RuntimeException("Failed to get PV prediction from AI microservice");
        } catch (Exception e) {
            throw new RuntimeException("Error calling AI microservice /predict/pv: " + e.getMessage(), e);
        }
    }
}


