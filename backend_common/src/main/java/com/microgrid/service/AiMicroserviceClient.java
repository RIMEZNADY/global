package com.microgrid.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * Client pour appeler le microservice AI (FastAPI)
 */
@Service
public class AiMicroserviceClient {

    @Value("${ai.microservice.url:http://localhost:8000}")
    private String aiMicroserviceUrl;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public AiMicroserviceClient() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Prédit la consommation future
     * 
     * @param datetime Date/heure de prédiction
     * @param temperatureC Température en °C
     * @param irradianceKwhM2 Irradiance en kWh/m²
     * @param pvProdKwh Production PV en kWh
     * @param patients Nombre de patients
     * @param socBatterieKwh État de charge batterie (optionnel)
     * @param event Événement (optionnel)
     * @return Prédiction de consommation en kWh
     */
    public double predictConsumption(
            LocalDateTime datetime,
            double temperatureC,
            double irradianceKwhM2,
            double pvProdKwh,
            double patients,
            Double socBatterieKwh,
            String event) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("datetime", datetime.format(DateTimeFormatter.ISO_DATE_TIME));
            requestBody.put("temperature_C", temperatureC);
            requestBody.put("irradiance_kWh_m2", irradianceKwhM2);
            requestBody.put("pv_prod_kWh", pvProdKwh);
            requestBody.put("patients", patients);
            
            if (socBatterieKwh != null) {
                requestBody.put("soc_batterie_kWh", socBatterieKwh);
            }
            if (event != null) {
                requestBody.put("event", event);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/predict";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                Object predictedValue = body.get("predicted_consumption_kWh");
                if (predictedValue instanceof Number) {
                    return ((Number) predictedValue).doubleValue();
                }
            }
            
            throw new RuntimeException("Failed to get prediction from AI microservice");
        } catch (Exception e) {
            throw new RuntimeException("Error calling AI microservice /predict: " + e.getMessage(), e);
        }
    }

    /**
     * Optimise le dispatch énergétique
     * 
     * @param predKwh Consommation prédite en kWh
     * @param pvKwh Production PV en kWh
     * @param socKwh État de charge batterie en kWh
     * @param batteryParams Paramètres batterie (optionnel)
     * @return Résultat d'optimisation
     */
    public Map<String, Object> optimizeDispatch(
            double predKwh,
            double pvKwh,
            double socKwh,
            Map<String, Double> batteryParams) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("pred_kWh", predKwh);
            requestBody.put("pv_kWh", pvKwh);
            requestBody.put("soc_kwh", socKwh);
            
            if (batteryParams != null) {
                requestBody.putAll(batteryParams);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/optimize";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                return response.getBody();
            }
            
            throw new RuntimeException("Failed to get optimization from AI microservice");
        } catch (Exception e) {
            throw new RuntimeException("Error calling AI microservice /optimize: " + e.getMessage(), e);
        }
    }
}


