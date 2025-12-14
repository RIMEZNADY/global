# Script pour arrêter les services
Write-Host "=== Arret des Services ===" -ForegroundColor Cyan
Write-Host ""

# Lire les PIDs sauvegardés
$pidsFile = "$PSScriptRoot\.services-pids.json"
if (Test-Path $pidsFile) {
    $pids = Get-Content $pidsFile | ConvertFrom-Json
    Write-Host "Arret des processus sauvegardes..." -ForegroundColor Yellow
    
    if ($pids.AI_PID) {
        try {
            Stop-Process -Id $pids.AI_PID -Force -ErrorAction Stop
            Write-Host "  [OK] AI Microservice arrete (PID: $($pids.AI_PID))" -ForegroundColor Green
        } catch {
            Write-Host "  [ERREUR] Impossible d'arreter AI Microservice (PID: $($pids.AI_PID))" -ForegroundColor Red
        }
    }
    
    if ($pids.Backend_PID) {
        try {
            Stop-Process -Id $pids.Backend_PID -Force -ErrorAction Stop
            Write-Host "  [OK] Backend Spring Boot arrete (PID: $($pids.Backend_PID))" -ForegroundColor Green
        } catch {
            Write-Host "  [ERREUR] Impossible d'arreter Backend (PID: $($pids.Backend_PID))" -ForegroundColor Red
        }
    }
    
    Remove-Item $pidsFile -ErrorAction SilentlyContinue
} else {
    Write-Host "Aucun fichier de PIDs trouve. Arret des processus par nom..." -ForegroundColor Yellow
    
    # Arrêter par nom de processus
    Get-Process | Where-Object {
        $_.ProcessName -eq "java" -or 
        ($_.ProcessName -eq "python" -and $_.CommandLine -like "*uvicorn*")
    } | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
            Write-Host "  [OK] Processus arrete: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Green
        } catch {
            Write-Host "  [ERREUR] Impossible d'arreter: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=== Arret termine ===" -ForegroundColor Cyan


