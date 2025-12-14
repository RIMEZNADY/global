# Script de test pour le Cas 2 (Nouvel Établissement)
# Teste les endpoints backend pour un établissement créé via le flow Cas 2

$backendUrl = "http://localhost:8080"
$aiUrl = "http://localhost:8000"

Write-Host "`n=== Test Cas 2 - Nouvel Établissement ===" -ForegroundColor Cyan
Write-Host "Backend: $backendUrl" -ForegroundColor Gray
Write-Host "AI Microservice: $aiUrl" -ForegroundColor Gray

# Vérifier que les services sont démarrés
Write-Host "`n[1] Vérification des services..." -ForegroundColor Yellow
try {
    $healthBackend = Invoke-WebRequest -Uri "$backendUrl/api/public/health" -Method GET -UseBasicParsing
    if ($healthBackend.StatusCode -eq 200) {
        Write-Host "  [OK] Backend démarré" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERREUR] Backend non disponible: $_" -ForegroundColor Red
    exit 1
}

try {
    $healthAi = Invoke-WebRequest -Uri "$aiUrl/health" -Method GET -UseBasicParsing
    if ($healthAi.StatusCode -eq 200) {
        Write-Host "  [OK] AI Microservice démarré" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERREUR] AI Microservice non disponible: $_" -ForegroundColor Red
    Write-Host "  [INFO] Certains tests IA échoueront" -ForegroundColor Yellow
}

