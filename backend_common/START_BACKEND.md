# Instructions pour lancer le Backend

## 1. Lancer PostgreSQL avec Docker

```bash
cd backend
docker-compose up -d
```

Vérifier que PostgreSQL est lancé :
```bash
docker-compose ps
```

## 2. Lancer le Backend Spring Boot

**Option A : Avec Maven (recommandé)**
```bash
cd backend
mvn spring-boot:run
```

**Option B : Avec le JAR compilé**
```bash
cd backend
java -jar target/microgrid-backend-1.0.0.jar
```

## 3. Vérifier que le backend fonctionne

Le backend devrait démarrer sur `http://localhost:8080`

Vous devriez voir dans les logs :
```
Started MicrogridBackendApplication in X.XXX seconds
```

## 4. Tester l'API

Une fois le backend lancé, testez l'inscription depuis le frontend ou avec curl :

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","firstName":"Test","lastName":"User"}'
```

## Problèmes courants

### Le backend ne démarre pas
- Vérifiez que PostgreSQL est lancé : `docker-compose ps`
- Vérifiez les logs : `docker-compose logs postgres`
- Vérifiez les logs du backend dans le terminal

### Erreur de connexion à la base de données
- Vérifiez que PostgreSQL est accessible : `docker-compose ps`
- Vérifiez les credentials dans `application.properties`

### Port 8080 déjà utilisé
- Changez le port dans `application.properties` : `server.port=8081`
- Ou arrêtez l'application qui utilise le port 8080


