# Explication du Diagramme de Classes - SMART MICROGRID

## 1. Vue d'ensemble

Le diagramme de classes présenté modélise l'architecture logicielle du système SMART MICROGRID en mettant en évidence les principales classes, leurs relations et leur organisation en couches. Ce diagramme illustre la structure interne du système, montrant comment les différentes composantes interagissent pour réaliser les fonctionnalités décrites dans le diagramme de cas d'utilisation.

## 2. Architecture en couches

Le système suit une architecture en couches classique, organisée en trois niveaux principaux :

### 2.1. Couche Présentation (Controllers)
Cette couche contient les contrôleurs qui gèrent les requêtes HTTP entrantes et les réponses :

- **AuthController** : Gère les requêtes d'authentification (inscription, connexion, gestion du profil utilisateur).
- **EstablishmentController** : Traite les opérations CRUD sur les établissements et la récupération des résultats complets.
- **LocationController** : Gère les requêtes liées aux données géographiques (classe d'irradiation, estimation de population).

### 2.2. Couche Métier (Services)
Cette couche encapsule la logique métier de l'application :

- **AuthService** : Implémente la logique d'authentification et de gestion des utilisateurs.
- **EstablishmentService** : Gère les opérations métier sur les établissements (création, modification, suppression, consultation).
- **ComprehensiveResultsService** : Orchestre le calcul et l'agrégation des résultats complets pour un établissement donné.
- **LocationService** : Fournit des services liés à la géolocalisation (détermination de l'irradiation solaire, estimation de population).
- **CalculationServices** : Groupe de services spécialisés dans les calculs :
  - `SizingService` : Calcule le dimensionnement optimal des équipements solaires.
  - `SimulationService` : Simule le comportement énergétique du microgrid.
  - `PvCalculationService` : Calcule la production photovoltaïque.
- **AIServices** : Groupe de services utilisant l'intelligence artificielle :
  - `MlRecommendationService` : Fournit des recommandations basées sur l'apprentissage automatique.
  - `PredictionService` : Génère des prédictions à long terme.
  - `AnomalyDetectionService` : Détecte les anomalies dans les données de consommation.

### 2.3. Couche Accès aux Données (Repositories)
Cette couche abstrait l'accès aux données :

- **UserRepository** : Interface pour les opérations de persistance sur les utilisateurs.
- **EstablishmentRepository** : Interface pour les opérations de persistance sur les établissements.

## 3. Entités du domaine (Models)

Les entités représentent les concepts métier fondamentaux du système :

### 3.1. User (Utilisateur)
Représente un utilisateur du système (manager, ingénieur, responsable d'établissement). Les attributs principaux incluent :
- Identifiant unique
- Email et mot de passe pour l'authentification
- Prénom et nom

### 3.2. Establishment (Établissement)
Représente un établissement médical géré par le système. Les attributs principaux incluent :
- Identifiant unique
- Nom et type d'établissement
- Coordonnées géographiques (latitude, longitude)
- Consommation mensuelle en kWh

## 4. Composants externes

### 4.1. AiMicroserviceClient
Client permettant de communiquer avec un microservice externe d'intelligence artificielle. Ce composant est utilisé par :
- Les services du groupe `AIServices` pour obtenir des prédictions et recommandations ML
- Le `LocationService` pour certaines fonctionnalités avancées de géolocalisation

## 5. Relations entre les classes

### 5.1. Relation d'association User - Establishment
- **Type** : Composition/Aggrégation (1 à plusieurs)
- **Description** : Un utilisateur peut posséder et gérer plusieurs établissements. Cette relation est représentée par un losange noir, indiquant une relation forte où un établissement appartient à un utilisateur.

### 5.2. Relations de dépendance Controllers → Services
Les contrôleurs dépendent des services pour exécuter la logique métier :
- `AuthController` utilise `AuthService` et `UserRepository`
- `EstablishmentController` utilise `EstablishmentService` et `ComprehensiveResultsService`
- `LocationController` utilise `LocationService`

### 5.3. Relations de dépendance Services → Repositories
Les services utilisent les repositories pour accéder aux données :
- `EstablishmentService` utilise `EstablishmentRepository` pour persister et récupérer les établissements

### 5.4. Relations de dépendance entre Services
Les services peuvent dépendre d'autres services pour réaliser leurs fonctionnalités :
- `ComprehensiveResultsService` orchestre les `CalculationServices` et les `AIServices` pour générer des résultats complets
- Les services du groupe `AIServices` utilisent `AiMicroserviceClient` pour communiquer avec le microservice IA externe
- `LocationService` utilise également `AiMicroserviceClient` pour certaines fonctionnalités avancées

### 5.5. Relations de réalisation Repositories → Entities
Les repositories gèrent les instances des entités :
- `UserRepository` gère les instances de `User`
- `EstablishmentRepository` gère les instances de `Establishment`

## 6. Principes de conception appliqués

### 6.1. Séparation des responsabilités
Chaque couche a une responsabilité claire et bien définie :
- Les contrôleurs gèrent uniquement les requêtes HTTP
- Les services encapsulent la logique métier
- Les repositories gèrent l'accès aux données

### 6.2. Inversion de dépendances
Les services dépendent d'interfaces (repositories) plutôt que d'implémentations concrètes, facilitant les tests et la maintenance.

### 6.3. Regroupement fonctionnel
Les services similaires sont regroupés (`CalculationServices`, `AIServices`) pour améliorer la lisibilité et montrer les domaines fonctionnels.

### 6.4. Intégration de services externes
L'utilisation d'un client dédié (`AiMicroserviceClient`) pour communiquer avec le microservice IA externe permet une intégration propre et découplée.

## 7. Flux de données typique

Un flux de données typique dans le système suit cette séquence :

1. **Requête HTTP** : Un utilisateur envoie une requête via le frontend.
2. **Controller** : Le contrôleur approprié reçoit la requête.
3. **Service** : Le contrôleur délègue la logique métier au service correspondant.
4. **Repository** : Le service utilise le repository pour accéder aux données si nécessaire.
5. **Services spécialisés** : Pour des calculs complexes, le service peut faire appel à d'autres services (calculs, IA).
6. **Microservice externe** : Si nécessaire, les services IA communiquent avec le microservice externe via `AiMicroserviceClient`.
7. **Réponse** : Le résultat remonte la chaîne jusqu'au contrôleur qui renvoie la réponse HTTP.

## 8. Points clés du diagramme

- **Architecture modulaire** : Le système est organisé en modules clairs (authentification, gestion d'établissements, calculs, IA).
- **Découplage** : L'utilisation d'interfaces (repositories) et de clients dédiés (AiMicroserviceClient) permet un découplage entre les composants.
- **Extensibilité** : La structure en couches et le regroupement fonctionnel facilitent l'ajout de nouvelles fonctionnalités.
- **Intégration IA** : L'intégration de l'intelligence artificielle est clairement séparée et accessible via un client dédié.

## 9. Conclusion

Ce diagramme de classes fournit une vue claire de l'architecture interne du système SMART MICROGRID. Il illustre comment les différentes composantes sont organisées en couches, comment elles interagissent, et comment le système intègre des services externes (microservice IA) tout en maintenant une architecture propre et modulaire. Cette modélisation facilite la compréhension du système, guide le développement, et sert de référence pour la maintenance et l'évolution future de l'application.


