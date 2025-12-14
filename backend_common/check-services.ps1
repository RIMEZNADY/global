# Script pour vérifier si les services sont démarrés
Write-Host "=== Verification des Services ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier Backend Spring Boot
Write-Host "1. Backend Spring Boot (http://localhost:8080)..." -ForegroundColor Yellow
$backendReady = $false
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/public/health" `
        -Method GET `
        -UseBasicParsing `
        -TimeoutSec 3 `
        -ErrorAction Stop
    Write-Host "   OK Backend demarre" -ForegroundColor Green
    $backendReady = $true
} catch {
    # Essayer avec un autre endpoint
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body '{"email":"test","password":"test"}' `
            -UseBasicParsing `
            -TimeoutSec 3 `
            -ErrorAction Stop
        Write-Host "   OK Backend demarre (endpoint auth accessible)" -ForegroundColor Green
        $backendReady = $true
    } catch {
        Write-Host "   ERREUR Backend non disponible" -ForegroundColor Red
        Write-Host "   Demarrer avec: cd backend_common && mvn spring-boot:run" -ForegroundColor Yellow
    }
}
Write-Host ""

# Vérifier AI Microservice
Write-Host "2. AI Microservice (http://localhost:8000)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" `
        -Method GET `
        -UseBasicParsing `
        -TimeoutSec 2 `
        -ErrorAction Stop
    $data = $response.Content | ConvertFrom-Json
    Write-Host "   OK AI Microservice demarre" -ForegroundColor Green
    Write-Host "     - Status: $($data.status)" -ForegroundColor Gray
    Write-Host "     - Model loaded: $($data.model_loaded)" -ForegroundColor Gray
} catch {
    Write-Host "   ERREUR AI Microservice non disponible" -ForegroundColor Red
    Write-Host "   Demarrer avec: cd ai_microservices && python -m uvicorn src.api:app --reload" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== Verification terminee ===" -ForegroundColor Cyan

