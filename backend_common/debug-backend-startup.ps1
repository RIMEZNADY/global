# Script pour diagnostiquer le problème de démarrage du backend
Write-Host "=== Diagnostic Demarrage Backend ===" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier la compilation
Write-Host "1. Compilation..." -ForegroundColor Yellow
mvn clean compile -q 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   [OK] Compilation reussie" -ForegroundColor Green
} else {
    Write-Host "   [ERREUR] Echec de compilation" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. Vérifier le port
Write-Host "2. Port 8080..." -ForegroundColor Yellow
$port8080 = netstat -ano | findstr ":8080"
if ($port8080) {
    Write-Host "   [ATTENTION] Port 8080 deja utilise:" -ForegroundColor Yellow
    Write-Host "   $port8080" -ForegroundColor Gray
} else {
    Write-Host "   [OK] Port 8080 libre" -ForegroundColor Green
}
Write-Host ""

# 3. Vérifier PostgreSQL
Write-Host "3. PostgreSQL..." -ForegroundColor Yellow
$postgres = docker ps | findstr postgres
if ($postgres) {
    Write-Host "   [OK] PostgreSQL en cours d'execution" -ForegroundColor Green
} else {
    Write-Host "   [ERREUR] PostgreSQL non demarre" -ForegroundColor Red
    Write-Host "   Demarrer avec: docker-compose up -d" -ForegroundColor Yellow
}
Write-Host ""

# 4. Vérifier le microservice AI
Write-Host "4. Microservice AI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" `
        -Method GET `
        -UseBasicParsing `
        -TimeoutSec 2 `
        -ErrorAction Stop
    Write-Host "   [OK] Microservice AI accessible" -ForegroundColor Green
} catch {
    Write-Host "   [ATTENTION] Microservice AI non accessible (peut bloquer le demarrage)" -ForegroundColor Yellow
    Write-Host "   Le backend peut demarrer sans, mais certains services ne fonctionneront pas" -ForegroundColor Gray
}
Write-Host ""

# 5. Tester le démarrage avec logs
Write-Host "5. Test de demarrage (10 secondes)..." -ForegroundColor Yellow
Write-Host "   Lancement en arriere-plan pour voir les erreurs..." -ForegroundColor Gray

$job = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    mvn spring-boot:run 2>&1 | Select-Object -First 50
}

Start-Sleep -Seconds 10

$output = Receive-Job -Job $job
Stop-Job -Job $job
Remove-Job -Job $job

Write-Host "   Sortie du demarrage:" -ForegroundColor Gray
$output | Select-String -Pattern "ERROR|Exception|Failed|Started|Tomcat" | Select-Object -First 15

Write-Host ""
Write-Host "=== Diagnostic termine ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Si le backend ne demarre pas, verifiez:" -ForegroundColor Yellow
Write-Host "  1. Les logs dans le terminal du backend" -ForegroundColor Gray
Write-Host "  2. La connexion a PostgreSQL (port 5433)" -ForegroundColor Gray
Write-Host "  3. Les erreurs de configuration Spring" -ForegroundColor Gray
Write-Host "  4. Les dependances manquantes" -ForegroundColor Gray


