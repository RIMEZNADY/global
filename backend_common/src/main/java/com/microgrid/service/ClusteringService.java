package com.microgrid.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * Service pour le clustering d'établissements similaires
 */
@Service
public class ClusteringService {

    @Value("${ai.microservice.url:http://localhost:8000}")
    private String aiMicroserviceUrl;

    private final RestTemplate restTemplate;

    public ClusteringService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Résultat du clustering
     */
    public static class ClusterResult {
        public final int clusterId;
        public final double distanceToCenter;
        public final String message;

        public ClusterResult(int clusterId, double distanceToCenter, String message) {
            this.clusterId = clusterId;
            this.distanceToCenter = distanceToCenter;
            this.message = message;
        }
    }

    /**
     * Clustérise un établissement
     */
    public ClusterResult clusterEstablishment(
            String establishmentType,
            int numberOfBeds,
            double monthlyConsumption,
            Double installableSurface,
            String irradiationClass,
            Double latitude,
            Double longitude) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("establishment_type", establishmentType);
            requestBody.put("number_of_beds", numberOfBeds);
            requestBody.put("monthly_consumption", monthlyConsumption);
            if (installableSurface != null) {
                requestBody.put("installable_surface", installableSurface);
            }
            requestBody.put("irradiation_class", irradiationClass);
            if (latitude != null) {
                requestBody.put("latitude", latitude);
            }
            if (longitude != null) {
                requestBody.put("longitude", longitude);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/cluster/establishments";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                int clusterId = ((Number) body.getOrDefault("cluster_id", -1)).intValue();
                double distance = ((Number) body.getOrDefault("distance_to_center", 0.0)).doubleValue();
                String message = (String) body.getOrDefault("message", "");
                
                return new ClusterResult(clusterId, distance, message);
            }
            
            throw new RuntimeException("Failed to get clustering from AI microservice");
        } catch (Exception e) {
            System.err.println("Error calling AI microservice /cluster/establishments: " + e.getMessage());
            return new ClusterResult(-1, 0.0, "Clustering service unavailable");
        }
    }

    /**
     * Obtient le cluster d'un établissement (wrapper)
     */
    public Map<String, Object> getEstablishmentCluster(com.microgrid.model.Establishment establishment) {
        double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
            ? establishment.getMonthlyConsumptionKwh()
            : 50000.0; // Fallback
        
        ClusterResult result = clusterEstablishment(
            establishment.getType().toString(),
            establishment.getNumberOfBeds(),
            monthlyConsumption,
            establishment.getInstallableSurfaceM2(),
            establishment.getIrradiationClass() != null ? establishment.getIrradiationClass().toString() : "C",
            establishment.getLatitude(),
            establishment.getLongitude()
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("cluster_id", result.clusterId);
        response.put("distance_to_center", result.distanceToCenter);
        response.put("message", result.message);
        return response;
    }
}

