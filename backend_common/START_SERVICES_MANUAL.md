# 🚀 Démarrage Manuel des Services

Les services doivent être démarrés dans **2 terminaux séparés** pour fonctionner correctement.

## 📋 Prérequis

1. **PostgreSQL** doit être démarré (via Docker) :
   ```bash
   cd backend
   docker-compose up -d
   ```

2. **Python** et **Maven** doivent être installés

---

## 🔧 Démarrage

### Terminal 1 : AI Microservice (Python)

```bash
cd ai_microservices
python -m uvicorn src.api:app --reload --host 0.0.0.0 --port 8000
```

**Vérification** : Ouvrir http://localhost:8000/health dans le navigateur

---

### Terminal 2 : Backend Spring Boot (Java)

```bash
cd backend_common
mvn spring-boot:run
```

**Vérification** : Ouvrir http://localhost:8080/api/public/health dans le navigateur

---

## ✅ Vérification

Une fois les deux services démarrés, exécuter :

```powershell
.\check-services.ps1
```

Puis lancer les tests :

```powershell
.\test-phase2-endpoints.ps1
```

---

## 🛑 Arrêt

Dans chaque terminal, appuyer sur `Ctrl+C` pour arrêter le service.

Ou utiliser :

```powershell
.\stop-services.ps1
```

---

## 🔍 Dépannage

### Port déjà utilisé
- Vérifier qu'aucun autre processus n'utilise les ports 8000 ou 8080
- Arrêter les processus existants

### Erreur de connexion à la base de données
- Vérifier que PostgreSQL est démarré : `docker ps`
- Vérifier les credentials dans `application.properties`

### Erreur Python
- Vérifier que toutes les dépendances sont installées : `pip install -r requirements.txt`

### Erreur Maven
- Vérifier que Maven est installé : `mvn --version`
- Nettoyer et recompiler : `mvn clean install`


