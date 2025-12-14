package com.microgrid.service;

import com.microgrid.model.MoroccanCity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service pour les recommandations intelligentes basées sur ML
 */
@Service
public class MlRecommendationService {

    @Value("${ai.microservice.url:http://localhost:8000}")
    private String aiMicroserviceUrl;

    @Autowired
    private SizingService sizingService;

    private final RestTemplate restTemplate;

    public MlRecommendationService() {
        this.restTemplate = new RestTemplate();
    }

    /**
     * Résultat des recommandations ML
     * Note: ROI calculé via formule déterministe côté backend, pas avec ML
     */
    public static class MlRecommendationResult {
        public final List<Map<String, Object>> recommendations;
        public final String method;

        public MlRecommendationResult(List<Map<String, Object>> recommendations, String method) {
            this.recommendations = recommendations;
            this.method = method;
        }
    }

    /**
     * Obtient des recommandations intelligentes basées sur règles + patterns similaires
     * Note: ROI calculé via formule déterministe (SizingService.calculateROI), pas avec ML
     */
    public MlRecommendationResult getMlRecommendations(
            String establishmentType,
            int numberOfBeds,
            double monthlyConsumption,
            Double installableSurface,
            String irradiationClass,
            double recommendedPvPower,
            double recommendedBattery,
            double autonomy,
            double roiYears,  // ROI calculé côté backend avec formule déterministe
            List<Map<String, Object>> similarEstablishments) {
        
        try {
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("establishment_type", establishmentType);
            requestBody.put("number_of_beds", numberOfBeds);
            requestBody.put("monthly_consumption", monthlyConsumption);
            if (installableSurface != null) {
                requestBody.put("installable_surface", installableSurface);
            }
            requestBody.put("irradiation_class", irradiationClass);
            requestBody.put("recommended_pv_power", recommendedPvPower);
            requestBody.put("recommended_battery", recommendedBattery);
            requestBody.put("autonomy", autonomy);
            requestBody.put("roi_years", roiYears);  // ROI calculé côté backend
            if (similarEstablishments != null) {
                requestBody.put("similar_establishments", similarEstablishments);
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            String url = aiMicroserviceUrl + "/recommendations/ml";
            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> recommendations = (List<Map<String, Object>>) body.getOrDefault("recommendations", List.of());
                String method = (String) body.getOrDefault("method", "hybrid_decision_system");
                
                return new MlRecommendationResult(recommendations, method);
            }
            
            throw new RuntimeException("Failed to get ML recommendations from AI microservice");
        } catch (Exception e) {
            System.err.println("Error calling AI microservice /recommendations/ml: " + e.getMessage());
            return new MlRecommendationResult(List.of(), "fallback");
        }
    }

    /**
     * Obtient des recommandations intelligentes pour un établissement (wrapper)
     * Note: ROI calculé via formule déterministe (SizingService.calculateROI), pas avec ML
     */
    public Map<String, Object> getMlRecommendations(com.microgrid.model.Establishment establishment) {
        double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
            ? establishment.getMonthlyConsumptionKwh()
            : 50000.0; // Fallback
        
        // Convertir IrradiationClass
        MoroccanCity.IrradiationClass irradiationClass = convertIrradiationClass(establishment.getIrradiationClass());
        
        // Calculer les valeurs recommandées AVANT de les passer au système de recommandations
        double recommendedPvPower = sizingService.calculateRecommendedPvPower(monthlyConsumption, irradiationClass);
        double recommendedBattery = sizingService.calculateRecommendedBatteryCapacityFromMonthly(monthlyConsumption);
        
        // Calculer l'autonomie énergétique
        double autonomy = 0.0;
        Double installableSurface = establishment.getInstallableSurfaceM2();
        if (installableSurface != null && installableSurface > 0) {
            autonomy = sizingService.calculateEnergyAutonomy(
                installableSurface, monthlyConsumption, irradiationClass);
        } else {
            // Utiliser la surface recommandée
            double recommendedSurface = sizingService.calculateRecommendedPvSurface(monthlyConsumption, irradiationClass);
            autonomy = sizingService.calculateEnergyAutonomy(
                recommendedSurface, monthlyConsumption, irradiationClass);
        }
        
        // Calculer ROI avec formule déterministe (pas ML)
        double annualSavings = sizingService.calculateAnnualSavings(monthlyConsumption, autonomy, 1.2);
        // Estimation coût installation (formule simple)
        double installationCost = (recommendedPvPower * 2500) + (recommendedBattery * 4000) + (recommendedPvPower * 2000) * 1.2;
        double roiYears = sizingService.calculateROI(installationCost, annualSavings);
        
        MlRecommendationResult result = getMlRecommendations(
            establishment.getType().toString(),
            establishment.getNumberOfBeds(),
            monthlyConsumption,
            installableSurface,
            establishment.getIrradiationClass() != null ? establishment.getIrradiationClass().toString() : "C",
            recommendedPvPower,
            recommendedBattery,
            autonomy,
            roiYears,  // ROI calculé avec formule déterministe
            null // similarEstablishments
        );
        
        Map<String, Object> response = new HashMap<>();
        response.put("recommendations", result.recommendations);
        response.put("method", result.method);
        // Note: ROI n'est plus dans la réponse car calculé côté backend avec formule
        return response;
    }
    
    /**
     * Convertit Establishment.IrradiationClass en MoroccanCity.IrradiationClass
     */
    private MoroccanCity.IrradiationClass convertIrradiationClass(com.microgrid.model.Establishment.IrradiationClass class_) {
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

