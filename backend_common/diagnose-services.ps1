# Script de diagnostic des services
Write-Host "=== Diagnostic des Services ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier les processus Java
Write-Host "1. Processus Java (Spring Boot)..." -ForegroundColor Yellow
$javaProcesses = Get-Process | Where-Object {$_.ProcessName -eq "java"}
if ($javaProcesses) {
    Write-Host "   Processus Java trouves:" -ForegroundColor Green
    $javaProcesses | ForEach-Object {
        Write-Host "     - PID: $($_.Id), Memoire: $([math]::Round($_.WorkingSet64/1MB, 2)) MB" -ForegroundColor Gray
    }
} else {
    Write-Host "   Aucun processus Java trouve" -ForegroundColor Red
}
Write-Host ""

# Vérifier les processus Python
Write-Host "2. Processus Python (AI Microservice)..." -ForegroundColor Yellow
$pythonProcesses = Get-Process | Where-Object {$_.ProcessName -eq "python" -or $_.ProcessName -eq "pythonw"}
if ($pythonProcesses) {
    Write-Host "   Processus Python trouves:" -ForegroundColor Green
    $pythonProcesses | ForEach-Object {
        Write-Host "     - PID: $($_.Id), Memoire: $([math]::Round($_.WorkingSet64/1MB, 2)) MB" -ForegroundColor Gray
    }
} else {
    Write-Host "   Aucun processus Python trouve" -ForegroundColor Red
}
Write-Host ""

# Vérifier les ports
Write-Host "3. Ports en ecoute..." -ForegroundColor Yellow
$ports = netstat -ano | Select-String ":8000|:8080"
if ($ports) {
    Write-Host "   Ports actifs:" -ForegroundColor Green
    $ports | ForEach-Object {
        Write-Host "     $_" -ForegroundColor Gray
    }
} else {
    Write-Host "   Aucun port 8000 ou 8080 en ecoute" -ForegroundColor Red
}
Write-Host ""

# Tester les endpoints
Write-Host "4. Test des endpoints..." -ForegroundColor Yellow

# Test AI Microservice
Write-Host "   4.1 AI Microservice (http://localhost:8000/health)..." -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" `
        -Method GET `
        -UseBasicParsing `
        -TimeoutSec 3 `
        -ErrorAction Stop
    Write-Host "      [OK] Reponse: $($response.StatusCode)" -ForegroundColor Green
    $data = $response.Content | ConvertFrom-Json
    Write-Host "      Status: $($data.status)" -ForegroundColor Gray
} catch {
    Write-Host "      [ERREUR] $_" -ForegroundColor Red
}

# Test Backend
Write-Host "   4.2 Backend Spring Boot (http://localhost:8080/api/public/health)..." -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/public/health" `
        -Method GET `
        -UseBasicParsing `
        -TimeoutSec 3 `
        -ErrorAction Stop
    Write-Host "      [OK] Reponse: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "      [ERREUR] $_" -ForegroundColor Red
    Write-Host "      Essai avec /actuator/health..." -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" `
            -Method GET `
            -UseBasicParsing `
            -TimeoutSec 3 `
            -ErrorAction Stop
        Write-Host "      [OK] Actuator repond: $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "      [ERREUR] Actuator aussi inaccessible" -ForegroundColor Red
    }
}
Write-Host ""

# Vérifier les fichiers de configuration
Write-Host "5. Verification des fichiers..." -ForegroundColor Yellow
$backendExists = Test-Path "$PSScriptRoot\pom.xml"
$aiApiExists = Test-Path "$PSScriptRoot\..\ai_microservices\src\api.py"
Write-Host "   Backend pom.xml: $(if ($backendExists) { '[OK]' } else { '[MANQUANT]' })" -ForegroundColor $(if ($backendExists) { 'Green' } else { 'Red' })
Write-Host "   AI api.py: $(if ($aiApiExists) { '[OK]' } else { '[MANQUANT]' })" -ForegroundColor $(if ($aiApiExists) { 'Green' } else { 'Red' })
Write-Host ""

Write-Host "=== Diagnostic termine ===" -ForegroundColor Cyan


