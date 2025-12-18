# 📊 Explication : Burndown Chart

## 🎯 Qu'est-ce qu'un Burndown Chart ?

**Burndown Chart** = Graphique qui montre le **travail restant** au fil du temps pendant un sprint.

---

## 📈 Comment ça Fonctionne ?

### Principe

Le graphique montre :
- **Axe X** : Jours du sprint (Jour 1, Jour 2, ..., Jour 14)
- **Axe Y** : Story Points (ou heures) restants

**Ligne idéale** : Ligne droite qui descend de "Travail total" à "0" à la fin du sprint
**Ligne réelle** : Ligne qui montre le travail réellement restant jour par jour

---

## 📊 Exemple Concret

### Sprint de 2 semaines (10 jours)

**Planning Sprint :**
- Total Story Points planifiés : **20 SP**

**Burndown Chart :**

```
Story Points
    │
 20 │●─────────────────────────── (Ligne idéale)
    │ \
 15 │  \
    │   \
 10 │    \
    │     \
  5 │      \
    │       \
  0 │────────●─────────────────── (Ligne réelle)
    └───────────────────────────── Jours
     1  2  3  4  5  6  7  8  9 10
```

### Mise à Jour au Fur et à Mesure

**Jour 1 (Lundi) :**
- Travail restant : 20 SP
- Point sur le graphique : (Jour 1, 20 SP)

**Jour 2 (Mardi) :**
- US complétée : 3 SP
- Travail restant : 17 SP
- Point sur le graphique : (Jour 2, 17 SP)

**Jour 3 (Mercredi) :**
- US complétée : 2 SP
- Travail restant : 15 SP
- Point sur le graphique : (Jour 3, 15 SP)

**Jour 4 (Jeudi) :**
- US complétée : 4 SP
- Travail restant : 11 SP
- Point sur le graphique : (Jour 4, 11 SP)

**... et ainsi de suite jusqu'à la fin du sprint**

---

## ✅ OUI, il doit être mis à jour au fur et à mesure !

### Fréquence de Mise à Jour

**Recommandation :** **Chaque jour** (idéalement en fin de journée)

**Pourquoi ?**
- ✅ Permet de voir l'avancement en temps réel
- ✅ Détecte rapidement si on est en retard
- ✅ Permet d'ajuster si nécessaire

### Qui le Met à Jour ?

**Responsable :** **Scrum Master** ou **Responsable Qualité (RQ)**

**Quand :**
- **Chaque jour** : Mettre à jour le travail restant
- **Daily Standup** : Afficher le graphique et discuter
- **Fin de sprint** : Analyser les écarts

---

## 📋 Comment le Créer et le Maintenir ?

### Méthode 1 : Excel (Simple)

**Étape 1 : Créer le tableau**

| Jour | Date | Travail Restant (SP) | Ligne Idéale |
|------|------|---------------------|--------------|
| 1 | Lun 01/01 | 20 | 20 |
| 2 | Mar 02/01 | 17 | 18 |
| 3 | Mer 03/01 | 15 | 16 |
| 4 | Jeu 04/01 | 11 | 14 |
| 5 | Ven 05/01 | 9 | 12 |
| ... | ... | ... | ... |
| 10 | Ven 12/01 | 0 | 0 |

**Étape 2 : Calculer la ligne idéale**

```
Ligne idéale (Jour N) = Total SP - (Total SP / Nombre de jours) × N
```

Exemple pour 20 SP sur 10 jours :
- Jour 1 : 20 - (20/10) × 1 = 18
- Jour 2 : 20 - (20/10) × 2 = 16
- Jour 3 : 20 - (20/10) × 3 = 14
- ...

**Étape 3 : Créer le graphique**

1. Sélectionner les colonnes "Jour", "Travail Restant", "Ligne Idéale"
2. Insertion → Graphique en ligne
3. Ligne idéale = ligne droite descendante
4. Ligne réelle = ligne qui suit le travail restant

**Étape 4 : Mettre à jour chaque jour**

- À la fin de chaque journée, mettre à jour "Travail Restant"
- Le graphique se met à jour automatiquement

---

### Méthode 2 : GitHub Projects (Automatique)

**Avantage :** Mise à jour automatique

