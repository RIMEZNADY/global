# Script simplifie pour lancer tous les services sur Chrome
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEMARRAGE DES SERVICES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $rootDir "backend_common"
$aiDir = Join-Path $rootDir "ai_microservices"
$frontendDir = Join-Path $rootDir "hospital-microgrid"

# 1. PostgreSQL
Write-Host "[1/4] PostgreSQL..." -ForegroundColor Yellow
$postgres = docker ps --filter "name=microgrid-postgres" --format "{{.Names}}" 2>$null
if ($postgres -ne "microgrid-postgres") {
    Set-Location $backendDir
    docker-compose up -d postgres
    Start-Sleep -Seconds 3
}
Write-Host "  OK" -ForegroundColor Green

# 2. AI Microservice
Write-Host "[2/4] AI Microservice (port 8000)..." -ForegroundColor Yellow
Set-Location $aiDir
$aiCmd = "cd '$aiDir'; python -m uvicorn src.api:app --host 0.0.0.0 --port 8000 --reload"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $aiCmd
Start-Sleep -Seconds 2
Write-Host "  OK" -ForegroundColor Green

# 3. Backend Spring Boot
Write-Host "[3/4] Backend Spring Boot (port 8080)..." -ForegroundColor Yellow
Set-Location $backendDir
if (Test-Path "mvnw.cmd") {
    $backendCmd = "cd '$backendDir'; .\mvnw.cmd spring-boot:run"
} else {
    $backendCmd = "cd '$backendDir'; mvn spring-boot:run"
}
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd
Start-Sleep -Seconds 2
Write-Host "  OK" -ForegroundColor Green

# 4. Frontend Flutter Web
Write-Host "[4/4] Frontend Flutter Web..." -ForegroundColor Yellow
Set-Location $frontendDir

if (Test-Path "pubspec.yaml") {
    Write-Host "  Installation des dependances Flutter..." -ForegroundColor Gray
    flutter pub get
    Write-Host "  Demarrage Flutter Web sur Chrome..." -ForegroundColor Gray
    $frontendCmd = "cd '$frontendDir'; flutter run -d chrome --web-port=3000"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd
    Start-Sleep -Seconds 8
    Write-Host "  Ouverture de Chrome..." -ForegroundColor Gray
    Start-Process "chrome.exe" "http://localhost:3000"
    Write-Host "  OK - Flutter Web sur http://localhost:3000" -ForegroundColor Green
} else {
    Write-Host "  ERREUR: pubspec.yaml non trouve - Ce n'est pas un projet Flutter!" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  SERVICES DEMARRES" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Attendez 30-60 secondes que les services demarrent..." -ForegroundColor Yellow
Write-Host ""
Write-Host "URLs:" -ForegroundColor Cyan
Write-Host "  Frontend:  http://localhost:3000" -ForegroundColor White
Write-Host "  Backend:   http://localhost:8080" -ForegroundColor White
Write-Host "  AI Service: http://localhost:8000" -ForegroundColor White
Write-Host ""
Write-Host "Chrome devrait s'ouvrir automatiquement." -ForegroundColor Cyan
Write-Host "Si ce n'est pas le cas, ouvrez: http://localhost:3000" -ForegroundColor Yellow
Write-Host ""

