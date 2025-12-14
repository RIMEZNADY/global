# Script de test pour l'endpoint de localisation
Write-Host "=== Test de l'endpoint de localisation ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Casablanca (Classe C)
Write-Host "Test 1: Casablanca (33.5731, -7.5898) - Attendu: Classe C" -ForegroundColor Yellow
try {
    $uri = "http://localhost:8080/api/location/irradiation?latitude=33.5731&longitude=-7.5898"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "Succès: Classe d'irradiation = $($data.irradiationClass)" -ForegroundColor Green
    if ($data.nearestCity) {
        Write-Host "  Ville la plus proche: $($data.nearestCity.name) - $($data.nearestCity.region)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Marrakech (Classe B)
Write-Host "Test 2: Marrakech (31.6295, -7.9811) - Attendu: Classe B" -ForegroundColor Yellow
try {
    $uri = "http://localhost:8080/api/location/irradiation?latitude=31.6295&longitude=-7.9811"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "Succès: Classe d'irradiation = $($data.irradiationClass)" -ForegroundColor Green
    if ($data.nearestCity) {
        Write-Host "  Ville la plus proche: $($data.nearestCity.name) - $($data.nearestCity.region)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Ouarzazate (Classe A)
Write-Host "Test 3: Ouarzazate (30.9333, -6.9167) - Attendu: Classe A" -ForegroundColor Yellow
try {
    $uri = "http://localhost:8080/api/location/irradiation?latitude=30.9333&longitude=-6.9167"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "Succès: Classe d'irradiation = $($data.irradiationClass)" -ForegroundColor Green
    if ($data.nearestCity) {
        Write-Host "  Ville la plus proche: $($data.nearestCity.name) - $($data.nearestCity.region)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: Tanger (Classe D)
Write-Host "Test 4: Tanger (35.7595, -5.8340) - Attendu: Classe D" -ForegroundColor Yellow
try {
    $uri = "http://localhost:8080/api/location/irradiation?latitude=35.7595&longitude=-5.8340"
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing
    $data = $response.Content | ConvertFrom-Json
    Write-Host "Succès: Classe d'irradiation = $($data.irradiationClass)" -ForegroundColor Green
    if ($data.nearestCity) {
        Write-Host "  Ville la plus proche: $($data.nearestCity.name) - $($data.nearestCity.region)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "=== Tests terminés ===" -ForegroundColor Cyan

