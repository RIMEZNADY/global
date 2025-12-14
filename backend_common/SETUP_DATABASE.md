# Configuration de la Base de Données PostgreSQL

## Créer la base de données

Vous devez créer la base de données `microgrid_db` avant de lancer le backend.

### Option 1 : Via pgAdmin
1. Ouvrez pgAdmin
2. Connectez-vous à votre serveur PostgreSQL
3. Clic droit sur "Databases" → "Create" → "Database"
4. Nom : `microgrid_db`
5. Cliquez sur "Save"

### Option 2 : Via ligne de commande (si psql est dans le PATH)
```sql
CREATE DATABASE microgrid_db;
```

### Option 3 : Via PowerShell (si vous avez accès à psql)
```powershell
# Trouver le chemin de psql
$psqlPath = Get-ChildItem -Path "C:\Program Files\PostgreSQL" -Recurse -Filter "psql.exe" | Select-Object -First 1

# Créer la base de données
& $psqlPath -U postgres -c "CREATE DATABASE microgrid_db;"
```

## Configuration

Une fois la base de données créée, les tables seront créées automatiquement par Hibernate au premier démarrage du backend grâce à :
```properties
spring.jpa.hibernate.ddl-auto=update
```

## Vérifier la connexion

Le backend devrait démarrer sur `http://localhost:8080` une fois la base de données créée.


