# Microgrid Backend - Spring Boot

Backend principal pour le système de microgrid hospitalier. Ce backend interagit avec le microservice AI (Python/FastAPI) et le frontend Flutter/Angular.

## Technologies

- **Spring Boot 3.2.0**
- **PostgreSQL** (Base de données)
- **Spring Security** (Authentification JWT)
- **Spring Data JPA** (ORM)
- **Maven** (Gestion des dépendances)

## Structure du projet

```
backend/
├── src/main/java/com/microgrid/
│   ├── MicrogridBackendApplication.java
│   ├── model/                          (User, Establishment)
│   ├── repository/                     (UserRepository, EstablishmentRepository)
│   └── authentication/                (Module d'authentification)
│       ├── controller/
│       ├── service/
│       ├── dto/
│       ├── security/
│       └── config/
├── authentication/                    (Organisation de référence)
│   └── README.md
├── pom.xml
└── src/main/resources/
    └── application.properties
```

## Configuration

### Base de données PostgreSQL

1. Installer PostgreSQL
2. Créer la base de données :
```sql
CREATE DATABASE microgrid_db;
```

3. Configurer les credentials dans `src/main/resources/application.properties` :
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/microgrid_db
spring.datasource.username=postgres
spring.datasource.password=postgres
```

## Installation et exécution

### Prérequis
- Java 17+
- Maven 3.6+
- PostgreSQL 12+

### Lancer l'application

```bash
# Installer les dépendances
mvn clean install

# Lancer l'application
mvn spring-boot:run
```

L'application sera accessible sur `http://localhost:8080`

## API Endpoints

### Authentification

#### POST `/api/auth/register`
Inscription d'un nouvel utilisateur

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+212612345678"
}
```

**Response:**
```json
{
  "token": "jwt_token_here",
  "type": "Bearer",
  "userId": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "establishments": []
}
```

#### POST `/api/auth/login`
Connexion d'un utilisateur

**Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:** (même format que register)

#### GET `/api/auth/me`
Récupérer les informations de l'utilisateur connecté

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+212612345678",
  "role": "USER",
  "active": true,
  "createdAt": "2024-01-01T10:00:00",
  "establishments": [
    {
      "id": 1,
      "name": "CHU Casablanca",
      "type": "CHU",
      "status": "ACTIVE",
      "createdAt": "2024-01-01T10:00:00"
    }
  ]
}
```

## Intégration Frontend

Voir [INTEGRATION_FRONTEND.md](./INTEGRATION_FRONTEND.md) pour les détails d'intégration avec le frontend Flutter.

## Prochaines étapes

- [x] Authentification (login/register)
- [ ] Endpoints pour la gestion des établissements (Cas 1 et Cas 2)
- [ ] Intégration avec le microservice AI
- [ ] Endpoints de simulation et recommandations
- [ ] Calculs de ROI et économies
