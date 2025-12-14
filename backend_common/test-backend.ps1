# Script PowerShell pour tester le démarrage du backend
Write-Host "=== Test du Backend Spring Boot ===" -ForegroundColor Cyan

# Vérifier PostgreSQL
Write-Host "`n1. Vérification de PostgreSQL..." -ForegroundColor Yellow
docker-compose ps postgres

# Vérifier la connexion à la base de données
Write-Host "`n2. Test de connexion à PostgreSQL..." -ForegroundColor Yellow
docker exec microgrid-postgres psql -U postgres -d microgrid_db -c "SELECT 1;" 2>&1

# Lancer le backend et capturer les logs
Write-Host "`n3. Lancement du backend (attendre 30 secondes)..." -ForegroundColor Yellow
Write-Host "Les logs vont s'afficher ci-dessous:" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

mvn spring-boot:run


