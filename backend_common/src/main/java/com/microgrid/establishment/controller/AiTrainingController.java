package com.microgrid.establishment.controller;

import com.microgrid.service.AutoTrainingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller pour l'entraînement automatique du modèle ML
 */
@RestController
@RequestMapping("/api/ai")
@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:3000"})
public class AiTrainingController {

    @Autowired
    private AutoTrainingService autoTrainingService;

    /**
     * Déclenche manuellement l'entraînement du modèle ML
     * POST /api/ai/retrain
     */
    @PostMapping("/retrain")
    public ResponseEntity<Map<String, Object>> triggerRetrain(Authentication authentication) {
        try {
            if (autoTrainingService.isTrainingInProgress()) {
                return ResponseEntity.status(409).body(Map.of(
                    "status", "error",
                    "message", "Training already in progress"
                ));
            }

            Map<String, Object> result = autoTrainingService.triggerRetrain();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                "status", "error",
                "message", e.getMessage()
            ));
        }
    }

    /**
     * Obtient le statut de l'entraînement
     * GET /api/ai/training/status
     */
    @GetMapping("/training/status")
    public ResponseEntity<Map<String, Object>> getTrainingStatus() {
        return ResponseEntity.ok(Map.of(
            "isTrainingInProgress", autoTrainingService.isTrainingInProgress(),
            "lastTrainingDate", autoTrainingService.getLastTrainingDate() != null 
                ? autoTrainingService.getLastTrainingDate().toString() 
                : "Never"
        ));
    }
}


