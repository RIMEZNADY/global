# Structure du Projet Backend

## Organisation

Le code d'authentification est organisé dans le dossier `authentication/` pour une meilleure clarté, mais les fichiers source doivent être dans `src/main/java/com/microgrid/authentication/` pour que Spring Boot les trouve.

## Structure actuelle

```
backend/
├── src/main/java/com/microgrid/
│   ├── MicrogridBackendApplication.java  (classe principale)
│   ├── model/                            (User, Establishment)
│   ├── repository/                      (UserRepository, EstablishmentRepository)
│   └── authentication/                  (Module d'authentification)
│       ├── controller/
│       │   └── AuthController.java
│       ├── service/
│       │   ├── AuthService.java
│       │   └── UserService.java
│       ├── dto/
│       │   ├── RegisterRequest.java
│       │   ├── LoginRequest.java
│       │   ├── AuthResponse.java
│       │   └── UserResponse.java
│       ├── security/
│       │   ├── JwtTokenProvider.java
│       │   ├── JwtAuthenticationFilter.java
│       │   └── CustomUserDetailsService.java
│       └── config/
│           └── SecurityConfig.java
├── authentication/                      (Organisation du code - référence)
│   └── src/main/java/com/microgrid/authentication/
│       └── (mêmes fichiers)
├── pom.xml
└── src/main/resources/
    └── application.properties
```

## Note importante

Les fichiers dans `backend/authentication/src/main/java/` sont une organisation de référence.
**Les fichiers actifs doivent être dans `backend/src/main/java/com/microgrid/authentication/`**

Si les fichiers ne sont pas déjà dans le bon emplacement, copiez-les depuis:
- `backend/authentication/src/main/java/com/microgrid/authentication/`
vers:
- `backend/src/main/java/com/microgrid/authentication/`

## Packages

- `com.microgrid` - Package principal
- `com.microgrid.authentication` - Module d'authentification
- `com.microgrid.model` - Modèles JPA (User, Establishment)
- `com.microgrid.repository` - Repositories JPA

## Configuration Spring Boot

La classe principale `MicrogridBackendApplication` scanne les packages:
- `com.microgrid`
- `com.microgrid.authentication`

Cela permet à Spring Boot de trouver tous les composants d'authentification.


