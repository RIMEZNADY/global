# Explication du Diagramme BPMN - SMART MICROGRID

## 1. Vue d'ensemble

Le diagramme BPMN (Business Process Model and Notation) présenté modélise les processus métier principaux du système SMART MICROGRID. Ce diagramme illustre de manière séquentielle et structurée les différents flux de travail que suit un utilisateur pour gérer des projets de microgrids solaires pour établissements médicaux, depuis l'authentification jusqu'à la consultation et la gestion des résultats.

## 2. Structure générale du processus

Le diagramme suit une structure hiérarchique avec un point de départ unique, plusieurs chemins conditionnels, et un point d'arrivée commun. Il modélise les interactions entre l'utilisateur et le système, ainsi que les décisions et les actions qui en découlent.

## 3. Processus détaillés

### 3.1. Phase d'authentification

Le processus commence par une **étape d'authentification** :

- **Activité initiale** : "Connexion/Inscription"
- **Point de décision** : "Utilisateur authentifié ?"
  - **Si non** : L'utilisateur doit d'abord s'inscrire, puis se connecter
  - **Si oui** : L'utilisateur accède directement à son profil

Cette phase garantit que seuls les utilisateurs authentifiés peuvent accéder aux fonctionnalités du système.

### 3.2. Accès au profil

Après l'authentification, l'utilisateur **accède à son profil**, qui lui permet de gérer ses établissements et de lancer de nouvelles actions.

### 3.3. Processus principal : Création d'établissement

Le processus de création d'établissement est le plus complexe et se divise en deux workflows distincts selon le type d'établissement :

#### 3.3.1. Workflow EXISTANT (Établissement existant)

Pour un établissement médical déjà en fonctionnement, le processus suit cette séquence :

1. **FormA1 : Identifier l'établissement**
   - Collecte des informations de base : type d'établissement, nom, nombre de lits, localisation GPS

2. **FormA2 : Saisir données techniques**
   - Collecte des données énergétiques : surface installable, consommation mensuelle, présence éventuelle d'une installation PV existante

3. **FormA3 : Prévisualiser l'analyse**
   - Affichage d'une analyse préliminaire basée sur les données saisies

4. **FormA4 : Prévisualiser les recommandations**
   - Affichage des recommandations préliminaires de dimensionnement

#### 3.3.2. Workflow NEW (Nouveau projet)

Pour un établissement en phase de conception ou de construction, le processus suit cette séquence :

1. **FormB1 : Sélectionner localisation GPS**
   - Sélection de la localisation avec détermination automatique de la classe d'irradiation solaire

2. **FormB2 : Saisir informations projet**
   - Collecte des contraintes du projet : budget, surface disponible, population servie

3. **FormB3 : Définir objectif et priorité**
   - Sélection des objectifs du projet (économique, environnemental, technique) et des priorités

4. **FormB4 : Voir score de recommandation**
   - Affichage d'un score de recommandation basé sur les critères définis

#### 3.3.3. Étape commune : Sélection des équipements

Les deux workflows convergent vers une étape commune :

- **FormA5/B5 : Sélectionner équipements**
  - Sélection des équipements solaires : panneaux photovoltaïques, batteries, onduleurs, régulateurs

#### 3.3.4. Création et calcul des résultats

Après la sélection des équipements :

1. **Créer établissement (Backend)**
   - Persistance des données dans la base de données

2. **Calculer résultats complets**
   - Le système calcule automatiquement :
     - Dimensionnement optimal des équipements
     - Analyse financière (ROI, économies, etc.)
     - Impact environnemental (réduction CO₂, etc.)
     - Performance technique (autonomie, production, etc.)

3. **Charger prédictions IA (optionnel)**
   - Chargement asynchrone des prédictions et analyses IA :
     - Prévisions de consommation
     - Recommandations basées sur l'apprentissage automatique
     - Détection d'anomalies

4. **Afficher résultats (7 onglets)**
   - Présentation des résultats complets dans une interface à 7 onglets

### 3.4. Processus de consultation d'établissement

Pour consulter un établissement existant :

