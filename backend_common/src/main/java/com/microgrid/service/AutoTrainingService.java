package com.microgrid.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Service pour l'entraînement automatique du modèle ML
 */
@Service
public class AutoTrainingService {

    @Value("${ai.microservice.url:http://localhost:8000}")
    private String aiMicroserviceUrl;

    @Autowired
    private RestTemplate restTemplate;

    private LocalDateTime lastTrainingDate;
    private boolean trainingInProgress = false;

    /**
     * Déclenche l'entraînement automatique du modèle ML
     * Exécuté tous les jours à 2h du matin
     */
    @Scheduled(cron = "0 0 2 * * ?") // Tous les jours à 2h
    public void scheduleAutoRetrain() {
        if (trainingInProgress) {
            System.out.println("Training already in progress, skipping...");
            return;
        }

        try {
            System.out.println("Starting scheduled auto-retraining at " + LocalDateTime.now());
            triggerRetrain();
            lastTrainingDate = LocalDateTime.now();
            System.out.println("Auto-retraining completed successfully");
        } catch (Exception e) {
            System.err.println("Error during auto-retraining: " + e.getMessage());
        } finally {
            trainingInProgress = false;
        }
    }

    /**
     * Déclenche manuellement l'entraînement
     */
    public Map<String, Object> triggerRetrain() {
        if (trainingInProgress) {
            throw new RuntimeException("Training already in progress");
        }

        trainingInProgress = true;
        try {
            String url = aiMicroserviceUrl + "/retrain";
            
            Map<String, Object> response = restTemplate.postForObject(
                url,
                null,
                Map.class
            );

            if (response != null && "ok".equals(response.get("status"))) {
                System.out.println("Retraining successful. Metrics: " + response.get("metrics"));
                lastTrainingDate = LocalDateTime.now();
                return response;
            } else {
                throw new RuntimeException("Retraining failed: " + response);
            }
        } catch (Exception e) {
            System.err.println("Error calling retrain endpoint: " + e.getMessage());
            throw new RuntimeException("Failed to trigger retraining: " + e.getMessage(), e);
        } finally {
            trainingInProgress = false;
        }
    }

    /**
     * Déclenche l'entraînement avec nouvelles données collectées
     * 
     * @param newDataCount Nombre de nouvelles données collectées
     */
    public void triggerRetrainWithNewData(int newDataCount) {
        // Seuil minimum de nouvelles données avant réentraînement
        int MIN_NEW_DATA = 100;
        
        if (newDataCount < MIN_NEW_DATA) {
            System.out.println("Not enough new data (" + newDataCount + " < " + MIN_NEW_DATA + "), skipping retrain");
            return;
        }

        // Vérifier qu'on n'a pas récemment entraîné (éviter sur-entraînement)
        if (lastTrainingDate != null && 
            lastTrainingDate.isAfter(LocalDateTime.now().minusHours(6))) {
            System.out.println("Recently trained, skipping to avoid overfitting");
            return;
        }

        System.out.println("Triggering retrain with " + newDataCount + " new data points");
        triggerRetrain();
    }

    /**
     * Obtient la date du dernier entraînement
     */
    public LocalDateTime getLastTrainingDate() {
        return lastTrainingDate;
    }

    /**
     * Vérifie si un entraînement est en cours
     */
    public boolean isTrainingInProgress() {
        return trainingInProgress;
    }
}


