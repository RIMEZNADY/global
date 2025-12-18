# Hospital Microgrid - Application Web Angular

Version web Angular de l'application Hospital Microgrid, reprenant les mêmes fonctionnalités que la version mobile Flutter.

## Fonctionnalités

- **Dashboard** : Monitoring en temps réel avec graphiques et métriques
- **AI Prediction** : Prédictions ML pour la demande d'énergie sur 24h
- **Auto-Learning** : Système d'apprentissage automatique avec métriques ML
- **History** : Analyse des tendances de consommation et génération d'énergie à long terme
- **Authentification** : Connexion et inscription
- **Thème Medical Solar** : Palette de couleurs claire et moderne

## Prérequis

- Node.js (v18 ou supérieur)
- npm ou yarn
- Angular CLI (installé globalement ou via npx)

## Installation

1. Installer les dépendances :
```bash
npm install
```

2. Démarrer le serveur de développement :
```bash
npm start
# ou
ng serve
```

L'application sera accessible sur `http://localhost:4200`

## Configuration

### URLs des services backend

Les URLs par défaut sont configurées dans les services :
- **Backend API** : `http://localhost:8080/api` (défini dans `src/app/services/api.service.ts`)
- **AI Service** : `http://localhost:8000` (défini dans `src/app/services/ai.service.ts`)

Pour modifier ces URLs, éditez les fichiers de services correspondants.

## Structure du projet

```
src/
├── app/
│   ├── components/          # Composants réutilisables
│   │   ├── navigation/      # Barre de navigation
│   │   └── metric-card/      # Carte de métrique
│   ├── guards/              # Guards de route (AuthGuard)
│   ├── pages/               # Pages principales
│   │   ├── dashboard/       # Page Dashboard
│   │   ├── ai-prediction/   # Page AI Prediction
│   │   ├── auto-learning/   # Page Auto-Learning
│   │   ├── history/         # Page History
│   │   ├── login/           # Page de connexion
│   │   └── welcome/         # Page d'accueil
│   └── services/            # Services Angular
│       ├── api.service.ts   # Service API générique
│       ├── auth.service.ts  # Service d'authentification
│       ├── ai.service.ts    # Service AI
│       └── establishment.service.ts
├── styles.scss              # Styles globaux
└── index.html               # Point d'entrée HTML
```

## Technologies utilisées

- **Angular 17** : Framework principal
- **Chart.js / ng2-charts** : Bibliothèque de graphiques
- **RxJS** : Programmation réactive
- **SCSS** : Préprocesseur CSS
- **TypeScript** : Langage de programmation

## Palette de couleurs (Medical Solar)

- **Medical Blue** : `#4EA8DE`
- **Solar Green** : `#6BCF9D`
- **Solar Yellow** : `#F4C430`
- **Off White** : `#F9FAF7`
- **Soft Grey** : `#3A3A3A`

## Build pour production

```bash
ng build --configuration production
```

Les fichiers compilés seront dans le dossier `dist/hospital-microgrid-web/`

## Notes

- L'application nécessite que les services backend (Spring Boot sur port 8080) et AI (Python sur port 8000) soient démarrés
- L'authentification utilise JWT stocké dans localStorage
- Les graphiques utilisent Chart.js via ng2-charts
- Le design est responsive et s'adapte aux différentes tailles d'écran

## Support

Pour toute question ou problème, consultez la documentation Angular ou les fichiers de configuration du projet.
