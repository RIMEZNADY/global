# Configuration Docker pour le Backend

## Prérequis

- Docker Desktop installé et lancé
- Docker Compose installé (inclus avec Docker Desktop)

## Lancer PostgreSQL avec Docker

### 1. Lancer PostgreSQL

```bash
cd backend
docker-compose up -d
```

Cette commande va :
- Télécharger l'image PostgreSQL 15 (si nécessaire)
- Créer un conteneur nommé `microgrid-postgres`
- Créer automatiquement la base de données `microgrid_db`
- Exposer PostgreSQL sur le port 5432

### 2. Vérifier que PostgreSQL est lancé

```bash
docker-compose ps
```

Vous devriez voir le conteneur `microgrid-postgres` avec le statut "Up".

### 3. Vérifier les logs

```bash
docker-compose logs postgres
```

### 4. Arrêter PostgreSQL

```bash
docker-compose down
```

Pour supprimer aussi les volumes (⚠️ supprime les données) :
```bash
docker-compose down -v
```

## Configuration du Backend

Le backend Spring Boot est configuré pour se connecter à PostgreSQL sur `localhost:5432`.

La configuration dans `application.properties` est déjà correcte :
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/microgrid_db
spring.datasource.username=postgres
spring.datasource.password=postgres
```

## Lancer le Backend

Une fois PostgreSQL lancé avec Docker :

```bash
cd backend
mvn spring-boot:run
```

Le backend sera accessible sur `http://localhost:8080`

## Commandes utiles

### Voir les logs PostgreSQL
```bash
docker-compose logs -f postgres
```

### Se connecter à PostgreSQL depuis Docker
```bash
docker exec -it microgrid-postgres psql -U postgres -d microgrid_db
```

### Redémarrer PostgreSQL
```bash
docker-compose restart postgres
```

### Voir l'état des conteneurs
```bash
docker-compose ps
```

## Avantages de Docker

✅ Pas besoin d'installer PostgreSQL localement
✅ Configuration isolée
✅ Facile à démarrer/arrêter
✅ Données persistantes dans un volume Docker
✅ Même environnement pour tous les développeurs


