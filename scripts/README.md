# Scripts de Gestion des Services

Scripts shell pour lancer et arrêter tous les services du projet Microgrid Hospitalier.

## Scripts Disponibles

### `start-all-services.sh`
Lance tous les services nécessaires :
- ✅ **AI Microservice** (FastAPI) - Port 8000
- ✅ **Backend Spring Boot** - Port 8080
- ✅ **Application Flutter** - Détecte automatiquement iOS/Android/Web

### `stop-all-services.sh`
Arrête tous les services lancés par le script de démarrage.

## Utilisation

### Lancer tous les services

```bash
cd scripts
./start-all-services.sh
```

Ou depuis la racine du projet :

```bash
./scripts/start-all-services.sh
```

### Arrêter tous les services

```bash
cd scripts
./stop-all-services.sh
```

Ou depuis la racine du projet :

```bash
./scripts/stop-all-services.sh
```

## Fonctionnalités

### Détection Automatique
- ✅ Détecte si les services sont déjà en cours d'exécution
- ✅ Détecte automatiquement la plateforme Flutter (iOS/Android/Web)
- ✅ Vérifie PostgreSQL (Docker)
- ✅ Vérifie les dépendances Python et les installe si nécessaire

### Gestion des Logs
- 📁 Les logs sont sauvegardés dans `logs/`
  - `backend.log` - Logs du backend Spring Boot
  - `ai-service.log` - Logs du microservice AI
  - `flutter.log` - Logs de l'application Flutter
- 💾 Les PIDs sont sauvegardés dans `logs/*.pid` pour un arrêt propre

### Vérification des Services
- ✅ Vérifie que chaque service répond correctement
- ✅ Affiche les URLs d'accès
- ✅ Messages colorés pour un suivi facile

## Prérequis

- ✅ **PostgreSQL** : Docker avec le conteneur `microgrid-postgres` (port 5434)
- ✅ **Python 3** : Avec les dépendances installées (voir `ai_microservices/requirements.txt`)
- ✅ **Java 17+** : Pour le backend Spring Boot
- ✅ **Maven** : Pour compiler le backend
- ✅ **Flutter** : Pour l'application mobile/web

## URLs des Services

Une fois lancés, les services sont accessibles sur :

- **AI Microservice** : http://localhost:8000
  - Documentation API : http://localhost:8000/docs
  - Health check : http://localhost:8000/health

- **Backend Spring Boot** : http://localhost:8080
  - API : http://localhost:8080/api
  - Health check : http://localhost:8080/actuator/health

- **Flutter App** :
  - Web : http://localhost:3000 (si lancé sur Chrome)
  - iOS/Android : Sur le simulateur/émulateur

## Dépannage

### Les services ne démarrent pas
1. Vérifiez que PostgreSQL est lancé : `docker ps | grep postgres`
2. Vérifiez les logs dans `logs/`
3. Vérifiez que les ports 8000 et 8080 ne sont pas déjà utilisés

### Flutter ne détecte pas l'émulateur
1. Lancez manuellement l'émulateur :
   ```bash
   flutter emulators --launch apple_ios_simulator
   # ou
   flutter emulators --launch Pixel_9_Pro
   ```
2. Vérifiez les appareils disponibles : `flutter devices`

### Erreur de connexion réseau dans Flutter
- Sur **iOS Simulator** : Utilise `localhost` (configuré automatiquement)
- Sur **Android Emulator** : Utilise `10.0.2.2` (configuré automatiquement)
- Sur **Web** : Utilise `localhost` (configuré automatiquement)

## Notes

- Les services sont lancés en arrière-plan (nohup)
- Les PIDs sont sauvegardés pour un arrêt propre
- Le script vérifie automatiquement la plateforme et configure les URLs correctement
- Les logs sont redirigés vers des fichiers pour un suivi facile

