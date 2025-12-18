package com.microgrid.establishment.controller;

import com.microgrid.establishment.dto.*;
import com.microgrid.establishment.service.EstablishmentService;
import com.microgrid.service.*;
import com.microgrid.model.Establishment;
import java.util.Map;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;
import java.util.HashMap;

@RestController
@RequestMapping("/api/establishments")
@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:3000"})
public class EstablishmentController {
    
    @Autowired
    private EstablishmentService establishmentService;
    
    @Autowired
    private SimulationService simulationService;
    
    @Autowired
    private SizingService sizingService;
    
    @Autowired
    private PvCalculationService pvCalculationService;
    
    @Autowired
    private ConsumptionEstimationService consumptionEstimationService;
    
    @Autowired
    private ClusteringService clusteringService;
    
    @Autowired
    private MlRecommendationService mlRecommendationService;
    
    @Autowired
    private LongTermPredictionService longTermPredictionService;
    
    @Autowired
    private AnomalyDetectionService anomalyDetectionService;
    
    @Autowired
    private MeteoDataService meteoDataService;
    
    @Autowired
    private ComprehensiveResultsService comprehensiveResultsService;

    /**
     * Helper: if Authentication is missing (permitAll), fetch by ID directly.
     * If Authentication is present, enforce ownership via email.
     */
    private Establishment getEstablishmentOptionalAuth(Long id, Authentication authentication) {
        try {
            if (authentication != null && authentication.isAuthenticated() && authentication.getName() != null) {
                String email = authentication.getName();
                if (email != null && !email.isEmpty()) {
                    return establishmentService.getEstablishmentEntity(id, email);
                }
            }
        } catch (Exception ignored) {
            // fall back to direct fetch below
        }
        return establishmentService.getEstablishmentEntityById(id);
    }
    
