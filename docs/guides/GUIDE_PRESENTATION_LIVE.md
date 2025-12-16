# 🎤 Guide de Présentation Live - SMART MICROGRID

## 📋 Structure de la Présentation (15-20 minutes)

### **1. Introduction (2 min)**
### **2. Vue d'ensemble du Projet (3 min)**
### **3. Architecture Technique (5 min)**
### **4. Démonstration Live (5-7 min)**
### **5. Technologies & Innovations (3 min)**
### **6. Conclusion & Questions (2 min)**

---

## 🎯 1. INTRODUCTION (2 minutes)

### **Ce qu'il faut dire :**

> "Bonjour, je vais vous présenter **SMART MICROGRID**, une plateforme complète de gestion et d'optimisation de microgrids solaires pour établissements médicaux au Maroc.
> 
> **Problématique :** Les établissements de santé ont besoin d'une autonomie énergétique fiable, d'économies financières, et d'un impact environnemental positif.
> 
> **Solution :** Notre plateforme permet de dimensionner, simuler, analyser et optimiser des installations photovoltaïques avec stockage, en fournissant des analyses financières, environnementales et techniques détaillées, enrichies par l'intelligence artificielle."

### **Points clés à mentionner :**
- ✅ Projet complet (Frontend + Backend + IA)
- ✅ Application cross-platform (Web, Android, iOS)
- ✅ Intégration d'Intelligence Artificielle
- ✅ Cas d'usage réel : établissements médicaux

---

## 🌟 2. VUE D'ENSEMBLE DU PROJET (3 minutes)

### **A. Fonctionnalités Principales**

**Ce qu'il faut dire :**

> "La plateforme offre **7 fonctionnalités principales** organisées en onglets :
> 
> 1. **Vue d'ensemble** : Score global, métriques clés, résumé
> 2. **Analyse Financière** : ROI, NPV, IRR, économies sur 10-20 ans
> 3. **Impact Environnemental** : CO₂ évité, équivalents arbres/voitures
> 4. **Recommandations Techniques** : Dimensionnement optimal PV et batteries
> 5. **Comparatif Avant/Après** : Comparaison avec scénarios What-If
> 6. **Alertes** : Recommandations et alertes intelligentes
> 7. **Prédictions IA** : Prévisions long terme, détection d'anomalies"

### **B. Deux Workflows de Création**

**Ce qu'il faut dire :**

> "Le système supporte **deux workflows** :
> 
> - **Workflow EXISTANT** : Pour établissements déjà en place (5 formulaires)
>   - Collecte des données existantes (consommation, équipements)
>   - Analyse de la situation actuelle
>   - Recommandations d'amélioration
> 
> - **Workflow NEW** : Pour nouveaux projets (4 formulaires)
>   - Dimensionnement depuis zéro
>   - Optimisation selon contraintes (budget, surface)
>   - Recommandations personnalisées"

### **C. Intelligence Artificielle**

**Ce qu'il faut dire :**

> "L'IA apporte :
> - **Prédictions long terme** (7, 14, 30, 90 jours) de consommation et production
> - **Recommandations ML optimisées** basées sur des modèles entraînés
> - **Détection d'anomalies** pour identifier les problèmes proactivement
> - **Optimisation automatique** du dispatch énergétique"

---

## 🏗️ 3. ARCHITECTURE TECHNIQUE (5 minutes)

### **A. Architecture en 3 Couches**

**Ce qu'il faut dire (en montrant le schéma) :**

> "L'architecture suit un modèle **en 3 couches** :

#### **1. Couche Présentation (Frontend)**
- **Technologie :** Flutter/Dart
- **Plateformes :** Web, Android, iOS
- **Responsabilités :**
  - Interface utilisateur
  - Formulaires de saisie
  - Visualisation des résultats (7 onglets)
  - Graphiques interactifs (fl_chart)
  - Export PDF

#### **2. Couche Métier (Backend)**
- **Technologie :** Spring Boot 3.2.0 / Java 17
- **Port :** 8080
- **Responsabilités :**
  - API REST
  - Logique métier (calculs, dimensionnement)
  - Authentification JWT
  - Communication avec l'IA
  - Gestion des données (JPA/Hibernate)

