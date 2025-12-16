# Explication du Diagramme de Cas d'Utilisation - SMART MICROGRID

## 1. Vue d'ensemble

Le diagramme de cas d'utilisation présenté modélise les interactions entre les acteurs principaux du système SMART MICROGRID et les fonctionnalités offertes par l'application. Ce diagramme permet de visualiser de manière claire et structurée les différents scénarios d'utilisation du système de gestion de microgrids solaires pour établissements médicaux.

## 2. Acteurs identifiés

Le système met en relation deux acteurs principaux :

- **Utilisateur** : Représente les managers, ingénieurs ou responsables d'établissements médicaux qui utilisent l'application pour gérer leurs projets de microgrids solaires. Cet acteur interagit directement avec la majorité des fonctionnalités du système.

- **Service IA** : Représente le microservice d'intelligence artificielle externe qui fournit des prédictions et des analyses avancées. Cet acteur est sollicité de manière asynchrone pour enrichir les résultats avec des prévisions et des recommandations basées sur l'apprentissage automatique.

## 3. Packages fonctionnels

Le diagramme organise les cas d'utilisation en cinq packages logiques :

### 3.1. Authentification
Ce package regroupe les fonctionnalités de gestion de compte utilisateur :
- **S'inscrire** : Permet à un nouvel utilisateur de créer un compte dans le système.
- **Se connecter** : Permet à un utilisateur existant d'accéder à son espace personnel.
- **Gérer son profil** : Permet de consulter et modifier les informations personnelles de l'utilisateur.

### 3.2. Gestion des Établissements
Ce package couvre toutes les opérations CRUD (Create, Read, Update, Delete) sur les établissements médicaux :
- **Créer un établissement** : Permet d'ajouter un nouvel établissement au profil de l'utilisateur.
- **Lister ses établissements** : Affiche la liste de tous les établissements associés à l'utilisateur.
- **Consulter un établissement** : Permet de visualiser les détails d'un établissement spécifique.
- **Modifier un établissement** : Permet de mettre à jour les informations d'un établissement existant.
- **Supprimer un établissement** : Permet de retirer un établissement du profil utilisateur.

### 3.3. Workflow EXISTANT
Ce package concerne le processus de configuration pour un établissement médical déjà en fonctionnement :
- **Saisir données établissement existant** : Permet d'entrer les données réelles de consommation, configuration actuelle, et caractéristiques techniques de l'établissement.
- **Sélectionner équipements** : Permet de choisir les équipements solaires (panneaux photovoltaïques, batteries) à installer ou à remplacer.

### 3.4. Workflow NEW
Ce package concerne le processus de dimensionnement pour un nouveau projet :
- **Définir nouveau projet** : Permet de spécifier les caractéristiques d'un projet de microgrid solaire pour un établissement en phase de conception ou de construction.

### 3.5. Résultats et Analyses
Ce package regroupe toutes les fonctionnalités de visualisation et d'analyse des résultats :
- **Consulter résultats complets** : Affiche une vue d'ensemble complète des résultats de dimensionnement, incluant les analyses financières, techniques et environnementales.
- **Voir prédictions IA** : Permet d'accéder aux prévisions générées par le service d'intelligence artificielle (consommation future, anomalies, recommandations ML).
- **Simuler scénarios What-If** : Permet de tester différents scénarios en modifiant des paramètres (puissance PV, capacité batterie, consommation) pour voir l'impact sur les résultats.
- **Exporter/Partager résultats** : Permet de générer des rapports PDF ou de partager les résultats avec d'autres parties prenantes.

## 4. Relations entre cas d'utilisation

### 4.1. Relations d'inclusion (<<include>>)

Les relations d'inclusion indiquent qu'un cas d'utilisation inclut nécessairement un autre cas d'utilisation :

- **Créer un établissement** inclut soit le **Workflow EXISTANT** soit le **Workflow NEW**, selon le type d'établissement à configurer.
- Les deux workflows (EXISTANT et NEW) incluent la **Sélection d'équipements**, étape commune à tous les projets.
- La **Sélection d'équipements** inclut nécessairement la consultation des **Résultats complets**, qui sont générés automatiquement après la sélection.

### 4.2. Relations d'extension (<<extend>>)

Les relations d'extension indiquent qu'un cas d'utilisation peut optionnellement étendre un autre cas d'utilisation :

- **Voir prédictions IA** étend la consultation des **Résultats complets** : l'utilisateur peut optionnellement activer cette fonctionnalité pour enrichir les résultats avec des analyses IA.
- **Simuler scénarios What-If** étend également la consultation des **Résultats complets** : l'utilisateur peut optionnellement tester différents scénarios à partir de la page de résultats.

### 4.3. Relations d'utilisation (<<uses>>)

- **Voir prédictions IA** utilise le **Service IA** : cette fonctionnalité fait appel au microservice externe pour obtenir les prédictions et analyses avancées.

## 5. Flux fonctionnel principal

Le flux principal d'utilisation du système suit cette séquence logique :

1. **Authentification** : L'utilisateur s'inscrit ou se connecte à son compte.
2. **Gestion des établissements** : L'utilisateur crée ou sélectionne un établissement.
3. **Configuration du projet** : 
   - Pour un établissement existant : saisie des données réelles → sélection des équipements
   - Pour un nouveau projet : définition du projet → sélection des équipements
4. **Consultation des résultats** : Affichage automatique des résultats complets après la sélection des équipements.
5. **Analyses avancées** (optionnel) : L'utilisateur peut activer les prédictions IA ou tester des scénarios What-If.
6. **Export/Partage** : L'utilisateur peut exporter ou partager les résultats obtenus.

## 6. Points clés du diagramme

- **Séparation claire des workflows** : Le système distingue deux parcours utilisateur distincts selon que l'établissement existe déjà ou est en projet.
- **Modularité** : Les fonctionnalités sont organisées en packages logiques facilitant la compréhension et la maintenance.
- **Extensibilité** : Les relations d'extension permettent d'ajouter des fonctionnalités optionnelles sans modifier le flux principal.
- **Intégration IA** : Le système intègre de manière optionnelle un service d'intelligence artificielle pour enrichir les analyses.

## 7. Conclusion

Ce diagramme de cas d'utilisation fournit une vision claire et structurée des fonctionnalités du système SMART MICROGRID. Il met en évidence les interactions entre l'utilisateur et le système, ainsi que l'intégration d'un service externe d'intelligence artificielle. La modélisation permet de comprendre facilement les différents scénarios d'utilisation et les flux fonctionnels, facilitant ainsi la communication avec les parties prenantes et guidant le développement et les tests du système.