    @PostMapping
    public ResponseEntity<?> createEstablishment(
            @Valid @RequestBody EstablishmentRequest request,
            Authentication authentication) {
        try {
            // Permettre la création sans authentification (comme dans Flutter)
            // Utiliser un email par défaut si l'authentification n'est pas disponible
            String email = "guest@microgrid.local";
            if (authentication != null && authentication.getName() != null) {
                email = authentication.getName();
            }
            EstablishmentResponse response = establishmentService.createEstablishment(email, request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (com.microgrid.exception.ValidationException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("message", "Erreur lors de la création: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        }
    }
    
    @GetMapping
    public ResponseEntity<List<EstablishmentResponse>> getUserEstablishments(Authentication authentication) {
        try {
            // Permettre l'accès sans authentification (comme dans Flutter)
            // Retourner une liste vide si l'authentification n'est pas disponible
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.ok(List.of());
            }
            String email = authentication.getName();
            List<EstablishmentResponse> establishments = establishmentService.getUserEstablishments(email);
            return ResponseEntity.ok(establishments);
        } catch (Exception e) {
            // En cas d'erreur, retourner une liste vide plutôt qu'une erreur
            return ResponseEntity.ok(List.of());
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<EstablishmentResponse> getEstablishment(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            String email = authentication.getName();
            EstablishmentResponse response = establishmentService.getEstablishment(id, email);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<EstablishmentResponse> updateEstablishment(
            @PathVariable Long id,
            @Valid @RequestBody EstablishmentRequest request,
            Authentication authentication) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            String email = authentication.getName();
            EstablishmentResponse response = establishmentService.updateEstablishment(id, email, request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteEstablishment(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            String email = authentication.getName();
            establishmentService.deleteEstablishment(id, email);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }
    
    /**
     * Simule le comportement énergétique d'un établissement sur une période
     * POST /api/establishments/{id}/simulate
     */
    @PostMapping("/{id}/simulate")
    public ResponseEntity<SimulationResponse> simulateEstablishment(
            @PathVariable Long id,
            @Valid @RequestBody SimulationRequest request,
            Authentication authentication) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            String email = authentication.getName();
            Establishment establishment = establishmentService.getEstablishmentEntity(id, email);
            
            // Valeurs par défaut si non spécifiées
            double batteryCapacity = request.getBatteryCapacityKwh() != null 
                ? request.getBatteryCapacityKwh() 
                : 500.0;
            double initialSoc = request.getInitialSocKwh() != null 
                ? request.getInitialSocKwh() 
                : batteryCapacity * 0.5; // 50% par défaut
            
            SimulationService.SimulationResult result = simulationService.simulate(
                establishment,
                request.getStartDate(),
                request.getDays(),
                batteryCapacity,
                initialSoc
            );
            
            // Convertir en DTO avec détection d'anomalies
            SimulationResponse response = new SimulationResponse();
            List<SimulationResponse.SimulationStep> stepList = new java.util.ArrayList<>();
            
            for (SimulationService.SimulationStep step : result.steps) {
                // Détecter anomalie pour ce pas
                boolean hasAnomaly = false;
                String anomalyType = null;
                Double anomalyScore = null;
                String anomalyRecommendation = null;
                
                try {
                    double expectedPv = pvCalculationService.calculatePvProductionFromIrradiance(
                        establishment.getInstallableSurfaceM2() != null ? establishment.getInstallableSurfaceM2() : 0.0,
                        meteoDataService.getAverageIrradiance(convertIrradiationClass(establishment.getIrradiationClass())) / 4.0
                    );
                    
                    AnomalyDetectionService.AnomalyResult anomalyResult = anomalyDetectionService.detectAnomaly(
                        step.predictedConsumption,
                        step.predictedConsumption,
                        step.pvProduction,
                        expectedPv,
                        step.socBattery,
                        20.0, // Température moyenne
                        meteoDataService.getAverageIrradiance(convertIrradiationClass(establishment.getIrradiationClass())) / 4.0
                    );
                    
                    if (anomalyResult.isAnomaly) {
                        hasAnomaly = true;
                        anomalyType = anomalyResult.anomalyType;
                        anomalyScore = anomalyResult.anomalyScore;
                        anomalyRecommendation = anomalyResult.recommendation;
                    }
                } catch (Exception e) {
                    // Ignorer erreurs
                }
                
                SimulationResponse.SimulationStep stepDto = new SimulationResponse.SimulationStep(
                    step.datetime,
                    step.predictedConsumption,
                    step.pvProduction,
                    step.socBattery,
                    step.gridImport,
                    step.batteryCharge,
                    step.batteryDischarge,
                    step.note,
                    hasAnomaly,
                    anomalyType,
                    anomalyScore,
                    anomalyRecommendation
                );
                stepList.add(stepDto);
            }
            
            response.setSteps(stepList);
            
            // Calculer recommandations pour le summary
            double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
                ? establishment.getMonthlyConsumptionKwh()
                : consumptionEstimationService.estimateMonthlyConsumption(
                    establishment.getType(), establishment.getNumberOfBeds());
            
            com.microgrid.model.MoroccanCity.IrradiationClass irradiationClass = 
                convertIrradiationClass(establishment.getIrradiationClass());
            
            double recommendedPv = sizingService.calculateRecommendedPvPower(
                monthlyConsumption, irradiationClass);
            double recommendedBattery = sizingService.calculateRecommendedBatteryCapacityFromMonthly(
                monthlyConsumption);
            
            response.setSummary(new SimulationResponse.SimulationSummary(
                result.totalConsumption,
                result.totalPvProduction,
                result.totalGridImport,
                result.averageAutonomy,
                result.totalSavings,
                recommendedPv,
                recommendedBattery
            ));
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * Calcule les recommandations de dimensionnement pour un établissement avec IA
     * GET /api/establishments/{id}/recommendations
     */
    @GetMapping("/{id}/recommendations")
    public ResponseEntity<RecommendationsResponse> getRecommendations(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            Establishment establishment = getEstablishmentOptionalAuth(id, authentication);
            
            // Consommation mensuelle
            double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
                ? establishment.getMonthlyConsumptionKwh()
                : consumptionEstimationService.estimateMonthlyConsumption(
                    establishment.getType(), establishment.getNumberOfBeds());
            
            // Classe d'irradiation
            com.microgrid.model.MoroccanCity.IrradiationClass irradiationClass = 
                convertIrradiationClass(establishment.getIrradiationClass());
            
            // Calculer recommandations de base
            double recommendedPvPower = sizingService.calculateRecommendedPvPower(
                monthlyConsumption, irradiationClass);
            double recommendedPvSurface = sizingService.calculateRecommendedPvSurface(
                monthlyConsumption, irradiationClass);
            double recommendedBattery = sizingService.calculateRecommendedBatteryCapacityFromMonthly(
                monthlyConsumption);
            
            // Autonomie énergétique
            double autonomy = 0.0;
            if (establishment.getInstallableSurfaceM2() != null && establishment.getInstallableSurfaceM2() > 0) {
                autonomy = sizingService.calculateEnergyAutonomy(
                    establishment.getInstallableSurfaceM2(),
                    monthlyConsumption,
                    irradiationClass
                );
            } else {
                // Utiliser la surface recommandée
                autonomy = sizingService.calculateEnergyAutonomy(
                    recommendedPvSurface,
                    monthlyConsumption,
                    irradiationClass
                );
            }
            
            // Utiliser le service ML pour améliorer les recommandations avec IA
            try {
                // establishment est déjà de type com.microgrid.model.Establishment
                Map<String, Object> mlResult = mlRecommendationService.getMlRecommendations(establishment);
                
                // Note: ROI calculé avec formule déterministe (SizingService.calculateROI), pas avec ML
                // Les recommandations ML sont utilisées pour alertes et optimisations,
                // pas pour ajuster le dimensionnement basique
                
                // Utiliser les recommandations ML si disponibles
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> mlRecommendations = 
                    (List<Map<String, Object>>) mlResult.get("recommendations");
                if (mlRecommendations != null && !mlRecommendations.isEmpty()) {
                    for (Map<String, Object> rec : mlRecommendations) {
                        if (rec.containsKey("type") && "pv_power".equals(rec.get("type"))) {
                            Object value = rec.get("value");
                            if (value instanceof Number) {
                                recommendedPvPower = ((Number) value).doubleValue();
                            }
                        } else if (rec.containsKey("type") && "battery_capacity".equals(rec.get("type"))) {
                            Object value = rec.get("value");
                            if (value instanceof Number) {
                                recommendedBattery = ((Number) value).doubleValue();
                            }
                        }
                    }
                }
            } catch (Exception e) {
                // Si le service ML échoue, utiliser les valeurs de base
                // Log l'erreur mais continue avec les recommandations de base
                System.err.println("ML recommendation service unavailable, using base recommendations: " + e.getMessage());
            }
            
            // Économies annuelles
            double annualSavings = sizingService.calculateAnnualSavings(
                monthlyConsumption, autonomy, 1.2); // 1.2 DH/kWh
            
            // Utiliser le service standardisé pour le coût d'installation
            double installationCost = comprehensiveResultsService.estimateInstallationCost(recommendedPvPower, recommendedBattery);
            double roi = sizingService.calculateROI(installationCost, annualSavings);
            
            RecommendationsResponse response = new RecommendationsResponse(
                recommendedPvPower,
                recommendedPvSurface,
                recommendedBattery,
                autonomy,
                annualSavings,
                roi,
                String.format("Recommandations basées sur IA et consommation mensuelle de %.0f kWh", monthlyConsumption)
            );
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * Calcule les économies et indicateurs économiques
     * GET /api/establishments/{id}/savings
     */
    @GetMapping("/{id}/savings")
    public ResponseEntity<SavingsResponse> calculateSavings(
            @PathVariable Long id,
            @RequestParam(defaultValue = "1.2") double electricityPriceDhPerKwh,
            Authentication authentication) {
        try {
            Establishment establishment = getEstablishmentOptionalAuth(id, authentication);
            
            double monthlyConsumption = establishment.getMonthlyConsumptionKwh() != null
                ? establishment.getMonthlyConsumptionKwh()
                : consumptionEstimationService.estimateMonthlyConsumption(
                    establishment.getType(), establishment.getNumberOfBeds());
            
            com.microgrid.model.MoroccanCity.IrradiationClass irradiationClass = 
                convertIrradiationClass(establishment.getIrradiationClass());
            
            double autonomy = 0.0;
            if (establishment.getInstallableSurfaceM2() != null && establishment.getInstallableSurfaceM2() > 0) {
                autonomy = sizingService.calculateEnergyAutonomy(
                    establishment.getInstallableSurfaceM2(),
                    monthlyConsumption,
                    irradiationClass
                );
            }
            
            double annualSavings = sizingService.calculateAnnualSavings(
                monthlyConsumption, autonomy, electricityPriceDhPerKwh);
            
            SavingsResponse response = new SavingsResponse(
                monthlyConsumption * 12, // Consommation annuelle
                monthlyConsumption * 12 * (autonomy / 100.0), // Énergie PV annuelle
                annualSavings,
                autonomy,
                (monthlyConsumption * 12 * electricityPriceDhPerKwh) - annualSavings // Facture annuelle après PV
            );
            
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * Récupère les données d'anomalies pour un établissement sur une période.
     * GET /api/establishments/{id}/anomalies
     */
    @GetMapping("/{id}/anomalies")
    public ResponseEntity<AnomalyGraphResponse> getAnomalyData(
            @PathVariable Long id,
            @RequestParam(defaultValue = "7") int days,
            Authentication authentication) {
        try {
            Establishment establishment = getEstablishmentOptionalAuth(id, authentication);

            // Pour ce graphique, nous allons réexécuter une simulation pour obtenir les anomalies
            SimulationService.SimulationResult simulationResult = simulationService.simulate(
                establishment,
                java.time.LocalDateTime.now().minusDays(days),
                days,
                500.0, // Capacité batterie par défaut
                250.0  // SOC initial par défaut
            );

            List<AnomalyGraphResponse.AnomalyDataPoint> anomalyDataList = new java.util.ArrayList<>();
            int totalAnomalies = 0;
            int highConsumptionAnomalies = 0;
            int lowConsumptionAnomalies = 0;
            int pvMalfunctionAnomalies = 0;
            int batteryLowAnomalies = 0;
            double totalAnomalyScore = 0.0;
            java.util.Map<String, Integer> anomalyTypeCount = new java.util.HashMap<>();

            for (SimulationService.SimulationStep step : simulationResult.steps) {
                boolean isAnomaly = step.hasAnomaly != null && step.hasAnomaly;
                AnomalyGraphResponse.AnomalyDataPoint dataPoint = new AnomalyGraphResponse.AnomalyDataPoint(
                    step.datetime,
                    isAnomaly,
                    step.anomalyType,
                    step.anomalyScore != null ? step.anomalyScore : 0.0,
                    step.anomalyRecommendation,
                    step.predictedConsumption,
                    step.predictedConsumption,
                    step.pvProduction,
                    step.pvProduction,
                    step.socBattery
                );
                anomalyDataList.add(dataPoint);

                if (isAnomaly) {
                    totalAnomalies++;
                    if (step.anomalyScore != null) {
                        totalAnomalyScore += Math.abs(step.anomalyScore);
                    }
                    if (step.anomalyType != null) {
                        anomalyTypeCount.put(step.anomalyType, anomalyTypeCount.getOrDefault(step.anomalyType, 0) + 1);
                        switch (step.anomalyType) {
                            case "high_consumption" -> highConsumptionAnomalies++;
                            case "low_consumption" -> lowConsumptionAnomalies++;
                            case "pv_malfunction" -> pvMalfunctionAnomalies++;
                            case "battery_low" -> batteryLowAnomalies++;
                        }
                    }
                }
            }

            String mostCommonType = anomalyTypeCount.entrySet().stream()
                .max(java.util.Map.Entry.comparingByValue())
                .map(java.util.Map.Entry::getKey)
                .orElse("none");

            AnomalyGraphResponse.AnomalyStatistics stats = new AnomalyGraphResponse.AnomalyStatistics(
                totalAnomalies,
                highConsumptionAnomalies,
                lowConsumptionAnomalies,
                pvMalfunctionAnomalies,
                batteryLowAnomalies,
                totalAnomalies > 0 ? totalAnomalyScore / totalAnomalies : 0.0,
                mostCommonType
            );

            AnomalyGraphResponse response = new AnomalyGraphResponse(anomalyDataList, stats);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Récupère le cluster d'un établissement et des établissements similaires.
     * GET /api/establishments/{id}/cluster
     */
    @GetMapping("/{id}/cluster")
    public ResponseEntity<Map<String, Object>> getEstablishmentCluster(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            if (authentication == null || authentication.getName() == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            }
            String email = authentication.getName();
            Establishment establishment = establishmentService.getEstablishmentEntity(id, email);

            Map<String, Object> clusterInfo = clusteringService.getEstablishmentCluster(establishment);
            return ResponseEntity.ok(clusterInfo);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Récupère les recommandations ML pour un établissement.
     * GET /api/establishments/{id}/recommendations/ml
     */
    @GetMapping("/{id}/recommendations/ml")
    public ResponseEntity<Map<String, Object>> getMlRecommendations(
            @PathVariable Long id,
            Authentication authentication) {
        try {
            Establishment establishment = getEstablishmentOptionalAuth(id, authentication);

            Map<String, Object> recommendations = mlRecommendationService.getMlRecommendations(establishment);
            return ResponseEntity.ok(recommendations);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Récupère les prévisions à long terme pour un établissement.
     * GET /api/establishments/{id}/forecast
     */
    @GetMapping("/{id}/forecast")
    public ResponseEntity<LongTermForecastResponse> getLongTermForecast(
            @PathVariable Long id,
            @RequestParam(defaultValue = "7") int horizonDays,
            Authentication authentication) {
        try {
            Establishment establishment = getEstablishmentOptionalAuth(id, authentication);

            LongTermForecastResponse forecast = longTermPredictionService.getForecast(
                establishment,
                java.time.LocalDateTime.now(),
                horizonDays
            );
            return ResponseEntity.ok(forecast);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Récupère les prévisions saisonnières pour un établissement.
     * GET /api/establishments/{id}/forecast/seasonal
     */
    @GetMapping("/{id}/forecast/seasonal")
    public ResponseEntity<LongTermForecastResponse> getSeasonalForecast(
            @PathVariable Long id,
            @RequestParam String season,
            @RequestParam(required = false) Integer year,
            Authentication authentication) {
        try {
            Establishment establishment = getEstablishmentOptionalAuth(id, authentication);

            LongTermForecastResponse forecast = longTermPredictionService.getSeasonalForecast(
                establishment,
                season,
                year != null ? year : java.time.LocalDate.now().getYear()
            );
            return ResponseEntity.ok(forecast);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtient tous les résultats complets (impact environnemental, score global, analyse financière, etc.)
     * GET /api/establishments/{id}/comprehensive-results
     * 
     * IMPORTANT: Les résultats sont TOUJOURS calculés pour l'établissement EXACT identifié par {id}.
     * - Avec authentification: vérifie que l'établissement appartient à l'utilisateur
     * - Sans authentification: récupère directement l'établissement par ID (pour compatibilité)
     * 
     * Dans les deux cas, les calculs utilisent les données RÉELLES de cet établissement:
     * - Consommation mensuelle (monthlyConsumptionKwh)
     * - Surface installable (installableSurfaceM2)
     * - Classe d'irradiation (irradiationClass)
     * - Nombre de lits (numberOfBeds)
     * - etc.
     */
    @GetMapping("/{id}/comprehensive-results")
    public ResponseEntity<Map<String, Object>> getComprehensiveResults(
            @PathVariable Long id,
            @org.springframework.lang.Nullable Authentication authentication) {
        try {
            // IMPORTANT: On récupère TOUJOURS l'établissement par son ID exact
            // La seule différence est la vérification de propriété (avec auth) ou non (sans auth)
            Establishment establishment;
            boolean withAuth = false;
            
            try {
                // Essayer d'abord avec authentification si disponible (vérifie la propriété)
                if (authentication != null && authentication.isAuthenticated() && authentication.getPrincipal() != null) {
                    String email = authentication.getName();
                    if (email != null && !email.isEmpty()) {
                        establishment = establishmentService.getEstablishmentEntity(id, email);
                        withAuth = true;
                        System.out.println("✅ Comprehensive results for establishment ID=" + id + " (authenticated user: " + email + ")");
                    } else {
                        // Email vide, récupérer directement par ID
                        establishment = establishmentService.getEstablishmentEntityById(id);
                        System.out.println("⚠️ Comprehensive results for establishment ID=" + id + " (no email, direct fetch)");
                    }
                } else {
                    // Pas d'authentification, récupérer directement par ID
                    establishment = establishmentService.getEstablishmentEntityById(id);
                    System.out.println("⚠️ Comprehensive results for establishment ID=" + id + " (no authentication, direct fetch)");
                }
            } catch (Exception authEx) {
                // Si l'authentification échoue, récupérer directement par ID
                System.err.println("Auth check failed for establishment ID=" + id + ", using direct fetch: " + authEx.getMessage());
                establishment = establishmentService.getEstablishmentEntityById(id);
            }
            
            // Vérification: s'assurer qu'on a bien récupéré l'établissement avec le bon ID
            if (establishment == null || !establishment.getId().equals(id)) {
                throw new RuntimeException("Establishment ID mismatch: expected " + id + " but got " + (establishment != null ? establishment.getId() : "null"));
            }
            
            // Log des données utilisées pour les calculs (pour vérification)
            System.out.println("📊 Calculating comprehensive results for:");
            System.out.println("   - Establishment ID: " + establishment.getId());
            System.out.println("   - Name: " + establishment.getName());
            System.out.println("   - Monthly Consumption: " + (establishment.getMonthlyConsumptionKwh() != null ? establishment.getMonthlyConsumptionKwh() : "null"));
            System.out.println("   - Installable Surface: " + (establishment.getInstallableSurfaceM2() != null ? establishment.getInstallableSurfaceM2() : "null"));
            System.out.println("   - Irradiation Class: " + establishment.getIrradiationClass());
            System.out.println("   - Number of Beds: " + establishment.getNumberOfBeds());
            System.out.println("   - With Auth Check: " + withAuth);
            
            // Calculer tous les résultats BASÉS SUR LES DONNÉES EXACTES DE CET ÉTABLISSEMENT
            Map<String, Object> results = comprehensiveResultsService.calculateAllResults(establishment);
            
            // Ajouter l'ID de l'établissement dans la réponse pour confirmation
            results.put("establishmentId", establishment.getId());
            results.put("establishmentName", establishment.getName());
            results.put("calculatedWithAuth", withAuth);
            
            return ResponseEntity.ok(results);
        } catch (RuntimeException e) {
            System.err.println("Error in getComprehensiveResults for ID=" + id + ": " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            System.err.println("Error calculating comprehensive results for ID=" + id + ": " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // Méthodes utilitaires
    private com.microgrid.model.MoroccanCity.IrradiationClass convertIrradiationClass(
            Establishment.IrradiationClass class_) {
        if (class_ == null) {
            return com.microgrid.model.MoroccanCity.IrradiationClass.C;
        }
        return switch (class_) {
            case A -> com.microgrid.model.MoroccanCity.IrradiationClass.A;
            case B -> com.microgrid.model.MoroccanCity.IrradiationClass.B;
            case C -> com.microgrid.model.MoroccanCity.IrradiationClass.C;
            case D -> com.microgrid.model.MoroccanCity.IrradiationClass.D;
        };
    }
}