#### **3. Couche Intelligence Artificielle**
- **Technologie :** FastAPI / Python 3.8+
- **Port :** 8000
- **Responsabilités :**
  - Modèles ML (XGBoost, RandomForest, Isolation Forest)
  - Prédictions et recommandations
  - Détection d'anomalies
  - Optimisation avancée

#### **4. Base de Données**
- **Technologie :** PostgreSQL 12+
- **Port :** 5434
- **Stockage :** Utilisateurs, établissements, données historiques"

### **B. Flux de Communication**

**Ce qu'il faut dire :**

> "**Communication Frontend ↔ Backend :**
> - Protocole : HTTP/REST API
> - Authentification : JWT (JSON Web Tokens)
> - Format : JSON
> - Le frontend n'appelle **JAMAIS** directement le microservice IA
> 
> **Communication Backend ↔ AI Microservice :**
> - Protocole : HTTP/REST API (interne)
> - Pas d'authentification (appels internes)
> - Format : JSON
> - Fallback : Si l'IA n'est pas disponible, le backend utilise des calculs simples
> 
> **Communication Backend ↔ PostgreSQL :**
> - ORM : Hibernate/JPA (Spring Data JPA)
> - Connexion JDBC"

### **C. Sécurité**

**Ce qu'il faut dire :**

> "**Sécurité implémentée :**
> - Authentification JWT avec expiration
> - Chiffrement des mots de passe (BCrypt)
> - Isolation des données : chaque utilisateur ne voit que ses établissements
> - Protection CSRF
> - Validation des données à chaque étape"

---

## 🎬 4. DÉMONSTRATION LIVE (5-7 minutes)

### **Scénario de Démonstration Recommandé**

#### **Étape 1 : Démarrage des Services (1 min)**

**Ce qu'il faut dire :**

> "Je vais démarrer tous les services avec notre script automatique."

**Actions :**
```powershell
.\start-all-services-mobile.ps1
```

**Ce qu'il faut expliquer :**
- ✅ PostgreSQL démarre (Docker)
- ✅ Backend Spring Boot démarre (port 8080)
- ✅ AI Microservice démarre (port 8000)
- ✅ Frontend Flutter Web démarre

**Vérification rapide :**
- Ouvrir `http://localhost:8080/api/public/health` → Vérifier "UP"
- Ouvrir `http://localhost:8000/health` → Vérifier "healthy"

#### **Étape 2 : Authentification (30 sec)**

**Actions :**
1. Ouvrir l'application Flutter
2. Se connecter (ou créer un compte)
3. Expliquer : "Le token JWT est stocké localement et inclus dans toutes les requêtes"

#### **Étape 3 : Création d'un Établissement (2 min)**

**Actions :**
1. Cliquer sur "Nouvel établissement"
2. Choisir "EXISTANT" ou "NEW"
3. Remplir le formulaire (montrer la géolocalisation GPS)
4. Expliquer : "Le système détermine automatiquement la zone solaire (A, B, C, D) selon la localisation"

**Points à mentionner :**
- ✅ Géolocalisation automatique
- ✅ Détermination de la zone solaire
- ✅ Validation des données en temps réel
- ✅ Sauvegarde automatique des brouillons

#### **Étape 4 : Affichage des Résultats (2-3 min)**

**Actions :**
1. Naviguer vers la page de résultats
2. Parcourir les 7 onglets

**Onglet 1 - Vue d'ensemble :**
- "Voici le score global (0-100) calculé selon 4 critères : autonomie (40%), économique (30%), résilience (20%), environnemental (10%)"

**Onglet 2 - Financier :**
- "Analyse financière complète : ROI de X années, NPV de Y, IRR de Z%"
- "Projections sur 10 et 20 ans avec économies cumulées"

**Onglet 3 - Environnemental :**
- "Impact environnemental : X tonnes de CO₂ évitées par an"
- "Équivalent à Y arbres plantés ou Z voitures retirées de la route"

**Onglet 4 - Technique :**
- "Recommandations de dimensionnement : X kW de PV, Y kWh de batteries"
- "Surface nécessaire : Z m²"

**Onglet 5 - Comparatif :**
- "Comparaison avant/après installation"
- "Scénarios What-If : je peux ajuster les paramètres et voir l'impact en temps réel"

**Onglet 6 - Alertes :**
- "Alertes et recommandations intelligentes"

