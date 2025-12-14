# Script de test pour les endpoints du Cas 1
Write-Host "=== Test des Endpoints Cas 1 ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$baseUrl = "http://localhost:8080"
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

# Fonction pour créer un établissement de test
function Create-TestEstablishment {
    param($token)
    
    try {
        $establishmentBody = @{
            name = "Hôpital Test Cas 1"
            type = "CHU"
            numberOfBeds = 200
            latitude = 33.5731
            longitude = -7.5898
            installableSurfaceM2 = 1000.0
            nonCriticalSurfaceM2 = 500.0
            monthlyConsumptionKwh = 50000.0
        } | ConvertTo-Json
        
        $headers = @{
            "Authorization" = "Bearer $token"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments" `
            -Method POST `
            -Headers $headers `
            -Body $establishmentBody `
            -UseBasicParsing `
            -ErrorAction Stop
        
        $data = $response.Content | ConvertFrom-Json
        return $data.id
    } catch {
        Write-Host "Erreur lors de la création de l'établissement: $_" -ForegroundColor Red
        Write-Host "Réponse: $($_.Exception.Response)" -ForegroundColor Yellow
        return $null
    }
}

# Étape 1: Connexion
Write-Host "1. Connexion..." -ForegroundColor Yellow
$token = Get-AuthToken -email $testEmail -password $testPassword

if ($null -eq $token) {
    Write-Host "   ⚠️  Impossible de se connecter. Tentative d'inscription..." -ForegroundColor Yellow
    
    # Essayer de s'inscrire
    try {
        $registerBody = @{
            email = $testEmail
            password = $testPassword
            firstName = "Test"
            lastName = "User"
            phone = "0612345678"
        } | ConvertTo-Json
        
        $registerResponse = Invoke-WebRequest -Uri "$baseUrl/api/auth/register" `
            -Method POST `
            -ContentType "application/json" `
            -Body $registerBody `
            -UseBasicParsing `
            -ErrorAction Stop
        
        Write-Host "   OK Inscription reussie" -ForegroundColor Green
        
        # Réessayer la connexion
        $token = Get-AuthToken -email $testEmail -password $testPassword
    } catch {
        Write-Host "   ✗ Erreur lors de l'inscription: $_" -ForegroundColor Red
        exit 1
    }
}

if ($null -eq $token) {
    Write-Host "   ✗ Impossible d'obtenir un token" -ForegroundColor Red
    exit 1
}

    Write-Host "   OK Token obtenu" -ForegroundColor Green
Write-Host ""

# Étape 2: Créer un établissement de test
Write-Host "2. Création d'un établissement de test..." -ForegroundColor Yellow
$establishmentId = Create-TestEstablishment -token $token

if ($null -eq $establishmentId) {
    # Essayer de récupérer un établissement existant
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
        if ($establishments.Count -gt 0) {
            $establishmentId = $establishments[0].id
            Write-Host "   OK Utilisation d'un etablissement existant (ID: $establishmentId)" -ForegroundColor Green
        } else {
            Write-Host "   ✗ Aucun établissement trouvé" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "   ✗ Erreur: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   OK Etablissement cree (ID: $establishmentId)" -ForegroundColor Green
}
Write-Host ""

# Étape 3: Test GET /api/establishments/{id}/recommendations
Write-Host "3. Test GET /api/establishments/$establishmentId/recommendations" -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments/$establishmentId/recommendations" `
        -Method GET `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - Puissance PV recommandée: $($data.recommendedPvPowerKwc) kWc" -ForegroundColor Gray
    Write-Host "     - Surface PV recommandée: $($data.recommendedPvSurfaceM2) m²" -ForegroundColor Gray
    Write-Host "     - Capacité batterie recommandée: $($data.recommendedBatteryCapacityKwh) kWh" -ForegroundColor Gray
    Write-Host "     - Autonomie estimée: $($data.estimatedEnergyAutonomy) %" -ForegroundColor Gray
    Write-Host "     - Économies annuelles: $($data.estimatedAnnualSavings) DH" -ForegroundColor Gray
    Write-Host "     - ROI: $($data.estimatedROI) années" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Erreur: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Réponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

# Étape 4: Test GET /api/establishments/{id}/savings
Write-Host "4. Test GET /api/establishments/$establishmentId/savings" -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $token"
    }
    
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments/$establishmentId/savings?electricityPriceDhPerKwh=1.2" `
        -Method GET `
        -Headers $headers `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - Consommation annuelle: $($data.annualConsumption) kWh" -ForegroundColor Gray
    Write-Host "     - Énergie PV annuelle: $($data.annualPvEnergy) kWh" -ForegroundColor Gray
    Write-Host "     - Économies annuelles: $($data.annualSavings) DH" -ForegroundColor Gray
    Write-Host "     - Autonomie: $($data.autonomyPercentage) %" -ForegroundColor Gray
    Write-Host "     - Facture annuelle après PV: $($data.annualBillAfterPv) DH" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Erreur: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Réponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

# Étape 5: Test POST /api/establishments/{id}/simulate
Write-Host "5. Test POST /api/establishments/$establishmentId/simulate" -ForegroundColor Yellow
try {
    $simulationBody = @{
        startDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
        days = 7
        batteryCapacityKwh = 500.0
        initialSocKwh = 250.0
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    Write-Host "   Envoi de la requête..." -ForegroundColor Gray
    $response = Invoke-WebRequest -Uri "$baseUrl/api/establishments/$establishmentId/simulate" `
        -Method POST `
        -Headers $headers `
        -Body $simulationBody `
        -UseBasicParsing `
        -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK Succes" -ForegroundColor Green
    Write-Host "     - Nombre de pas de simulation: $($data.steps.Count)" -ForegroundColor Gray
    Write-Host "     - Total consommation: $($data.summary.totalConsumption) kWh" -ForegroundColor Gray
    Write-Host "     - Total production PV: $($data.summary.totalPvProduction) kWh" -ForegroundColor Gray
    Write-Host "     - Total import réseau: $($data.summary.totalGridImport) kWh" -ForegroundColor Gray
    Write-Host "     - Autonomie moyenne: $($data.summary.averageAutonomy) %" -ForegroundColor Gray
    Write-Host "     - Économies totales: $($data.summary.totalSavings) DH" -ForegroundColor Gray
    
    if ($data.steps.Count -gt 0) {
        Write-Host "     - Premier pas:" -ForegroundColor Gray
        Write-Host "       * Date: $($data.steps[0].datetime)" -ForegroundColor Gray
        Write-Host "       * Consommation: $($data.steps[0].predictedConsumption) kWh" -ForegroundColor Gray
        Write-Host "       * Production PV: $($data.steps[0].pvProduction) kWh" -ForegroundColor Gray
        Write-Host "       * SOC batterie: $($data.steps[0].socBattery) kWh" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ Erreur: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "     Réponse: $responseBody" -ForegroundColor Yellow
    }
}
Write-Host ""

Write-Host "=== Tests terminés ===" -ForegroundColor Cyan

