# Intégration Backend - Frontend

## Analyse du Frontend Flutter

### Flux d'authentification

1. **AuthPage** → Choix entre Login et Register
   - **Login** → `LoginPage` → Dashboard (si succès)
   - **Register** → `InstitutionChoicePage` (directement, sans formulaire d'inscription)

2. **InstitutionChoicePage** → Choix entre:
   - **EXISTANT** → FormA1 (Cas 1 - Établissement existant)
   - **NEW** → FormB1 (Cas 2 - Nouveau établissement)

### Cas 1: Établissement EXISTANT (FormA1 → FormA2 → ...)

**FormA1** collecte:
- Type d'établissement (dropdown):
  - CHU (Centre Hospitalier Universitaire)
  - Hôpital Général
  - Hôpital Spécialisé
  - Clinique
  - Centre de Santé
  - Autre
- Nom de l'établissement
- Nombre de lits
- Localisation GPS (latitude, longitude)

**FormA2** (à examiner) - Informations énergétiques

### Cas 2: Nouveau établissement (FormB1 → FormB2 → ...)

**FormB1** collecte:
- Localisation GPS avec carte interactive
- Zone solaire déterminée automatiquement (A, B, C, D) via `SolarZoneService`
  - Zone 1: Très fort rayonnement (Sud-Est, Sahara)
  - Zone 2: Fort rayonnement (Centre, Sud)
  - Zone 3: Rayonnement moyen (Nord, Côtes)
  - Zone 4: Rayonnement modéré (Rif, Hautes altitudes)

**FormB2** (à examiner) - Contraintes projet

## Endpoints Backend Requis

### ✅ Déjà implémentés

1. `POST /api/auth/register` - Inscription
2. `POST /api/auth/login` - Connexion
3. `GET /api/auth/me` - Profil utilisateur

### ❌ À implémenter

#### Gestion des établissements

1. **POST `/api/establishments`** - Créer un établissement
   - Cas 1 (EXISTANT) ou Cas 2 (NEW)
   - Body selon le cas

2. **GET `/api/establishments`** - Liste des établissements de l'utilisateur
   - Retourne tous les établissements de l'utilisateur connecté

3. **GET `/api/establishments/{id}`** - Détails d'un établissement

4. **PUT `/api/establishments/{id}`** - Mettre à jour un établissement

5. **DELETE `/api/establishments/{id}`** - Supprimer un établissement

#### Simulation et recommandations

6. **POST `/api/simulations/run`** - Lancer une simulation
   - Pour Cas 1 ou Cas 2
   - Retourne les résultats de simulation

7. **GET `/api/simulations/{id}`** - Récupérer les résultats d'une simulation

8. **POST `/api/recommendations/establishment-type`** - Recommander un type d'établissement
   - Pour Cas 2 uniquement
   - Basé sur budget, surface, population, etc.

#### Intégration avec microservice AI

9. **POST `/api/ai/predict`** - Prédiction de consommation
   - Appelle le microservice Python/FastAPI

10. **POST `/api/ai/optimize`** - Optimisation énergétique
    - Appelle le microservice Python/FastAPI

## Mapping des données

### Type d'établissement (Frontend → Backend)

| Frontend | Backend Enum |
|----------|--------------|
| CHU (Centre Hospitalier Universitaire) | `CHU` |
| Hôpital Général | `HOPITAL_REGIONAL` ou `HOPITAL_PROVINCIAL` |
| Hôpital Spécialisé | Selon spécialité |
| Clinique | `CLINIQUE_PRIVEE` |
| Centre de Santé | `CENTRE_SANTE_PRIMAIRE` |
| Autre | À définir |

### Zone solaire (Frontend → Backend)

| Frontend SolarZone | Backend IrradiationClass |
|-------------------|-------------------------|
| zone1 (Très fort) | `A` |
| zone2 (Fort) | `B` |
| zone3 (Moyen) | `C` |
| zone4 (Modéré) | `D` |

## Prochaines étapes

1. ✅ Authentification (fait)
2. ⏳ Créer les endpoints pour les établissements
3. ⏳ Créer les services de simulation
4. ⏳ Intégrer avec le microservice AI
5. ⏳ Créer les calculs de ROI et économies

## Notes importantes

- Le frontend ne fait **pas** d'appel API pour l'inscription dans `AuthPage` → il va directement à `InstitutionChoicePage`
- L'inscription devrait probablement se faire après le choix EXISTANT/NEW
- Le login actuel est simulé (ligne 67 dans `login_page.dart`) → doit être connecté au backend
- Les formulaires A2-A5 et B2-B5 doivent être examinés pour comprendre tous les champs requis


