# 🏥 SMART MICROGRID

Plateforme complète de gestion et d'optimisation de microgrids solaires pour établissements médicaux au Maroc.

## 📋 Description

SMART MICROGRID est une application permettant de dimensionner, simuler, analyser et optimiser des installations photovoltaïques avec stockage, en fournissant des analyses financières, environnementales et techniques détaillées, enrichies par l'intelligence artificielle.

## 🏗️ Architecture

Le projet repose sur une architecture en 3 couches :

- **Frontend** : Flutter (Mobile/Web)
- **Backend** : Spring Boot (Java)
- **AI Microservice** : FastAPI (Python)
- **Base de données** : PostgreSQL

## 📁 Structure du Projet

```
SMART_MICROGRID/
├── backend_common/          # Backend Spring Boot
├── ai_microservices/        # Microservice IA Python
├── hospital-microgrid/      # Frontend Flutter
├── docs/                    # Documentation complète
│   ├── architecture/        # Architecture et diagrammes
│   ├── guides/              # Guides de présentation
│   ├── technical/           # Documentation technique
│   ├── features/            # Documentation des fonctionnalités
│   ├── ux-ui/               # Documentation UX/UI
│   ├── project-management/  # Gestion de projet (PAQP, etc.)
│   └── audits/              # Audits et analyses
└── scripts/                 # Scripts utilitaires
```

## 🚀 Démarrage Rapide

### Prérequis

- Java 17+
- Python 3.8+
- Flutter 3.0+
- Docker (pour PostgreSQL)
- Maven

### Lancer tous les services

```powershell
.\scripts\start-all-services-mobile.ps1
```

Ce script lance automatiquement :
- PostgreSQL (port 5434)
- Backend Spring Boot (port 8080)
- AI Microservice (port 8000)
- Frontend Flutter Web (port 3000)

### URLs des services

- **Frontend** : http://localhost:3000
- **Backend API** : http://localhost:8080
- **AI Microservice** : http://localhost:8000
- **PostgreSQL** : localhost:5434

## 📚 Documentation

Toute la documentation est disponible dans le dossier `docs/` :

- **Architecture** : `docs/architecture/`
- **Guides** : `docs/guides/`
- **Documentation technique** : `docs/technical/`
- **Fonctionnalités** : `docs/features/`
- **UX/UI** : `docs/ux-ui/`
- **Gestion de projet** : `docs/project-management/`
- **Audits** : `docs/audits/`

## 🛠️ Technologies

- **Frontend** : Flutter 3.0+, Dart
- **Backend** : Spring Boot 3.2.0, Java 17+
- **IA** : FastAPI 0.115.2, Python 3.8+, scikit-learn, XGBoost
- **Base de données** : PostgreSQL 12+

## 👥 Équipe

Projet développé par une équipe de 5 membres dans le cadre du module Management de Qualité - EMSI.

## 📄 Licence

Projet académique - EMSI 2024-2025

