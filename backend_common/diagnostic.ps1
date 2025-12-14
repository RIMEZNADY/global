# Script de diagnostic pour identifier le problème

Write-Host "=== DIAGNOSTIC DU PROBLÈME ===" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier Docker PostgreSQL
Write-Host "1. Vérification Docker PostgreSQL..." -ForegroundColor Yellow
docker-compose ps postgres
Write-Host ""

# 2. Vérifier si la base de données existe
Write-Host "2. Vérification de la base de données..." -ForegroundColor Yellow
docker exec microgrid-postgres psql -U postgres -c "\l" | findstr microgrid
Write-Host ""

# 3. Vérifier si un PostgreSQL local utilise le port 5432
Write-Host "3. Vérification du port 5432..." -ForegroundColor Yellow
netstat -ano | findstr :5432
Write-Host ""

# 4. Tester la connexion à PostgreSQL Docker
Write-Host "4. Test de connexion à PostgreSQL Docker..." -ForegroundColor Yellow
docker exec microgrid-postgres psql -U postgres -d microgrid_db -c "SELECT 1;" 2>&1
Write-Host ""

# 5. Vérifier les variables d'environnement PostgreSQL
Write-Host "5. Variables d'environnement PostgreSQL..." -ForegroundColor Yellow
docker exec microgrid-postgres env | findstr POSTGRES
Write-Host ""

Write-Host "=== FIN DU DIAGNOSTIC ===" -ForegroundColor Cyan


