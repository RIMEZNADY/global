# Script de test pour les endpoints Phase 2 et graphiques anomalies
Write-Host "=== Test des Endpoints Phase 2 ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$baseUrl = "http://localhost:8080"
$aiUrl = "http://localhost:8000"
$testEmail = "test@example.com"
$testPassword = "password123"

# Fonction pour obtenir le token JWT
function Get-AuthToken {
    param($email, $password)
    
    try {
        $loginBody = @{
            email = $email
            password = $password
        } | ConvertTo-Json
        
        $loginResponse = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $loginBody `
            -UseBasicParsing `
            -ErrorAction Stop
        
        $loginData = $loginResponse.Content | ConvertFrom-Json
        return $loginData.token
    } catch {
        Write-Host "Erreur lors de la connexion: $_" -ForegroundColor Red
        return $null
    }
}

# Étape 1: Connexion
Write-Host "1. Connexion..." -ForegroundColor Yellow
$token = Get-AuthToken -email $testEmail -password $testPassword

if ($null -eq $token) {
    Write-Host "   ERREUR Impossible de se connecter" -ForegroundColor Red
    exit 1
}

Write-Host "   OK Token obtenu" -ForegroundColor Green
Write-Host ""

# Étape 2: Obtenir un établissement
Write-Host "2. Recuperation d'un etablissement..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments" `
        -Method GET `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $establishments = $response.Content | ConvertFrom-Json
    if ($establishments.Count -eq 0) {
        Write-Host "   ERREUR Aucun etablissement trouve" -ForegroundColor Red
        exit 1
    }
    
    $establishmentId = $establishments[0].id
    Write-Host "   OK Etablissement trouve (ID: $establishmentId)" -ForegroundColor Green
} catch {
    Write-Host "   ERREUR: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Étape 3: Test Clustering
Write-Host "3. Test POST $aiUrl/cluster/establishments" -ForegroundColor Yellow
try {
    $clusterBody = @{
        establishment_type = "CHU"
        number_of_beds = 200
        monthly_consumption = 50000.0
        installable_surface = 1000.0
        irradiation_class = "C"
        latitude = 33.5731
        longitude = -7.5898
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$aiUrl/cluster/establishments" `
        -Method POST `
        -ContentType "application/json" `
        -Body $clusterBody `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - Cluster ID: $($data.cluster_id)" -ForegroundColor Gray
    Write-Host "     - Distance au centre: $($data.distance_to_center)" -ForegroundColor Gray
} catch {
    Write-Host "   ERREUR: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Reponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

# Étape 4: Test Recommandations ML
Write-Host "4. Test GET /api/establishments/$establishmentId/recommendations/ml" -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments/$establishmentId/recommendations/ml" `
        -Method GET `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - ROI predit: $($data.predicted_roi_years) annees" -ForegroundColor Gray
    Write-Host "     - Confiance: $($data.confidence)" -ForegroundColor Gray
    Write-Host "     - Nombre de recommandations: $($data.recommendations.Count)" -ForegroundColor Gray
    if ($data.recommendations.Count -gt 0) {
        Write-Host "     - Premiere recommandation: $($data.recommendations[0].message)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ERREUR: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Reponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

# Étape 5: Test Prédiction Long Terme
Write-Host "5. Test GET /api/establishments/$establishmentId/forecast" -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments/$establishmentId/forecast?horizonDays=7" `
        -Method GET `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - Nombre de predictions: $($data.predictions.Count)" -ForegroundColor Gray
    Write-Host "     - Tendance: $($data.trend)" -ForegroundColor Gray
    Write-Host "     - Methode: $($data.method)" -ForegroundColor Gray
    if ($data.predictions.Count -gt 0) {
        Write-Host "     - Jour 1:" -ForegroundColor Gray
        Write-Host "       * Consommation predite: $($data.predictions[0].predictedConsumption) kWh" -ForegroundColor Gray
        Write-Host "       * Production PV predite: $($data.predictions[0].predictedPvProduction) kWh" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ERREUR: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Reponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

# Étape 6: Test Graphique Anomalies
Write-Host "6. Test GET /api/establishments/$establishmentId/anomalies" -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments/$establishmentId/anomalies?days=7" `
        -Method GET `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - Nombre de points de donnees: $($data.anomalies.Count)" -ForegroundColor Gray
    Write-Host "     - Total anomalies detectees: $($data.statistics.totalAnomalies)" -ForegroundColor Gray
    Write-Host "     - Anomalies consommation elevee: $($data.statistics.highConsumptionAnomalies)" -ForegroundColor Gray
    Write-Host "     - Anomalies PV: $($data.statistics.pvMalfunctionAnomalies)" -ForegroundColor Gray
    Write-Host "     - Anomalies batterie: $($data.statistics.batteryLowAnomalies)" -ForegroundColor Gray
    Write-Host "     - Type le plus frequent: $($data.statistics.mostCommonAnomalyType)" -ForegroundColor Gray
    Write-Host "     - Score moyen: $($data.statistics.averageAnomalyScore)" -ForegroundColor Gray
    
    # Afficher quelques anomalies si présentes
    $anomalyCount = 0
    foreach ($anomaly in $data.anomalies) {
        if ($anomaly.isAnomaly -eq $true) {
            $anomalyCount++
            if ($anomalyCount -le 3) {
                Write-Host "     - Anomalie #$anomalyCount : $($anomaly.anomalyType) a $($anomaly.datetime)" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "   ERREUR: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Reponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

# Étape 7: Test Simulation avec Anomalies
Write-Host "7. Test POST /api/establishments/$establishmentId/simulate (avec anomalies)" -ForegroundColor Yellow
try {
    $simulationBody = @{
        startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        days = 3
        batteryCapacityKwh = 500.0
        initialSocKwh = 250.0
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "   Envoi de la requete..." -ForegroundColor Gray
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments/$establishmentId/simulate" `
        -Method POST `
        -Headers $headers `
        -Body $simulationBody `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - Nombre de pas de simulation: $($data.steps.Count)" -ForegroundColor Gray
    
    # Compter les anomalies
    $anomalyCount = 0
    foreach ($step in $data.steps) {
        if ($step.hasAnomaly -eq $true) {
            $anomalyCount++
        }
    }
    Write-Host "     - Anomalies detectees dans la simulation: $anomalyCount" -ForegroundColor Gray
    
    if ($anomalyCount -gt 0) {
        Write-Host "     - Exemples d'anomalies:" -ForegroundColor Yellow
        $shown = 0
        foreach ($step in $data.steps) {
            if ($step.hasAnomaly -eq $true -and $shown -lt 2) {
                Write-Host "       * $($step.datetime): $($step.anomalyType) - $($step.anomalyRecommendation)" -ForegroundColor Yellow
                $shown++
            }
        }
    }
} catch {
    Write-Host "   ERREUR: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Reponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

# Étape 8: Test Endpoints AI directement
Write-Host "8. Test endpoints AI directement..." -ForegroundColor Yellow

# Test /recommendations/ml
Write-Host "   8.1 POST $aiUrl/recommendations/ml" -ForegroundColor Gray
try {
    $mlRecBody = @{
        establishment_type = "CHU"
        number_of_beds = 200
        monthly_consumption = 50000.0
        installable_surface = 1000.0
        irradiation_class = "C"
        recommended_pv_power = 3000.0
        recommended_battery = 4333.0
        autonomy = 43.2
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$aiUrl/recommendations/ml" `
        -Method POST `
        -ContentType "application/json" `
        -Body $mlRecBody `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "      OK ROI predit: $($data.predicted_roi_years) annees" -ForegroundColor Green
} catch {
    Write-Host "      ERREUR: $_" -ForegroundColor Red
}
Write-Host ""

# Test /predict/longterm
Write-Host "   8.2 POST $aiUrl/predict/longterm" -ForegroundColor Gray
try {
    $historicalData = @(
        @{consumption = 500.0; pv_production = 200.0; temperature = 20.0; irradiance = 2.5},
        @{consumption = 480.0; pv_production = 180.0; temperature = 19.0; irradiance = 2.3},
        @{consumption = 520.0; pv_production = 220.0; temperature = 21.0; irradiance = 2.7}
    )
    
    $longtermBody = @{
        historical_data = $historicalData
        horizon_days = 7
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$aiUrl/predict/longterm" `
        -Method POST `
        -ContentType "application/json" `
        -Body $longtermBody `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "      OK Predictions: $($data.predictions.Count) jours, tendance: $($data.trend)" -ForegroundColor Green
} catch {
    Write-Host "      ERREUR: $_" -ForegroundColor Red
}
Write-Host ""

# Test /detect/anomalies
Write-Host "   8.3 POST $aiUrl/detect/anomalies" -ForegroundColor Gray
try {
    $anomalyBody = @{
        consumption = 600.0
        predicted_consumption = 500.0
        pv_production = 150.0
        expected_pv = 300.0
        soc = 100.0
        temperature_C = 25.0
        irradiance_kWh_m2 = 2.5
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest -Uri "$aiUrl/detect/anomalies" `
        -Method POST `
        -ContentType "application/json" `
        -Body $anomalyBody `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "      OK Anomalie detectee: $($data.is_anomaly), type: $($data.anomaly_type)" -ForegroundColor Green
    if ($data.is_anomaly) {
        Write-Host "        Recommendation: $($data.recommendation)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      ERREUR: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Tests termines ===" -ForegroundColor Cyan


