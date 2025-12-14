# Comment lancer le Backend

## Étape 1 : Lancer PostgreSQL avec Docker

```powershell
cd backend
docker-compose up -d
```

Vérifier que PostgreSQL est lancé :
```powershell
docker-compose ps
```

Vous devriez voir `microgrid-postgres` avec le statut `Up (healthy)`

## Étape 2 : Lancer le Backend

**Ouvrez un NOUVEAU terminal** (important pour voir les logs) :

```powershell
cd backend
mvn spring-boot:run
```

## Étape 3 : Vérifier que le backend démarre

Vous devriez voir dans les logs :
```
Started MicrogridBackendApplication in X.XXX seconds
```

**Si vous voyez des erreurs**, copiez-les et partagez-les.

## Étape 4 : Tester l'API

Une fois le backend lancé, testez depuis le frontend ou avec curl :

```powershell
curl -X POST http://localhost:8080/api/auth/register `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"test@test.com\",\"password\":\"test123\",\"firstName\":\"Test\",\"lastName\":\"User\"}'
```

## Problèmes courants

### Le backend s'arrête immédiatement
- Vérifiez les logs dans le terminal
- Vérifiez que PostgreSQL est lancé : `docker-compose ps`
- Vérifiez les erreurs de connexion à la base de données

### Erreur "Connection refused"
- Vérifiez que PostgreSQL est lancé
- Vérifiez que le port 5432 n'est pas utilisé par un autre service

### Erreur "Database does not exist"
- La base de données est créée automatiquement par Docker
- Vérifiez avec : `docker exec microgrid-postgres psql -U postgres -c "\l"`


