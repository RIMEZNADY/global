# Script pour démarrer les services
Write-Host "=== Demarrage des Services ===" -ForegroundColor Cyan
Write-Host ""

# Fonction pour démarrer le microservice AI
function Start-AIMicroservice {
    Write-Host "1. Demarrage AI Microservice (Python)..." -ForegroundColor Yellow
    
    $aiProcess = Start-Process -FilePath "python" `
        -ArgumentList "-m", "uvicorn", "src.api:app", "--reload", "--host", "0.0.0.0", "--port", "8000" `
        -WorkingDirectory "$PSScriptRoot\..\ai_microservices" `
        -WindowStyle Minimized `
        -PassThru
    
    Write-Host "   Processus demarre (PID: $($aiProcess.Id))" -ForegroundColor Gray
    return $aiProcess
}

# Fonction pour démarrer le backend Spring Boot
function Start-SpringBootBackend {
    Write-Host "2. Demarrage Backend Spring Boot..." -ForegroundColor Yellow
    
    $backendProcess = Start-Process -FilePath "mvn" `
        -ArgumentList "spring-boot:run" `
        -WorkingDirectory "$PSScriptRoot" `
        -WindowStyle Minimized `
        -PassThru
    
    Write-Host "   Processus demarre (PID: $($backendProcess.Id))" -ForegroundColor Gray
    return $backendProcess
}

# Démarrer les services
$aiProcess = Start-AIMicroservice
Start-Sleep -Seconds 2
$backendProcess = Start-SpringBootBackend

Write-Host ""
Write-Host "Services en cours de demarrage..." -ForegroundColor Yellow
Write-Host "  - AI Microservice PID: $($aiProcess.Id)" -ForegroundColor Gray
Write-Host "  - Backend Spring Boot PID: $($backendProcess.Id)" -ForegroundColor Gray
Write-Host ""
Write-Host "Attente de 30 secondes pour le demarrage complet..." -ForegroundColor Yellow

# Attendre et vérifier
$maxAttempts = 15
$attempt = 0
$aiReady = $false
$backendReady = $false

while ($attempt -lt $maxAttempts -and (-not $aiReady -or -not $backendReady)) {
    Start-Sleep -Seconds 2
    $attempt++
    
    # Vérifier AI Microservice
    if (-not $aiReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/health" `
                -Method GET `
                -UseBasicParsing `
                -TimeoutSec 2 `
                -ErrorAction Stop
            $aiReady = $true
            Write-Host "  [OK] AI Microservice pret" -ForegroundColor Green
        } catch {
            # Pas encore prêt
        }
    }
    
    # Vérifier Backend
    if (-not $backendReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/api/public/health" `
                -Method GET `
                -UseBasicParsing `
                -TimeoutSec 2 `
                -ErrorAction Stop
            $backendReady = $true
            Write-Host "  [OK] Backend Spring Boot pret" -ForegroundColor Green
        } catch {
            # Pas encore prêt
        }
    }
    
    if ($attempt % 5 -eq 0) {
        Write-Host "  Tentative $attempt/$maxAttempts..." -ForegroundColor Gray
    }
}

Write-Host ""
if ($aiReady -and $backendReady) {
    Write-Host "=== Tous les services sont pret! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pour arreter les services:" -ForegroundColor Yellow
    Write-Host "  Stop-Process -Id $($aiProcess.Id)" -ForegroundColor Gray
    Write-Host "  Stop-Process -Id $($backendProcess.Id)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Ou utiliser: .\stop-services.ps1" -ForegroundColor Gray
} else {
    Write-Host "=== Attention ===" -ForegroundColor Yellow
    if (-not $aiReady) {
        Write-Host "  AI Microservice n'est pas pret" -ForegroundColor Red
    }
    if (-not $backendReady) {
        Write-Host "  Backend Spring Boot n'est pas pret" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Verifiez les logs des processus." -ForegroundColor Yellow
}

# Sauvegarder les PIDs pour arrêt ultérieur
@{
    AI_PID = $aiProcess.Id
    Backend_PID = $backendProcess.Id
} | ConvertTo-Json | Out-File "$PSScriptRoot\.services-pids.json"


