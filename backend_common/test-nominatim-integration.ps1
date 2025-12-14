# Script PowerShell pour tester l'intégration Nominatim
# Teste l'endpoint d'estimation de population avec différentes villes marocaines

$baseUrl = "http://localhost:8080/api/location"

Write-Host "=== Test de l'intégration OpenStreetMap Nominatim ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Casablanca (grande ville)
Write-Host "Test 1: Casablanca (33.5731, -7.5898)" -ForegroundColor Yellow
$url1 = "$baseUrl/estimate-population?latitude=33.5731&longitude=-7.5898&establishmentType=CHU&numberOfBeds=500"
try {
    $response1 = Invoke-RestMethod -Uri $url1 -Method Get -ContentType "application/json"
    Write-Host "  Population estimée: $($response1.estimatedPopulation)" -ForegroundColor Green
    Write-Host "  Type établissement: $($response1.establishmentType)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  Erreur: $_" -ForegroundColor Red
    Write-Host ""
}

# Test 2: Rabat (ville moyenne)
Write-Host "Test 2: Rabat (34.0209, -6.8416)" -ForegroundColor Yellow
$url2 = "$baseUrl/estimate-population?latitude=34.0209&longitude=-6.8416&establishmentType=HOPITAL_REGIONAL&numberOfBeds=300"
try {
    $response2 = Invoke-RestMethod -Uri $url2 -Method Get -ContentType "application/json"
    Write-Host "  Population estimée: $($response2.estimatedPopulation)" -ForegroundColor Green
    Write-Host "  Type établissement: $($response2.establishmentType)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  Erreur: $_" -ForegroundColor Red
    Write-Host ""
}

# Test 3: Marrakech (grande ville du Sud)
Write-Host "Test 3: Marrakech (31.6295, -7.9811)" -ForegroundColor Yellow
$url3 = "$baseUrl/estimate-population?latitude=31.6295&longitude=-7.9811&establishmentType=HOPITAL_REGIONAL&numberOfBeds=400"
try {
    $response3 = Invoke-RestMethod -Uri $url3 -Method Get -ContentType "application/json"
    Write-Host "  Population estimée: $($response3.estimatedPopulation)" -ForegroundColor Green
    Write-Host "  Type établissement: $($response3.establishmentType)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  Erreur: $_" -ForegroundColor Red
    Write-Host ""
}

# Test 4: Petite ville (Kénitra)
Write-Host "Test 4: Kénitra (34.2611, -6.5802)" -ForegroundColor Yellow
$url4 = "$baseUrl/estimate-population?latitude=34.2611&longitude=-6.5802&establishmentType=CENTRE_SANTE_PRIMAIRE&numberOfBeds=50"
try {
    $response4 = Invoke-RestMethod -Uri $url4 -Method Get -ContentType "application/json"
    Write-Host "  Population estimée: $($response4.estimatedPopulation)" -ForegroundColor Green
    Write-Host "  Type établissement: $($response4.establishmentType)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  Erreur: $_" -ForegroundColor Red
    Write-Host ""
}

# Test 5: Sans type d'établissement (devrait utiliser la valeur par défaut)
Write-Host "Test 5: Casablanca sans type d'établissement" -ForegroundColor Yellow
$url5 = "$baseUrl/estimate-population?latitude=33.5731&longitude=-7.5898"
try {
    $response5 = Invoke-RestMethod -Uri $url5 -Method Get -ContentType "application/json"
    Write-Host "  Population estimée: $($response5.estimatedPopulation)" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "  Erreur: $_" -ForegroundColor Red
    Write-Host ""
}

Write-Host "=== Tests terminés ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Si les valeurs proviennent de Nominatim, elles seront les populations réelles."
Write-Host "Sinon, ce sont des estimations basées sur la zone solaire et le type d'établissement."
