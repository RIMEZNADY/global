# Script pour lancer tous les services
Write-Host "=== LANCEMENT DE TOUS LES SERVICES ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier PostgreSQL
Write-Host "1. Vérification PostgreSQL..." -ForegroundColor Yellow
$postgres = docker ps --filter "name=microgrid-postgres" --format "{{.Names}}" 2>$null
if ($postgres -eq "microgrid-postgres") {
    Write-Host "   ✓ PostgreSQL déjà en cours d'exécution" -ForegroundColor Green
} else {
    Write-Host "   ⚠ PostgreSQL non détecté. Lancement..." -ForegroundColor Yellow
    docker start microgrid-postgres 2>$null
    Start-Sleep -Seconds 2
}

# Lancer Backend Spring Boot
Write-Host "2. Lancement Backend Spring Boot (port 8080)..." -ForegroundColor Yellow
$backendProcess = Get-Process | Where-Object { $_.CommandLine -like "*spring-boot:run*" -or ($_.ProcessName -eq "java" -and (netstat -ano | findstr ":8080" | findstr "LISTENING")) }
if (-not $backendProcess) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { Set-Location '$PWD\backend_common'; .\mvnw.cmd spring-boot:run }" -WindowStyle Minimized
    Write-Host "   ✓ Backend lancé dans une nouvelle fenêtre" -ForegroundColor Green
    Start-Sleep -Seconds 5
} else {
    Write-Host "   ✓ Backend déjà en cours d'exécution" -ForegroundColor Green
}

# Lancer Microservice IA
Write-Host "3. Lancement Microservice IA (port 8000)..." -ForegroundColor Yellow
$aiProcess = Get-Process | Where-Object { $_.ProcessName -eq "python" -and (netstat -ano | findstr ":8000" | findstr "LISTENING") }
if (-not $aiProcess) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { Set-Location '$PWD\ai_microservices'; python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload }" -WindowStyle Minimized
    Write-Host "   ✓ Microservice IA lancé dans une nouvelle fenêtre" -ForegroundColor Green
    Start-Sleep -Seconds 3
} else {
    Write-Host "   ✓ Microservice IA déjà en cours d'exécution" -ForegroundColor Green
}

# Lancer Frontend Flutter
Write-Host "4. Lancement Frontend Flutter (port 3000)..." -ForegroundColor Yellow
$frontendPath = Join-Path $PWD "frontend_flutter_mobile\hospital-microgrid"
if (Test-Path $frontendPath) {
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "& { Set-Location '$frontendPath'; flutter run -d chrome --web-port=3000 }" -WindowStyle Normal
    Write-Host "   ✓ Frontend lancé dans une nouvelle fenêtre" -ForegroundColor Green
    Write-Host "   ℹ Le navigateur s'ouvrira automatiquement sur http://localhost:3000" -ForegroundColor Cyan
} else {
    Write-Host "   ✗ Chemin frontend non trouvé: $frontendPath" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== ATTENTE DU DÉMARRAGE (15 secondes) ===" -ForegroundColor Cyan
Start-Sleep -Seconds 15

# Vérification finale
Write-Host ""
Write-Host "=== ÉTAT FINAL DES SERVICES ===" -ForegroundColor Cyan
Write-Host "Backend (8080):" -NoNewline
try {
    $r = Invoke-WebRequest -Uri http://localhost:8080/actuator/health -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    Write-Host " ✓ OK" -ForegroundColor Green
} catch {
    try {
        $r = Invoke-WebRequest -Uri http://localhost:8080/api/health -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        Write-Host " ✓ OK" -ForegroundColor Green
    } catch {
        Write-Host " ⚠ Port ouvert mais endpoint non accessible" -ForegroundColor Yellow
    }
}

Write-Host "IA Service (8000):" -NoNewline
try {
    $r = Invoke-WebRequest -Uri http://localhost:8000/health -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    Write-Host " ✓ OK" -ForegroundColor Green
} catch {
    Write-Host " ⚠ Port ouvert mais endpoint non accessible" -ForegroundColor Yellow
}

Write-Host "Frontend (3000):" -NoNewline
try {
    $r = Invoke-WebRequest -Uri http://localhost:3000 -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
    Write-Host " ✓ OK - Ouvrez http://localhost:3000 dans votre navigateur" -ForegroundColor Green
} catch {
    Write-Host " ⚠ En cours de démarrage..." -ForegroundColor Yellow
    Write-Host "   → Essayez d'ouvrir http://localhost:3000 dans votre navigateur" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=== SERVICES LANCÉS ===" -ForegroundColor Green
Write-Host "Les fenêtres PowerShell resteront ouvertes pour voir les logs." -ForegroundColor White
Write-Host "Pour arrêter, fermez les fenêtres PowerShell ou utilisez stop-services.ps1" -ForegroundColor White

