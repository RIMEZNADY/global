# Script simplifié pour lancer le projet sur Chrome
# Exécutez ce script depuis la racine du projet

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LANCEMENT PROJET SUR CHROME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Join-Path $PSScriptRoot "scripts\run-on-chrome.ps1"
if (Test-Path $scriptPath) {
    & powershell -ExecutionPolicy Bypass -File $scriptPath
} else {
    Write-Host "Erreur: Script non trouve: $scriptPath" -ForegroundColor Red
}