**Onglet 7 - Prédictions IA :**
- "Prévisions long terme générées par l'IA"
- "Détection d'anomalies"
- "Recommandations ML optimisées"

#### **Étape 5 : Scénario What-If (1 min)**

**Actions :**
1. Aller dans l'onglet Comparatif
2. Ajuster les sliders (puissance PV, capacité batterie)
3. Montrer la mise à jour en temps réel

**Ce qu'il faut dire :**
> "Le système recalcule instantanément tous les résultats avec les nouveaux paramètres. L'IA optimise le dispatch énergétique pour ces nouveaux paramètres."

---

## 💻 5. TECHNOLOGIES & INNOVATIONS (3 minutes)

### **A. Stack Technique Complète**

**Ce qu'il faut dire :**

> "**Frontend :**
> - Flutter 3.0+ : Framework cross-platform (une seule base de code pour Web, Android, iOS)
> - Bibliothèques : fl_chart (graphiques), geolocator (GPS), printing (PDF)
> 
> **Backend :**
> - Spring Boot 3.2.0 : Framework Java moderne
> - Spring Security : Authentification JWT
> - Spring Data JPA : ORM pour PostgreSQL
> - Architecture en couches : Controller → Service → Repository
> 
> **IA :**
> - FastAPI : Framework Python async haute performance
> - Modèles ML : XGBoost, RandomForest, Isolation Forest
> - Bibliothèques : scikit-learn, pandas, numpy
> 
> **Base de données :**
> - PostgreSQL : Base relationnelle robuste
> - Docker : Containerisation pour faciliter le déploiement"

### **B. Points d'Innovation**

**Ce qu'il faut dire :**

> "**1. Architecture Microservices :**
> - Séparation claire des responsabilités
> - Scalabilité : chaque service peut évoluer indépendamment
> - Résilience : fallback si l'IA n'est pas disponible
> 
> **2. Intelligence Artificielle Intégrée :**
> - Prédictions basées sur des modèles entraînés
> - Détection d'anomalies proactive
> - Optimisation automatique
> 
> **3. Cross-Platform :**
> - Une seule base de code pour Web, Android, iOS
> - Expérience utilisateur cohérente
> 
> **4. Calculs Avancés :**
> - Dimensionnement optimal multi-critères
> - Analyse financière complète (NPV, IRR, ROI)
> - Simulation énergétique horaire
> 
> **5. Expérience Utilisateur :**
> - Interface intuitive avec 7 onglets
> - Graphiques interactifs
> - Export PDF
> - Scénarios What-If en temps réel"

---

## 🎯 6. CONCLUSION & QUESTIONS (2 minutes)

### **Résumé**

**Ce qu'il faut dire :**

> "Pour résumer, SMART MICROGRID est une plateforme complète qui combine :
> - ✅ **Architecture moderne** : 3 couches (Frontend, Backend, IA)
> - ✅ **Technologies de pointe** : Flutter, Spring Boot, FastAPI, PostgreSQL
> - ✅ **Intelligence Artificielle** : Prédictions, recommandations, détection d'anomalies
> - ✅ **Expérience utilisateur** : Interface intuitive, graphiques interactifs, export PDF
> - ✅ **Calculs avancés** : Dimensionnement optimal, analyse financière, impact environnemental
> 
> Le système est prêt pour un déploiement réel et peut être étendu avec des capteurs IoT pour un monitoring temps réel."

### **Points Forts à Mettre en Avant**

1. ✅ **Projet complet** : Frontend + Backend + IA + Base de données
2. ✅ **Architecture professionnelle** : Microservices, séparation des responsabilités
3. ✅ **Technologies modernes** : Stack à jour et performante
4. ✅ **Intelligence Artificielle** : ML intégré avec modèles entraînés
5. ✅ **Cross-platform** : Web, Android, iOS
6. ✅ **Calculs avancés** : Dimensionnement optimal, analyses financières
7. ✅ **Expérience utilisateur** : Interface intuitive, graphiques interactifs

---

## 📚 POINTS TECHNIQUES À CONNAÎTRE PAR CŒUR

### **Architecture & Communications**

1. **Flux de données principal :**
   ```
   Frontend (Flutter) 
     → HTTP/REST + JWT 
     → Backend (Spring Boot) 
     → HTTP/REST (interne) 
     → AI Microservice (FastAPI)
     → Retour JSON
   ```