1. **Lister établissements**
   - Affichage de la liste des établissements de l'utilisateur

2. **Sélectionner établissement**
   - Choix d'un établissement spécifique

3. **Afficher résultats complets**
   - Affichage des résultats déjà calculés

4. **Actions supplémentaires (optionnelles)**
   - **Prédictions IA** : Chargement des prédictions IA si non encore chargées
   - **Scénarios What-If** : Simulation de scénarios alternatifs en modifiant :
     - Puissance PV
     - Capacité batterie
     - Consommation
     - Priorité du projet
   - **Exporter** : Génération d'un PDF et partage des résultats

### 3.5. Processus de modification d'établissement

Pour modifier un établissement existant :

1. **Sélectionner établissement**
2. **Modifier données**
3. **Recalculer résultats**
   - Le système recalcule automatiquement tous les résultats basés sur les nouvelles données
4. **Afficher résultats mis à jour**

### 3.6. Processus de suppression d'établissement

Pour supprimer un établissement :

1. **Sélectionner établissement**
2. **Confirmer suppression**
   - Étape de confirmation pour éviter les suppressions accidentelles
3. **Supprimer établissement**
   - Suppression définitive de l'établissement et de ses données associées

## 4. Points de décision et flux conditionnels

Le diagramme utilise plusieurs **points de décision** (représentés par des losanges) qui permettent de modéliser les choix de l'utilisateur :

1. **Authentification** : Détermine si l'utilisateur doit s'inscrire ou peut se connecter directement
2. **Type d'action** : Détermine quelle opération l'utilisateur souhaite effectuer (créer, consulter, modifier, supprimer)
3. **Type d'établissement** : Détermine le workflow à suivre (EXISTANT ou NEW)
4. **Actions supplémentaires** : Détermine les fonctionnalités optionnelles à activer lors de la consultation

## 5. Activités parallèles et séquentielles

- **Activités séquentielles** : La plupart des activités suivent un ordre logique strict (par exemple, FormA1 → FormA2 → FormA3)
- **Activités conditionnelles** : Certaines activités ne sont exécutées que sous certaines conditions (par exemple, les prédictions IA sont optionnelles)
- **Convergence de workflows** : Les workflows EXISTANT et NEW convergent vers une étape commune (sélection des équipements)

## 6. Intégration des services backend

Le diagramme met en évidence l'interaction avec le backend :

- **Création d'établissement** : Les données sont persistées dans la base de données
- **Calcul des résultats** : Le backend exécute des calculs complexes (dimensionnement, analyses financières, etc.)
- **Prédictions IA** : Le backend communique avec le microservice IA pour obtenir des prédictions et recommandations

## 7. Points clés du diagramme

- **Flexibilité** : Le système supporte deux workflows distincts selon le type d'établissement
- **Automatisation** : Les calculs et analyses sont effectués automatiquement après la saisie des données
- **Intégration IA** : L'intelligence artificielle est intégrée de manière optionnelle et asynchrone
- **Gestion complète** : Le système couvre tout le cycle de vie d'un établissement (création, consultation, modification, suppression)
- **Actions optionnelles** : Les fonctionnalités avancées (IA, What-If, export) sont disponibles mais non obligatoires

## 8. Flux de données et résultats

Le diagramme illustre comment les données circulent dans le système :

1. **Saisie utilisateur** → Formulaires (FormA1, FormA2, FormB1, etc.)
2. **Persistance** → Backend (création d'établissement)
3. **Traitement** → Calculs et analyses (backend)
4. **Enrichissement** → Prédictions IA (microservice externe)
5. **Présentation** → Affichage des résultats (7 onglets)

## 9. Conclusion

Ce diagramme BPMN fournit une vue complète et structurée des processus métier du système SMART MICROGRID. Il illustre clairement les différents chemins qu'un utilisateur peut emprunter, les décisions qu'il doit prendre, et les résultats qu'il peut obtenir. La modélisation permet de comprendre facilement le flux de travail global, facilite la communication avec les parties prenantes, et sert de référence pour le développement, les tests, et l'amélioration continue du système.


