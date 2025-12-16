# 📝 Aide-Mémoire Rapide - Présentation SMART MICROGRID

## 🎯 STRUCTURE (15-20 min)

1. **Introduction** (2 min) - Problématique + Solution
2. **Vue d'ensemble** (3 min) - 7 onglets + 2 workflows + IA
3. **Architecture** (5 min) - 3 couches + communications
4. **Démo live** (5-7 min) - Création établissement + résultats
5. **Technologies** (3 min) - Stack technique + innovations
6. **Conclusion** (2 min) - Résumé + questions

---

## 🏗️ ARCHITECTURE (À RETENIR PAR CŒUR)

```
Frontend (Flutter) → HTTP/REST + JWT → Backend (Spring Boot:8080)
                                              ↓
                                    AI Microservice (FastAPI:8000)
                                              ↓
                                    PostgreSQL (5434)
```

**Points clés :**
- Frontend n'appelle JAMAIS directement l'IA
- Tous les appels passent par le backend
- Fallback si IA indisponible

---

## 🔌 PORTS & URLS

| Service | Port | URL |
|---------|------|-----|
| Backend | 8080 | http://localhost:8080 |
| AI Microservice | 8000 | http://localhost:8000 |
| PostgreSQL | 5434 | localhost:5434 |
| Frontend Web | Dynamique | http://localhost:XXXXX |

---

## 📊 7 ONGLETS RÉSULTATS

1. **Vue d'ensemble** - Score global (0-100), métriques clés
2. **Financier** - ROI, NPV, IRR, économies 10-20 ans
3. **Environnemental** - CO₂ évité, équivalents arbres/voitures
4. **Technique** - Dimensionnement PV/batteries, surface
5. **Comparatif** - Avant/après + What-If interactif
6. **Alertes** - Recommandations intelligentes
7. **Prédictions IA** - Prévisions long terme, anomalies

---

## 🧮 CALCULS PRINCIPAUX

**Production PV :**
```
monthlyProduction = surface × irradiance × 30 × 0.20 × 0.80
```
- Zones : A(6.0), B(5.5), C(5.0), D(4.5) kWh/m²/jour

**Autonomie :**
```
autonomy = (monthlyPvProduction / monthlyConsumption) × 100
```

**ROI :**
```
roi = installationCost / annualSavings  // années
```

**Score Global :**
```
autonomy(40%) + economic(30%) + resilience(20%) + environmental(10%)
```

---

## 🔑 ENDPOINTS API CLÉS

**Auth :**
- `POST /api/auth/login` - Connexion
- `POST /api/auth/register` - Inscription

**Établissements :**
- `GET /api/establishments` - Liste
- `POST /api/establishments` - Création
- `GET /api/establishments/{id}/comprehensive-results` - Résultats
- `GET /api/establishments/{id}/forecast` - Prévisions IA
- `POST /api/establishments/{id}/simulate` - What-If

---

## 🤖 MODÈLES ML

- **XGBoost** - Prédictions consommation
- **RandomForest** - Prévisions long terme
- **Isolation Forest** - Détection anomalies
- **GradientBoosting** - Production PV

---

## 💻 STACK TECHNIQUE

**Frontend :** Flutter 3.0+ / Dart
**Backend :** Spring Boot 3.2.0 / Java 17
**IA :** FastAPI / Python 3.8+
**DB :** PostgreSQL 12+
**Auth :** JWT (JSON Web Tokens)

---

## 🎬 DÉMO LIVE - SCÉNARIO

1. **Démarrer services** : `.\start-all-services-mobile.ps1`
2. **Vérifier** : Health checks (8080, 8000)
3. **Se connecter** : Login/Register
4. **Créer établissement** : Workflow EXISTANT ou NEW
5. **Voir résultats** : Parcourir 7 onglets
6. **What-If** : Ajuster sliders, voir impact

---

## ❓ QUESTIONS FRÉQUENTES

**Q: Pourquoi Flutter ?**
A: Cross-platform (Web/Android/iOS), une seule base de code

**Q: Pourquoi microservice IA ?**
A: Scalabilité, indépendance, résilience (fallback)

**Q: Comment fonctionne JWT ?**
A: Token généré au login, inclus dans headers, validé à chaque requête

**Q: Que se passe-t-il si l'IA est indisponible ?**
A: Backend utilise calculs simples (fallback), système continue

**Q: Comment déterminer zone solaire ?**
A: GPS (lat/long) → zone A/B/C/D selon position Maroc

---

## ✅ CHECKLIST AVANT PRÉSENTATION

- [ ] Services testés et fonctionnels
- [ ] Script démarrage OK
- [ ] Données de test prêtes
- [ ] Démo testée
- [ ] Architecture comprise
- [ ] Calculs mémorisés
- [ ] Questions préparées

---

## 🎯 RÉSUMÉ 30 SECONDES

> "SMART MICROGRID : plateforme complète de gestion microgrids solaires pour établissements médicaux. Frontend Flutter cross-platform, backend Spring Boot, microservice IA FastAPI. Dimensionnement, simulation, optimisation avec analyses financières/environnementales enrichies par IA. Architecture microservices scalable et résiliente."

---

**Bonne présentation ! 🚀**