2. **Ports des services :**
   - Backend : 8080
   - AI Microservice : 8000
   - PostgreSQL : 5434
   - Frontend Web : Port dynamique

3. **Authentification :**
   - JWT (JSON Web Tokens)
   - Token stocké dans SharedPreferences (Flutter)
   - Inclus dans header : `Authorization: Bearer <token>`

4. **Communication Frontend ↔ Backend :**
   - Le frontend n'appelle **JAMAIS** directement l'IA
   - Tous les appels passent par le backend
   - Format JSON

5. **Fallback :**
   - Si l'IA n'est pas disponible, le backend utilise des calculs simples
   - Le système continue de fonctionner

### **Calculs Principaux**

1. **Production Photovoltaïque :**
   ```
   monthlyProduction = surfaceM2 × irradiance × 30 × 0.20 × 0.80
   ```
   - Irradiance selon zone (A: 6.0, B: 5.5, C: 5.0, D: 4.5 kWh/m²/jour)
   - 0.20 = efficacité panneau (20%)
   - 0.80 = facteur performance (80% pour pertes)

2. **Autonomie Énergétique :**
   ```
   autonomy = (monthlyPvProduction / monthlyConsumption) × 100
   ```

3. **ROI (Retour sur Investissement) :**
   ```
   roi = installationCost / annualSavings  // en années
   ```

4. **Score Global (0-100) :**
   ```
   autonomyScore (40%) + economicScore (30%) + 
   resilienceScore (20%) + environmentalScore (10%)
   ```

### **Endpoints API Principaux**

1. **Authentification :**
   - `POST /api/auth/register` - Inscription
   - `POST /api/auth/login` - Connexion
   - `GET /api/auth/me` - Profil utilisateur

2. **Établissements :**
   - `GET /api/establishments` - Liste
   - `POST /api/establishments` - Création
   - `GET /api/establishments/{id}/comprehensive-results` - Résultats complets
   - `GET /api/establishments/{id}/forecast` - Prévisions IA
   - `POST /api/establishments/{id}/simulate` - Simulation What-If

3. **AI Microservice :**
   - `POST /forecast/longterm` - Prévisions long terme
   - `POST /recommendations/ml` - Recommandations ML
   - `POST /anomalies` - Détection d'anomalies
   - `POST /optimize` - Optimisation dispatch

### **Modèles ML Utilisés**

1. **XGBoost** : Prédictions de consommation
2. **RandomForest** : Prévisions long terme
3. **Isolation Forest** : Détection d'anomalies
4. **GradientBoosting** : Prédictions production PV

---

## ⚠️ QUESTIONS POSSIBLES DU PROFESSEUR & RÉPONSES

### **Q1 : "Pourquoi avoir choisi Flutter pour le frontend ?"**

**Réponse :**
> "Flutter permet de développer une seule application qui fonctionne sur Web, Android et iOS. Cela réduit le temps de développement et garantit une expérience utilisateur cohérente. De plus, Flutter offre d'excellentes performances et une riche bibliothèque de widgets pour les graphiques."

### **Q2 : "Comment fonctionne l'authentification JWT ?"**

**Réponse :**
> "L'utilisateur se connecte via `/api/auth/login`. Le backend valide les credentials et génère un token JWT signé. Ce token est stocké côté frontend et inclus dans toutes les requêtes suivantes via le header `Authorization: Bearer <token>`. Le backend valide le token à chaque requête via un filtre Spring Security."

### **Q3 : "Pourquoi avoir séparé l'IA dans un microservice ?"**

**Réponse :**
> "Séparer l'IA permet :
> - **Scalabilité** : L'IA peut être déployée sur des machines plus puissantes
> - **Indépendance** : L'IA peut être mise à jour sans affecter le backend
> - **Résilience** : Le backend continue de fonctionner même si l'IA est indisponible (fallback)
> - **Technologie** : Python est plus adapté pour le ML que Java"

### **Q4 : "Comment l'IA génère-t-elle les prédictions ?"**

**Réponse :**
> "L'IA utilise des modèles ML pré-entraînés (XGBoost, RandomForest) stockés au format `.joblib`. Ces modèles ont été entraînés sur des données historiques. Quand on demande une prédiction, le microservice charge le modèle, prépare les données d'entrée (features), et génère les prédictions. Les modèles sont réentraînables périodiquement pour s'améliorer."

