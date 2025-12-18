# Script pour lancer le projet complet sur Chrome
# Frontend Flutter/Next.js + Backend + AI Microservices

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LANCEMENT PROJET SUR CHROME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $rootDir "backend_common"
$aiDir = Join-Path $rootDir "ai_microservices"
$frontendDir = Join-Path $rootDir "hospital-microgrid"

# Fonction pour vérifier si un port est utilisé
function Test-Port {
    param([int]$Port)
    $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet
    return $connection
}

# 1. Vérifier et démarrer PostgreSQL
Write-Host "1. Vérification PostgreSQL..." -ForegroundColor Yellow
$postgresRunning = docker ps --filter "name=microgrid-postgres" --format "{{.Names}}" 2>$null
if ($postgresRunning -eq "microgrid-postgres") {
    Write-Host "   ✓ PostgreSQL déjà en cours d'exécution" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Démarrage de PostgreSQL..." -ForegroundColor Yellow
    Set-Location $backendDir
    docker-compose up -d postgres
    Start-Sleep -Seconds 5
    Write-Host "   ✓ PostgreSQL démarré" -ForegroundColor Green
}

# 2. Démarrer le microservice AI (FastAPI)
Write-Host ""
Write-Host "2. Démarrage AI Microservice (port 8000)..." -ForegroundColor Yellow
if (Test-Port -Port 8000) {
    Write-Host "   ✓ AI Microservice déjà en cours d'exécution" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Installation des dépendances Python si nécessaire..." -ForegroundColor Gray
    Set-Location $aiDir
    if (Test-Path "requirements.txt") {
        python -m pip install -q -r requirements.txt 2>$null
    }
    
    Write-Host "   ⚠ Démarrage du microservice AI..." -ForegroundColor Gray
    $aiCommand = "Set-Location '$aiDir'; Write-Host 'AI Microservice (FastAPI) - Port 8000' -ForegroundColor Cyan; python -m uvicorn src.api:app --host 0.0.0.0 --port 8000 --reload"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $aiCommand -WindowStyle Minimized
    Start-Sleep -Seconds 3
    Write-Host "   ✓ AI Microservice démarré" -ForegroundColor Green
}

# 3. Démarrer le Backend Spring Boot
Write-Host ""
Write-Host "3. Démarrage Backend Spring Boot (port 8080)..." -ForegroundColor Yellow
if (Test-Port -Port 8080) {
    Write-Host "   ✓ Backend déjà en cours d'exécution" -ForegroundColor Green
} else {
    Set-Location $backendDir
    Write-Host "   ⚠ Démarrage du backend (cela peut prendre 1-2 minutes)..." -ForegroundColor Gray
    
    # Vérifier si mvnw existe
    if (Test-Path "mvnw.cmd") {
        $backendCommand = "Set-Location '$backendDir'; Write-Host 'Backend Spring Boot - Port 8080' -ForegroundColor Cyan; .\mvnw.cmd spring-boot:run"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCommand -WindowStyle Minimized
    } elseif (Test-Path "mvnw") {
        $backendCommand = "Set-Location '$backendDir'; Write-Host 'Backend Spring Boot - Port 8080' -ForegroundColor Cyan; .\mvnw spring-boot:run"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCommand -WindowStyle Minimized
    } else {
        $backendCommand = "Set-Location '$backendDir'; Write-Host 'Backend Spring Boot - Port 8080' -ForegroundColor Cyan; mvn spring-boot:run"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCommand -WindowStyle Minimized
    }
    Start-Sleep -Seconds 5
    Write-Host "   ✓ Backend démarré (en cours de compilation...) " -ForegroundColor Green
}

# 4. Attendre que les services backend soient prêts
Write-Host ""
Write-Host "4. Attente du démarrage des services backend (30 secondes)..." -ForegroundColor Yellow
$maxAttempts = 15
$attempt = 0
$aiReady = $false
$backendReady = $false

while ($attempt -lt $maxAttempts -and (-not $aiReady -or -not $backendReady)) {
    Start-Sleep -Seconds 2
    $attempt++
    
    if (-not $aiReady -and (Test-Port -Port 8000)) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop 2>$null
            $aiReady = $true
            Write-Host "   ✓ AI Microservice prêt" -ForegroundColor Green
        } catch {
            # Pas encore prêt
        }
    }
    
    if (-not $backendReady -and (Test-Port -Port 8080)) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/api/public/health" -Method GET -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop 2>$null
            $backendReady = $true
            Write-Host "   ✓ Backend Spring Boot prêt" -ForegroundColor Green
        } catch {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -Method GET -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop 2>$null
                $backendReady = $true
                Write-Host "   ✓ Backend Spring Boot prêt" -ForegroundColor Green
            } catch {
                # Pas encore prêt
            }
        }
    }
    if ($attempt % 5 -eq 0 -and ($attempt -lt $maxAttempts)) {
        Write-Host "   Tentative $attempt/$maxAttempts..." -ForegroundColor Gray
    }
}

# 5. Démarrer le Frontend Flutter Web
Write-Host ""
Write-Host "5. Démarrage Frontend Flutter Web sur Chrome..." -ForegroundColor Yellow
Set-Location $frontendDir

# Vérifier que c'est un projet Flutter
if (Test-Path "pubspec.yaml") {
    Write-Host "   ⚠ Installation des dépendances Flutter..." -ForegroundColor Gray
    flutter pub get
    
    Write-Host "   ⚠ Démarrage Flutter Web (port 3000)..." -ForegroundColor Gray
    $frontendCommand = "Set-Location '$frontendDir'; Write-Host 'Frontend Flutter Web - Chrome' -ForegroundColor Cyan; flutter run -d chrome --web-port=3000"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCommand -WindowStyle Normal
    Start-Sleep -Seconds 8
    
    Write-Host "   ✓ Frontend Flutter Web démarré" -ForegroundColor Green
    Write-Host ""
    Write-Host "   🌐 Ouverture de Chrome..." -ForegroundColor Cyan
    Start-Process "chrome.exe" "http://localhost:3000"
    $frontendUrl = "http://localhost:3000"
} else {
    Write-Host "   ✗ Aucun projet Flutter détecté (pubspec.yaml manquant)" -ForegroundColor Red
    $frontendUrl = $null
}

# Résumé final
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  SERVICES DÉMARRÉS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "✓ PostgreSQL:     localhost:5434" -ForegroundColor Green
Write-Host "✓ AI Microservice: http://localhost:8000" -ForegroundColor Green
Write-Host "✓ Backend:         http://localhost:8080" -ForegroundColor Green
if ($frontendUrl) {
    Write-Host "✓ Frontend:        $frontendUrl" -ForegroundColor Green
}
Write-Host ""
Write-Host "Les fenêtres PowerShell restent ouvertes pour voir les logs." -ForegroundColor White
Write-Host "Pour arrêter les services, fermez les fenêtres PowerShell." -ForegroundColor White
Write-Host ""
if ($frontendUrl) {
    Write-Host "Le navigateur Chrome devrait s'ouvrir automatiquement." -ForegroundColor Cyan
    Write-Host "Sinon, ouvrez manuellement dans Chrome: $frontendUrl" -ForegroundColor Yellow
}
Write-Host ""

