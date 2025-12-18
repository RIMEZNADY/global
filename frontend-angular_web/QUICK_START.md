# Guide de démarrage rapide

## Installation et lancement

1. **Installer les dépendances** :
```bash
cd frontend-angular_web
npm install
```

2. **Démarrer l'application** :
```bash
npm start
```

L'application sera accessible sur `http://localhost:4200`

## Prérequis

Assurez-vous que les services backend sont démarrés :
- **Backend Spring Boot** : `http://localhost:8080`
- **Service AI Python** : `http://localhost:8000`
- **PostgreSQL** : via Docker

### Démarrage des services backend

**Option 1 : Script automatique (recommandé)**
```bash
# Depuis la racine du projet
./scripts/start-all-services.sh
```

**Option 2 : Démarrage manuel**

Terminal 1 - Service AI (Python):
```bash
cd ai_microservices
python -m uvicorn src.api:app --reload --host 0.0.0.0 --port 8000
```

Terminal 2 - Backend Spring Boot:
```bash
cd backend_common
mvn spring-boot:run
```

**Vérification des services:**
- AI Service: http://localhost:8000/health
- Backend: http://localhost:8080/api/public/health

## Première utilisation

1. **Créer un compte** : Allez sur `/register` pour créer un nouveau compte
2. **Se connecter** : Utilisez vos identifiants sur `/login`
3. **Créer un établissement** : Cliquez sur "Nouvel établissement" dans la navigation ou utilisez le bouton dans les messages d'erreur
4. **Explorer** : Une fois l'établissement créé, vous pouvez utiliser toutes les fonctionnalités

## Pages disponibles

- `/welcome` - Page d'accueil avec animation
- `/login` - Page de connexion
- `/dashboard` - Dashboard principal avec graphiques
- `/ai-prediction` - Prédictions IA
- `/auto-learning` - Métriques et apprentissage automatique
- `/history` - Historique et tendances

## Fonctionnalités principales

✅ Authentification (login/logout)
✅ Dashboard avec métriques en temps réel
✅ Graphiques interactifs (Chart.js)
✅ Prédictions IA avec sélection d'horizon
✅ Métriques ML et retraining
✅ Historique avec graphiques de tendances
✅ Design responsive
✅ Thème Medical Solar (même palette que mobile)

## Structure

- `src/app/pages/` - Pages principales
- `src/app/components/` - Composants réutilisables
- `src/app/services/` - Services Angular (API, Auth, AI)
- `src/app/guards/` - Guards de route (AuthGuard)

## Notes

- Les données sont chargées depuis les APIs backend
- L'authentification utilise JWT stocké dans localStorage
- Les graphiques utilisent Chart.js via ng2-charts
- Le design est responsive et s'adapte aux différentes tailles d'écran
