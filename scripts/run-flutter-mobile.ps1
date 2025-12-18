# Script pour lancer l'application Flutter sur l'émulateur Android
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LANCEMENT FLUTTER MOBILE APP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Aller dans le répertoire du projet Flutter
$flutterPath = Join-Path $PSScriptRoot "..\hospital-microgrid"
Set-Location $flutterPathimage.png

# Vérifier les appareils disponibles
Write-Host "Vérification des appareils disponibles..." -ForegroundColor Yellow
flutter devices
Write-Host ""

# Vérifier que l'émulateur est disponible
$devices = flutter devices 2>&1 | Select-String "emulator"
if (-not $devices) {
    Write-Host "Aucun émulateur détecté. Lancement d'un émulateur..." -ForegroundColor Yellow
    flutter emulators --launch SMG_Pixel_API_36
    Write-Host "Attente du démarrage de l'émulateur (30 secondes)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# Installer les dépendances
Write-Host "Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
Write-Host ""

# Nettoyer le build précédent (optionnel)
Write-Host "Nettoyage du build précédent..." -ForegroundColor Yellow
flutter clean
flutter pub get
Write-Host ""

# Lancer l'application
Write-Host "========================================" -ForegroundColor Green
Write-Host "  LANCEMENT DE L'APPLICATION" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "L'application va être compilée et installée sur l'émulateur..." -ForegroundColor Cyan
Write-Host "Cela peut prendre quelques minutes la première fois." -ForegroundColor Yellow
Write-Host ""

flutter run -d emulator-5554




