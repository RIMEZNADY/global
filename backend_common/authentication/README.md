# Module d'Authentification

Module d'authentification pour le système de microgrid hospitalier.

## Structure

```
authentication/
├── src/main/java/com/microgrid/authentication/
│   ├── controller/          # Contrôleurs REST
│   │   └── AuthController.java
│   ├── service/            # Services métier
│   │   ├── AuthService.java
│   │   └── UserService.java
│   ├── dto/                # Data Transfer Objects
│   │   ├── RegisterRequest.java
│   │   ├── LoginRequest.java
│   │   ├── AuthResponse.java
│   │   └── UserResponse.java
│   ├── security/           # Sécurité JWT
│   │   ├── JwtTokenProvider.java
│   │   ├── JwtAuthenticationFilter.java
│   │   └── CustomUserDetailsService.java
│   └── config/             # Configuration
│       └── SecurityConfig.java
└── pom.xml
```

## Fonctionnalités

### 1. Inscription (`POST /api/auth/register`)
- Création d'un nouvel utilisateur
- Hash du mot de passe avec BCrypt
- Génération d'un token JWT
- Retourne les informations utilisateur avec la liste des établissements (vide au départ)

### 2. Connexion (`POST /api/auth/login`)
- Authentification par email/mot de passe
- Génération d'un token JWT
- Retourne les informations utilisateur avec tous ses établissements

### 3. Profil utilisateur (`GET /api/auth/me`)
- Récupère les informations de l'utilisateur connecté
- Nécessite un token JWT valide dans le header `Authorization: Bearer <token>`
- Retourne la liste complète des établissements de l'utilisateur

## Sécurité

- **JWT (JSON Web Tokens)** : Authentification stateless
- **BCrypt** : Hash des mots de passe
- **Spring Security** : Configuration de sécurité
- **CORS** : Configuré pour Angular (4200) et Flutter (3000)

## Dépendances

Ce module utilise les modèles partagés :
- `com.microgrid.model.User`
- `com.microgrid.model.Establishment`
- `com.microgrid.repository.UserRepository`
- `com.microgrid.repository.EstablishmentRepository`

## Prochaines étapes

- [ ] Gestion des établissements (Cas 1 et Cas 2)
- [ ] Intégration avec le microservice AI
- [ ] Endpoints de simulation et recommandations