**Configuration :**
1. Créer un projet GitHub
2. Créer un sprint
3. Ajouter les User Stories avec Story Points
4. Marquer les US comme "Done" au fur et à mesure
5. GitHub génère automatiquement le burndown chart

**Fréquence :** Automatique (se met à jour quand vous marquez les US comme "Done")

---

### Méthode 3 : Outils Agile (Jira, Azure DevOps)

**Avantage :** Très complet, automatique

**Configuration :**
1. Créer un sprint
2. Ajouter les User Stories avec Story Points
3. Mettre à jour le statut des US (To Do → In Progress → Done)
4. Le burndown chart se génère automatiquement

---

## 📊 Interprétation du Graphique

### Scénario 1 : En Avance ✅

```
Story Points
    │
 20 │●─────────────────────────── (Idéale)
    │ \
 15 │  \
    │   \
 10 │    \
    │     ●─────── (Réelle - en avance)
  5 │       \
    │        \
  0 │─────────●───────────────────
```

**Signification :** L'équipe avance plus vite que prévu
**Action :** Peut prendre plus de travail ou se détendre

---

### Scénario 2 : En Retard ⚠️

```
Story Points
    │
 20 │●─────────────────────────── (Idéale)
    │ \
 15 │  \
    │   \
 10 │    \
    │     \
  5 │      \
    │       \
    │        ●─────── (Réelle - en retard)
  0 │─────────●───────────────────
```

**Signification :** L'équipe avance moins vite que prévu
**Action :** 
- Réduire le scope (retirer des US)
- Augmenter l'effort
- Identifier les blocages

---

### Scénario 3 : Parfaitement Aligné ✅

```
Story Points
    │
 20 │●─────────────────────────── (Idéale)
    │ \
 15 │  \
    │   \
 10 │    \
    │     \
  5 │      \
    │       \
  0 │────────●─────────────────── (Réelle - alignée)
```

**Signification :** L'équipe suit parfaitement le planning
**Action :** Continuer ainsi

---

## 🎯 Dans Votre Contexte (Projet Étudiant)

### Recommandation Simple

**Option 1 : Excel (Recommandé pour débuter)**
- Créer un fichier Excel
- Mettre à jour chaque jour (5 minutes)
- Afficher en Daily Standup

**Option 2 : GitHub Projects (Si vous utilisez GitHub)**
- Créer un projet GitHub
- Ajouter les User Stories
- Le graphique se génère automatiquement

**Option 3 : Tableau manuel (Très simple)**
- Dessiner sur un tableau blanc
- Mettre à jour chaque jour
- Prendre une photo pour garder l'historique

---

## 📝 Fréquence de Mise à Jour

### Recommandation

**Chaque jour** (idéalement en fin de journée ou début de Daily Standup)

**Processus :**
1. **Fin de journée** : Calculer le travail restant
   - Compter les Story Points des US non complétées
   - Mettre à jour le graphique

2. **Daily Standup** : Afficher et discuter
   - Montrer le graphique
   - Identifier si on est en avance/retard
   - Ajuster si nécessaire

3. **Fin de sprint** : Analyser
   - Comparer ligne réelle vs idéale
   - Identifier les causes d'écarts
   - Ajuster la vélocité pour le prochain sprint

---

## ✅ Résumé

**Burndown Chart :**
- ✅ **OUI**, mis à jour **au fur et à mesure** (chaque jour)
- ✅ Montre le **travail restant** jour par jour
- ✅ Permet de **détecter les retards** rapidement
- ✅ Simple à créer (Excel, GitHub, tableau)

**Fréquence :**
- **Chaque jour** : Mettre à jour le travail restant
- **Daily Standup** : Afficher et discuter
- **Fin de sprint** : Analyser les écarts

**Responsable :**
- Scrum Master ou RQ (Responsable Qualité)

---

## 🎓 Conclusion

**OUI, le burndown chart doit être mis à jour au fur et à mesure !**

C'est un **outil de suivi quotidien** qui permet de :
- ✅ Voir l'avancement en temps réel
- ✅ Détecter les problèmes rapidement
- ✅ Ajuster le planning si nécessaire

**Pour un projet étudiant :** Excel ou GitHub Projects sont parfaits et simples à utiliser.


