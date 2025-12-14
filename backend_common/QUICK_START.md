# Démarrage Rapide du Backend

## 1. Créer la base de données PostgreSQL

**Option A : Via pgAdmin (recommandé)**
1. Ouvrez pgAdmin
2. Connectez-vous à PostgreSQL
3. Clic droit sur "Databases" → "Create" → "Database"
4. Nom : `microgrid_db`
5. Propriétaire : `postgres`
6. Cliquez sur "Save"

**Option B : Via SQL**
```sql
CREATE DATABASE microgrid_db;
```

## 2. Vérifier la configuration

Vérifiez que les credentials dans `src/main/resources/application.properties` sont corrects :
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/microgrid_db
spring.datasource.username=postgres
spring.datasource.password=postgres
```

## 3. Lancer le backend

```bash
cd backend
mvn spring-boot:run
```

Le backend sera accessible sur `http://localhost:8080`

## 4. Vérifier que ça fonctionne

Ouvrez un navigateur et allez sur :
- `http://localhost:8080/api/auth/register` (devrait retourner une erreur 405 car c'est un POST, mais ça confirme que le serveur répond)

Ou testez avec curl :
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","firstName":"Test","lastName":"User"}'
```

## Problèmes courants

### Erreur : "Connection refused" ou "Failed to fetch"
- Vérifiez que PostgreSQL est lancé
- Vérifiez que la base de données `microgrid_db` existe
- Vérifiez les credentials dans `application.properties`

### Erreur : "Database does not exist"
- Créez la base de données (voir étape 1)

### Le backend ne démarre pas
- Vérifiez les logs dans le terminal
- Vérifiez que Java 17+ est installé
- Vérifiez que Maven est installé


