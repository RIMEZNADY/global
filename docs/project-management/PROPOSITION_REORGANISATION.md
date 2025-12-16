# 📁 Proposition de Réorganisation de la Structure du Projet

## 🔍 Problèmes identifiés

1. **Trop de fichiers .md à la racine** (40+ fichiers de documentation)
2. **Duplication frontend** : `frontend_flutter_mobile/` et `hospital-microgrid/` semblent être le même projet
3. **Fichiers de diagrammes** (.puml) à la racine
4. **Scripts PowerShell** à la racine
5. **Pas de dossier `docs/`** pour centraliser la documentation

## 📂 Structure proposée

```
SMART_MICROGRID/
├── README.md                          # README principal du projet
├── .gitignore
├── docker-compose.yml                 # Si nécessaire
│
├── backend_common/                    # Backend Spring Boot
│   ├── src/
│   ├── pom.xml
│   └── ...
│
├── ai_microservices/                  # Microservice IA Python
│   ├── src/
│   ├── models/
│   └── ...
│
├── frontend/                          # Frontend Flutter (un seul dossier)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── ...
│
├── docs/                              # 📚 NOUVEAU : Toute la documentation
│   ├── architecture/
│   │   ├── ARCHITECTURE_CONNEXIONS.md
│   │   ├── ARCHITECTURE_AFFICHAGE.md
│   │   ├── ORGANISATION_FONCTIONNELLE.md
│   │   └── diagrams/
│   │       ├── BPMN_DIAGRAM.puml
│   │       ├── CLASS_DIAGRAM.puml
│   │       └── USE_CASE_DIAGRAM.puml
│   │
│   ├── guides/
│   │   ├── GUIDE_PRESENTATION_LIVE.md
│   │   ├── GUIDE_PRESENTATION_FLUTTER.md
│   │   ├── AIDE_MEMOIRE_PRESENTATION.md
│   │   └── AIDE_MEMOIRE_FLUTTER.md
│   │
│   ├── technical/
│   │   ├── PROCESSUS_LOCALISATION.md
│   │   ├── PERSISTANCE_JSON.md
│   │   ├── REST_API_EXPLICATION.md
│   │   ├── LIAISON_FRONTEND_BACKEND.md
│   │   └── ...
│   │
│   ├── features/
│   │   ├── AUTO_LEARNING_CONTENT.md
│   │   ├── DASHBOARD_ANALYSIS.md
│   │   ├── WHAT_MAKES_IT_SMART.md
│   │   └── ...
│   │
│   ├── ux-ui/
│   │   ├── UX_IMPROVEMENTS.md
│   │   ├── PALETTE_COULEURS_ANALYSE.md
│   │   └── ...
│   │
│   ├── project-management/
│   │   ├── DIVISION_TACHES_5_MEMBRES.md
│   │   ├── PAQP_SMART_MICROGRID.tex
│   │   └── RESUME_MODIFICATIONS_PAQP.md
│   │
│   └── audits/
│       ├── AUDIT_COMPLET_APPLICATION.md
│       └── AUDIT_LOGIQUE_METIER.md
│
├── scripts/                           # 📜 Scripts utilitaires
│   ├── start-all-services.ps1
│   ├── start-all-services-mobile.ps1
│   └── ...
│
└── .github/                           # CI/CD (si nécessaire)
    └── workflows/
```

## 🎯 Catégories de documentation

### Architecture
- ARCHITECTURE_CONNEXIONS.md
- ARCHITECTURE_AFFICHAGE.md
- ORGANISATION_FONCTIONNELLE.md
- Diagrams (.puml)

### Guides
- GUIDE_PRESENTATION_LIVE.md
- GUIDE_PRESENTATION_FLUTTER.md
- AIDE_MEMOIRE_*.md

### Technique
- PROCESSUS_LOCALISATION.md
- PERSISTANCE_JSON.md
- REST_API_EXPLICATION.md
- LIAISON_FRONTEND_BACKEND.md
- INSTALL_ANDROID_PHONE.md
- TEST_MOBILE.md

### Features
- AUTO_LEARNING_CONTENT.md
- DASHBOARD_ANALYSIS.md
- WHAT_MAKES_IT_SMART.md
- FORMULAIRES_EXISTANT.md
- ESTABLISHMENTS_MANAGEMENT.md

### UX/UI
- UX_IMPROVEMENTS.md
- UX_IMPROVEMENTS_SUMMARY.md
- UX_MOBILE_IMPROVEMENTS.md
- PALETTE_COULEURS_ANALYSE.md
- PALETTE_IDEALE_UX.md

### Project Management
- DIVISION_TACHES_5_MEMBRES.md
- PAQP_SMART_MICROGRID.tex
- RESUME_MODIFICATIONS_PAQP.md

### Audits
- AUDIT_COMPLET_APPLICATION.md
- AUDIT_LOGIQUE_METIER.md

## ✅ Avantages

1. **Structure claire** : Facile de trouver la documentation
2. **Racine propre** : Seulement les fichiers essentiels
3. **Organisation logique** : Documentation groupée par thème
4. **Maintenabilité** : Plus facile d'ajouter de nouveaux documents
5. **Professionnel** : Structure standard de projet

## 🚀 Actions à faire

1. Créer le dossier `docs/` avec ses sous-dossiers
2. Déplacer tous les fichiers .md dans les bons dossiers
3. Déplacer les diagrammes .puml dans `docs/architecture/diagrams/`
4. Déplacer les scripts dans `scripts/`
5. Clarifier la situation frontend (garder un seul dossier)
6. Mettre à jour les liens dans les fichiers si nécessaire