# Token JWT (à remplacer par un token valide après login)
# Si NONINTERACTIVE ou $env:JWT_TOKEN est présent, on évite Read-Host.
if ($env:JWT_TOKEN) {
    $token = $env:JWT_TOKEN
    Write-Host "  [INFO] Token fourni via variable d'environnement JWT_TOKEN" -ForegroundColor Yellow
} elseif ($env:NONINTERACTIVE_TEST -eq "1") {
    $token = "test-token"
    Write-Host "  [INFO] Mode non interactif: token de test utilisé (les requêtes authentifiées échoueront)" -ForegroundColor Yellow
} else {
    $token = Read-Host "`nEntrez votre token JWT (ou appuyez sur Entrée pour utiliser 'test-token')"
    if ([string]::IsNullOrWhiteSpace($token)) {
        $token = "test-token"
        Write-Host "  [INFO] Utilisation d'un token de test (les requêtes authentifiées échoueront)" -ForegroundColor Yellow
    }
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# ID d'établissement (sera créé ou récupéré)
$establishmentId = $null

# [2] Créer un établissement Cas 2 (Nouvel Établissement)
Write-Host "`n[2] Création d'un établissement Cas 2..." -ForegroundColor Yellow
$establishmentData = @{
    name = "Hôpital Test Cas 2"
    type = "HOPITAL_REGIONAL"
    numberOfBeds = 50
    latitude = 33.5731
    longitude = -7.5898
    irradiationClass = "C"
    projectBudgetDh = 2000000.0
    totalAvailableSurfaceM2 = 5000.0
    installableSurfaceM2 = 2000.0
    populationServed = 5000
    # Valeurs autorisées: OPTIMIZE_ROI, BUILD_LARGEST, MINIMIZE_COST, MAXIMIZE_AUTONOMY
    projectPriority = "OPTIMIZE_ROI"
} | ConvertTo-Json

try {
    $createResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments" -Method POST -Headers $headers -Body $establishmentData -UseBasicParsing
    if ($createResponse.StatusCode -eq 201 -or $createResponse.StatusCode -eq 200) {
        $establishment = $createResponse.Content | ConvertFrom-Json
        $establishmentId = $establishment.id
        Write-Host "  [OK] Établissement créé (ID: $establishmentId)" -ForegroundColor Green
        Write-Host "    - Nom: $($establishment.name)" -ForegroundColor Gray
        Write-Host "    - Type: $($establishment.type)" -ForegroundColor Gray
        Write-Host "    - Budget: $($establishment.projectBudgetDh) DH" -ForegroundColor Gray
        Write-Host "    - Surface: $($establishment.installableSurfaceM2) m²" -ForegroundColor Gray
    }
} catch {
    Write-Host "  [ERREUR] Échec création établissement: $_" -ForegroundColor Red
    Write-Host "  [INFO] Tentative de récupération d'un établissement existant..." -ForegroundColor Yellow
    
    # Essayer de récupérer un établissement existant
    try {
        $listResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments" -Method GET -Headers $headers -UseBasicParsing
        if ($listResponse.StatusCode -eq 200) {
            $establishments = $listResponse.Content | ConvertFrom-Json
            if ($establishments.Count -gt 0) {
                $establishmentId = $establishments[0].id
                Write-Host "  [OK] Utilisation établissement existant (ID: $establishmentId)" -ForegroundColor Green
            } else {
                Write-Host "  [ERREUR] Aucun établissement trouvé" -ForegroundColor Red
                exit 1
            }
        }
    } catch {
        Write-Host "  [ERREUR] Impossible de récupérer les établissements: $_" -ForegroundColor Red
        exit 1
    }
}

if ($null -eq $establishmentId) {
    Write-Host "  [ERREUR] Aucun établissement disponible pour les tests" -ForegroundColor Red
    exit 1
}

# [3] Test recommandations de dimensionnement
Write-Host "`n[3] Test recommandations de dimensionnement..." -ForegroundColor Yellow
try {
    $recResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments/$establishmentId/recommendations" -Method GET -Headers $headers -UseBasicParsing
    if ($recResponse.StatusCode -eq 200) {
        $recommendations = $recResponse.Content | ConvertFrom-Json
        Write-Host "  [OK] Recommandations récupérées" -ForegroundColor Green
        Write-Host "    - Puissance PV recommandée: $($recommendations.recommendedPvPowerKwc) kWc" -ForegroundColor Gray
        Write-Host "    - Surface PV recommandée: $($recommendations.recommendedPvSurfaceM2) m²" -ForegroundColor Gray
        Write-Host "    - Capacité batterie: $($recommendations.recommendedBatteryCapacityKwh) kWh" -ForegroundColor Gray
        Write-Host "    - Autonomie énergétique: $([math]::Round($recommendations.estimatedEnergyAutonomy, 1))%" -ForegroundColor Gray
        Write-Host "    - Économies annuelles: $([math]::Round($recommendations.estimatedAnnualSavings, 0)) DH" -ForegroundColor Gray
        Write-Host "    - ROI estimé: $([math]::Round($recommendations.estimatedROI, 1)) ans" -ForegroundColor Gray
    }
} catch {
    Write-Host "  [ERREUR] Échec récupération recommandations: $_" -ForegroundColor Red
}

# [4] Test économies
Write-Host "`n[4] Test calcul économies..." -ForegroundColor Yellow
try {
    $savingsResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments/$establishmentId/savings?electricityPriceDhPerKwh=1.2" -Method GET -Headers $headers -UseBasicParsing
    if ($savingsResponse.StatusCode -eq 200) {
        $savings = $savingsResponse.Content | ConvertFrom-Json
        Write-Host "  [OK] Économies calculées" -ForegroundColor Green
        Write-Host "    - Consommation annuelle: $([math]::Round($savings.annualConsumption, 0)) kWh" -ForegroundColor Gray
        Write-Host "    - Production PV annuelle: $([math]::Round($savings.annualPvEnergy, 0)) kWh" -ForegroundColor Gray
        Write-Host "    - Économies annuelles: $([math]::Round($savings.annualSavings, 0)) DH" -ForegroundColor Gray
        Write-Host "    - Autonomie: $([math]::Round($savings.autonomyPercentage, 1))%" -ForegroundColor Gray
        Write-Host "    - Facture après PV: $([math]::Round($savings.annualBillAfterPv, 0)) DH" -ForegroundColor Gray
    }
} catch {
    Write-Host "  [ERREUR] Échec calcul économies: $_" -ForegroundColor Red
}

# [5] Test simulation
Write-Host "`n[5] Test simulation complète..." -ForegroundColor Yellow
$simulationData = @{
    startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    days = 3
    batteryCapacityKwh = 500.0
    initialSocKwh = 250.0
} | ConvertTo-Json

try {
    $simResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments/$establishmentId/simulate" -Method POST -Headers $headers -Body $simulationData -UseBasicParsing
    if ($simResponse.StatusCode -eq 200) {
        $simulation = $simResponse.Content | ConvertFrom-Json
        Write-Host "  [OK] Simulation complétée" -ForegroundColor Green
        Write-Host "    - Nombre de pas: $($simulation.steps.Count)" -ForegroundColor Gray
        if ($simulation.summary) {
            Write-Host "    - Consommation totale: $([math]::Round($simulation.summary.totalConsumption, 0)) kWh" -ForegroundColor Gray
            Write-Host "    - Production PV totale: $([math]::Round($simulation.summary.totalPvProduction, 0)) kWh" -ForegroundColor Gray
            Write-Host "    - Import réseau: $([math]::Round($simulation.summary.totalGridImport, 0)) kWh" -ForegroundColor Gray
            Write-Host "    - Autonomie moyenne: $([math]::Round($simulation.summary.averageAutonomy, 1))%" -ForegroundColor Gray
            Write-Host "    - Économies totales: $([math]::Round($simulation.summary.totalSavings, 0)) DH" -ForegroundColor Gray
        }
        
        # Compter les anomalies détectées
        $anomaliesCount = ($simulation.steps | Where-Object { $_.hasAnomaly -eq $true }).Count
        if ($anomaliesCount -gt 0) {
            Write-Host "    - Anomalies détectées: $anomaliesCount" -ForegroundColor Yellow
        } else {
            Write-Host "    - Aucune anomalie détectée" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  [ERREUR] Échec simulation: $_" -ForegroundColor Red
}

# [6] Test prédiction long terme
Write-Host "`n[6] Test prédiction long terme (IA)..." -ForegroundColor Yellow
try {
    $forecastResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments/$establishmentId/forecast?horizonDays=7" -Method GET -Headers $headers -UseBasicParsing
    if ($forecastResponse.StatusCode -eq 200) {
        $forecast = $forecastResponse.Content | ConvertFrom-Json
        Write-Host "  [OK] Prédiction long terme récupérée" -ForegroundColor Green
        Write-Host "    - Nombre de prédictions: $($forecast.predictions.Count)" -ForegroundColor Gray
        Write-Host "    - Méthode: $($forecast.method)" -ForegroundColor Gray
        Write-Host "    - Tendance: $($forecast.trend)" -ForegroundColor Gray
        if ($forecast.predictions.Count -gt 0) {
            $firstPred = $forecast.predictions[0]
            Write-Host "    - Jour 1 - Consommation: $([math]::Round($firstPred.predictedConsumption, 0)) kWh, PV: $([math]::Round($firstPred.predictedPvProduction, 0)) kWh" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  [ERREUR] Échec prédiction long terme: $_" -ForegroundColor Red
    Write-Host "  [INFO] Vérifiez que l'AI microservice est démarré" -ForegroundColor Yellow
}

# [7] Test recommandations ML
Write-Host "`n[7] Test recommandations ML (IA)..." -ForegroundColor Yellow
try {
    $mlRecResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments/$establishmentId/recommendations/ml" -Method GET -Headers $headers -UseBasicParsing
    if ($mlRecResponse.StatusCode -eq 200) {
        $mlRec = $mlRecResponse.Content | ConvertFrom-Json
        Write-Host "  [OK] Recommandations ML récupérées" -ForegroundColor Green
        Write-Host "    - ROI prédit: $([math]::Round($mlRec.predicted_roi_years, 1)) ans" -ForegroundColor Gray
        Write-Host "    - Confiance: $($mlRec.confidence)" -ForegroundColor Gray
        if ($mlRec.recommendations) {
            Write-Host "    - Nombre de recommandations: $($mlRec.recommendations.Count)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  [ERREUR] Échec recommandations ML: $_" -ForegroundColor Red
    Write-Host "  [INFO] Vérifiez que l'AI microservice est démarré" -ForegroundColor Yellow
}

# [8] Test détection d'anomalies
Write-Host "`n[8] Test détection d'anomalies (IA)..." -ForegroundColor Yellow
try {
    $anomaliesResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments/$establishmentId/anomalies?days=7" -Method GET -Headers $headers -UseBasicParsing
    if ($anomaliesResponse.StatusCode -eq 200) {
        $anomalies = $anomaliesResponse.Content | ConvertFrom-Json
        Write-Host "  [OK] Données d'anomalies récupérées" -ForegroundColor Green
        if ($anomalies.statistics) {
            Write-Host "    - Total anomalies: $($anomalies.statistics.totalAnomalies)" -ForegroundColor Gray
            Write-Host "    - Anomalies consommation élevée: $($anomalies.statistics.highConsumptionAnomalies)" -ForegroundColor Gray
            Write-Host "    - Anomalies consommation faible: $($anomalies.statistics.lowConsumptionAnomalies)" -ForegroundColor Gray
            Write-Host "    - Anomalies PV: $($anomalies.statistics.pvMalfunctionAnomalies)" -ForegroundColor Gray
            Write-Host "    - Anomalies batterie: $($anomalies.statistics.batteryLowAnomalies)" -ForegroundColor Gray
            Write-Host "    - Score moyen: $([math]::Round($anomalies.statistics.averageAnomalyScore, 2))" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  [ERREUR] Échec détection anomalies: $_" -ForegroundColor Red
    Write-Host "  [INFO] Vérifiez que l'AI microservice est démarré" -ForegroundColor Yellow
}

# [9] Test clustering
Write-Host "`n[9] Test clustering (IA)..." -ForegroundColor Yellow
try {
    $clusterResponse = Invoke-WebRequest -Uri "$backendUrl/api/establishments/$establishmentId/cluster" -Method GET -Headers $headers -UseBasicParsing
    if ($clusterResponse.StatusCode -eq 200) {
        $cluster = $clusterResponse.Content | ConvertFrom-Json
        Write-Host "  [OK] Cluster récupéré" -ForegroundColor Green
        Write-Host "    - Cluster ID: $($cluster.cluster_id)" -ForegroundColor Gray
        Write-Host "    - Distance au centre: $([math]::Round($cluster.distance_to_center, 2))" -ForegroundColor Gray
        if ($cluster.message) {
            Write-Host "    - Message: $($cluster.message)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  [ERREUR] Échec clustering: $_" -ForegroundColor Red
    Write-Host "  [INFO] Vérifiez que l'AI microservice est démarré" -ForegroundColor Yellow
}

Write-Host "`n=== Tests Cas 2 terminés ===" -ForegroundColor Cyan
Write-Host "`nRésumé:" -ForegroundColor Yellow
Write-Host "  - Établissement ID: $establishmentId" -ForegroundColor Gray
Write-Host "  - Tous les endpoints backend testés" -ForegroundColor Gray
Write-Host "  - Fonctionnalités IA testées (si microservice démarré)" -ForegroundColor Gray
Write-Host "`nPour tester depuis le frontend:" -ForegroundColor Yellow
Write-Host "  1. Créer un établissement via le flow B1->B2->B3->B4->B5" -ForegroundColor White
Write-Host "  2. La page AI s'affichera automatiquement avec toutes les données" -ForegroundColor White


