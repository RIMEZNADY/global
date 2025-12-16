# Script pour lancer tous les services (Backend + AI + Flutter Mobile)
Write-Host "=== LANCEMENT DE TOUS LES SERVICES ===" -ForegroundColor Cyan
Write-Host ""

# Definir le repertoire de base (remonter d'un niveau depuis scripts/)
$scriptDir = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { Split-Path $PWD -Parent }
Set-Location $scriptDir

# Verifier PostgreSQL
Write-Host "1. Verification PostgreSQL..." -ForegroundColor Yellow
$postgres = docker ps --filter "name=microgrid-postgres" --format "{{.Names}}" 2>$null
if ($postgres -eq "microgrid-postgres") {
    Write-Host "   [OK] PostgreSQL deja en cours d'execution" -ForegroundColor Green
} else {
    Write-Host "   [INFO] PostgreSQL non detecte. Lancement..." -ForegroundColor Yellow
    $dockerComposePath = Join-Path $scriptDir "backend_common\docker-compose.yml"
    if (Test-Path $dockerComposePath) {
        $backendDir = Join-Path $scriptDir "backend_common"
        Set-Location $backendDir
        docker-compose up -d
        Start-Sleep -Seconds 3
        Set-Location $scriptDir
        Write-Host "   [OK] PostgreSQL lance" -ForegroundColor Green
    } else {
        Write-Host "   [ERREUR] docker-compose.yml non trouve" -ForegroundColor Red
    }
}

# Lancer Backend Spring Boot
Write-Host ""
Write-Host "2. Lancement Backend Spring Boot (port 8080)..." -ForegroundColor Yellow
$backendPort = netstat -ano | findstr ":8080" | findstr "LISTENING"
if ($backendPort) {
    Write-Host "   [OK] Backend deja en cours d'execution sur le port 8080" -ForegroundColor Green
} else {
    $backendPath = Join-Path $scriptDir "backend_common"
    if (Test-Path $backendPath) {
        $command = "Set-Location '$backendPath'; Write-Host '=== BACKEND SPRING BOOT ===' -ForegroundColor Cyan; mvn spring-boot:run"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $command -WindowStyle Normal
        Write-Host "   [OK] Backend lance dans une nouvelle fenetre" -ForegroundColor Green
        Write-Host "   [INFO] Attente du demarrage (15 secondes)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    } else {
        Write-Host "   [ERREUR] Dossier backend_common non trouve" -ForegroundColor Red
    }
}

# Lancer Microservice IA
Write-Host ""
Write-Host "3. Lancement Microservice IA (port 8000)..." -ForegroundColor Yellow
$aiPort = netstat -ano | findstr ":8000" | findstr "LISTENING"
if ($aiPort) {
    Write-Host "   [OK] Microservice IA deja en cours d'execution sur le port 8000" -ForegroundColor Green
} else {
    $aiPath = Join-Path $scriptDir "ai_microservices"
    if (Test-Path $aiPath) {
        # Verifier si main.py ou src/api.py existe
        $apiFile = if (Test-Path (Join-Path $aiPath "main.py")) { "main:app" } else { "src.api:app" }
        $command = "Set-Location '$aiPath'; Write-Host '=== AI MICROSERVICE ===' -ForegroundColor Cyan; python -m uvicorn $apiFile --host 0.0.0.0 --port 8000 --reload"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $command -WindowStyle Normal
        Write-Host "   [OK] Microservice IA lance dans une nouvelle fenetre" -ForegroundColor Green
        Write-Host "   [INFO] Attente du demarrage (5 secondes)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } else {
        Write-Host "   [ERREUR] Dossier ai_microservices non trouve" -ForegroundColor Red
    }
}

# Lancer Frontend Flutter Web
Write-Host ""
Write-Host "4. Lancement Frontend Flutter Web (localhost)..." -ForegroundColor Yellow
$flutterPath = Join-Path $scriptDir "hospital-microgrid"
if (Test-Path $flutterPath) {
    $command = "Set-Location '$flutterPath'; Write-Host '=== FLUTTER WEB APP ===' -ForegroundColor Cyan; flutter run -d chrome --web-port=3000"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $command -WindowStyle Normal
    Write-Host "   [OK] Application Flutter lancee en mode web sur http://localhost:3000" -ForegroundColor Green
    Write-Host "   [INFO] Le navigateur s'ouvrira automatiquement" -ForegroundColor Cyan
} else {
    Write-Host "   [ERREUR] Chemin frontend non trouve: $flutterPath" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== ATTENTE DU DEMARRAGE COMPLET (20 secondes) ===" -ForegroundColor Cyan
Start-Sleep -Seconds 20

# Verification finale
Write-Host ""
Write-Host "=== ETAT FINAL DES SERVICES ===" -ForegroundColor Cyan

# Backend
Write-Host "Backend (8080):" -NoNewline
try {
    $r = Invoke-WebRequest -Uri http://localhost:8080/actuator/health -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    Write-Host " [OK]" -ForegroundColor Green
} catch {
    try {
        $r = Invoke-WebRequest -Uri http://localhost:8080/api/public/health -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        $port = netstat -ano | findstr ":8080" | findstr "LISTENING"
        if ($port) {
            Write-Host " [WARN] Port ouvert mais endpoint non accessible" -ForegroundColor Yellow
        } else {
            Write-Host " [ERREUR] Non accessible" -ForegroundColor Red
        }
    }
}

# AI Service
Write-Host "IA Service (8000):" -NoNewline
try {
    $r = Invoke-WebRequest -Uri http://localhost:8000/health -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    Write-Host " [OK]" -ForegroundColor Green
} catch {
    $port = netstat -ano | findstr ":8000" | findstr "LISTENING"
    if ($port) {
        Write-Host " [WARN] Port ouvert mais endpoint non accessible" -ForegroundColor Yellow
    } else {
        Write-Host " [ERREUR] Non accessible" -ForegroundColor Red
    }
}

# PostgreSQL
Write-Host "PostgreSQL (5434):" -NoNewline
$postgres = docker ps --filter "name=microgrid-postgres" --format "{{.Names}}" 2>$null
if ($postgres -eq "microgrid-postgres") {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [ERREUR] Non accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SERVICES LANCES ===" -ForegroundColor Green
Write-Host "Les fenetres PowerShell resteront ouvertes pour voir les logs." -ForegroundColor White
Write-Host ""
Write-Host "URLs des services :" -ForegroundColor Cyan
Write-Host "  - Frontend Flutter: http://localhost:3000" -ForegroundColor White
Write-Host "  - Backend API: http://localhost:8080" -ForegroundColor White
Write-Host "  - AI Microservice: http://localhost:8000" -ForegroundColor White
Write-Host "  - PostgreSQL: localhost:5434" -ForegroundColor White
Write-Host ""
Write-Host "Pour arreter les services, fermez les fenetres PowerShell ou utilisez stop-services.ps1" -ForegroundColor White






