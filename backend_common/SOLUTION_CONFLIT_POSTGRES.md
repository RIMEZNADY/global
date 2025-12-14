# Solution au Conflit PostgreSQL

## Problème Identifié

Il y a **DEUX** instances PostgreSQL qui tournent :
1. **PostgreSQL local** (PID 6704) sur le port 5432
2. **PostgreSQL Docker** (conteneur microgrid-postgres) sur le port 5432

Le backend Spring Boot se connecte probablement au PostgreSQL local qui n'a pas la base de données `microgrid_db`.

## Solutions

### Solution 1 : Arrêter le PostgreSQL Local (Recommandé)

```powershell
# Arrêter le service PostgreSQL local
Stop-Service -Name postgresql-x64-18

# Vérifier qu'il est arrêté
Get-Service -Name postgresql-x64-18
```

Ensuite, relancez le backend :
```powershell
mvn spring-boot:run
```

### Solution 2 : Changer le Port Docker PostgreSQL

Si vous avez besoin du PostgreSQL local, changez le port Docker :

1. Modifiez `docker-compose.yml` :
```yaml
ports:
  - "5433:5432"  # Au lieu de 5432:5432
```

2. Modifiez `application.properties` :
```properties
spring.datasource.url=jdbc:postgresql://localhost:5433/microgrid_db
```

3. Redémarrez Docker :
```powershell
docker-compose down
docker-compose up -d
```

### Solution 3 : Utiliser le PostgreSQL Local

Si vous préférez utiliser le PostgreSQL local :

1. Créez la base de données :
```sql
CREATE DATABASE microgrid_db;
```

2. Vérifiez que le mot de passe est "root" dans `application.properties`

## Vérification

Après avoir appliqué une solution, vérifiez que le backend démarre :
```powershell
mvn spring-boot:run
```

Vous devriez voir :
```
Started MicrogridBackendApplication in X.XXX seconds
```