### **Q5 : "Quelle est la différence entre les calculs simples et les calculs IA ?"**

**Réponse :**
> "Les calculs simples (backend) utilisent des formules mathématiques fixes basées sur des moyennes et des règles. Les calculs IA utilisent des modèles ML qui apprennent des patterns complexes dans les données historiques, permettant des prédictions plus précises et des optimisations plus sophistiquées."

### **Q6 : "Comment gérez-vous les erreurs si un service est indisponible ?"**

**Réponse :**
> "Le système a plusieurs mécanismes de résilience :
> - **Fallback** : Si l'IA n'est pas disponible, le backend utilise des calculs simples
> - **Validation** : Validation des données à chaque étape pour éviter les erreurs
> - **Gestion d'erreurs** : Messages d'erreur explicites pour l'utilisateur
> - **Health checks** : Vérification de l'état des services"

### **Q7 : "Comment le système détermine-t-il la zone solaire ?"**

**Réponse :**
> "Le système utilise les coordonnées GPS (latitude, longitude) de l'établissement. Selon la position géographique au Maroc, il détermine automatiquement la zone solaire (A, B, C, D) qui correspond à différents niveaux d'irradiation. Cette zone est utilisée pour calculer la production photovoltaïque."

### **Q8 : "Quels sont les avantages de l'architecture microservices ?"**

**Réponse :**
> "Les avantages sont :
> - **Séparation des responsabilités** : Chaque service a un rôle clair
> - **Scalabilité** : Chaque service peut être mis à l'échelle indépendamment
> - **Maintenabilité** : Code organisé et modulaire
> - **Flexibilité** : Services optionnels avec fallback
> - **Technologies** : Chaque service peut utiliser la technologie la plus adaptée"

---

## ✅ CHECKLIST AVANT LA PRÉSENTATION

### **Préparation Technique**

- [ ] Tous les services sont testés et fonctionnent
- [ ] Script de démarrage automatique fonctionne
- [ ] Base de données contient des données de test
- [ ] Application Flutter fonctionne (Web ou Mobile)
- [ ] AI Microservice est démarré et accessible
- [ ] Backend répond aux health checks
- [ ] Un établissement de test est créé pour la démo

### **Préparation Contenu**

- [ ] Connaître par cœur les 7 onglets et leur contenu
- [ ] Comprendre les calculs principaux (ROI, NPV, IRR, autonomie)
- [ ] Savoir expliquer l'architecture en 3 couches
- [ ] Connaître les ports et URLs des services
- [ ] Comprendre le flux de communication
- [ ] Savoir expliquer le rôle de l'IA

### **Préparation Démonstration**

- [ ] Scénario de démo préparé et testé
- [ ] Données de test prêtes
- [ ] Navigation dans l'application maîtrisée
- [ ] Points clés à montrer identifiés
- [ ] Temps de démo estimé (5-7 min)

### **Préparation Questions**

- [ ] Réponses aux questions fréquentes préparées
- [ ] Points techniques clés mémorisés
- [ ] Limitations connues et expliquées
- [ ] Améliorations futures identifiées

---

## 🎯 CONSEILS POUR LA PRÉSENTATION

1. **Soyez confiant** : Vous connaissez votre projet, montrez-le !
2. **Parlez clairement** : Expliquez les concepts techniques simplement
3. **Montrez le code si nécessaire** : Préparez quelques extraits clés
4. **Démontrez les fonctionnalités** : Actions concrètes valent mieux que descriptions
5. **Anticipez les questions** : Préparez des réponses aux questions techniques
6. **Gérez le temps** : Respectez les 15-20 minutes
7. **Soyez honnête** : Si vous ne savez pas, dites-le et proposez de chercher

---

## 📝 RÉSUMÉ EN 30 SECONDES (ÉLÉVATEUR)

> "SMART MICROGRID est une plateforme complète de gestion de microgrids solaires pour établissements médicaux. Elle combine un frontend Flutter cross-platform, un backend Spring Boot, et un microservice IA FastAPI. Le système permet de dimensionner, simuler et optimiser des installations photovoltaïques avec stockage, en fournissant des analyses financières, environnementales et techniques enrichies par l'intelligence artificielle. L'architecture microservices garantit scalabilité et résilience."

---

**Bonne chance pour votre présentation ! 🚀**

