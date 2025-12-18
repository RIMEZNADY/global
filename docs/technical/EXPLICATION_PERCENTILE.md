# 📊 Explication : 95e Percentile (P95)

## 🎯 Définition Simple

Le **95e percentile** (P95) signifie que **95% des requêtes sont plus rapides** que cette valeur.

En d'autres termes : **95% des utilisateurs** ont une expérience meilleure ou égale à ce temps de réponse.

---

## 📈 Exemple Concret

Imaginez que vous testez votre API avec JMeter et que vous obtenez ces temps de réponse (en millisecondes) :

```
Requête 1 : 150ms
Requête 2 : 200ms
Requête 3 : 180ms
Requête 4 : 250ms
Requête 5 : 300ms
Requête 6 : 220ms
Requête 7 : 190ms
Requête 8 : 210ms
Requête 9 : 280ms
Requête 10 : 350ms
Requête 11 : 400ms
Requête 12 : 320ms
Requête 13 : 380ms
Requête 14 : 450ms
Requête 15 : 500ms
Requête 16 : 600ms  ← Lente
Requête 17 : 550ms
Requête 18 : 480ms
Requête 19 : 520ms
Requête 20 : 800ms  ← Très lente (exception)
```

### Calcul du 95e Percentile

1. **Trier les valeurs** par ordre croissant :
   ```
   150, 180, 190, 200, 210, 220, 250, 280, 300, 320,
   350, 380, 400, 450, 480, 500, 520, 550, 600, 800
   ```

2. **Calculer la position** : 95% de 20 = 19ème position

3. **Valeur au 95e percentile** : **550ms**

### Interprétation

- ✅ **95% des requêtes** (19 sur 20) ont pris **≤ 550ms**
- ⚠️ **5% des requêtes** (1 sur 20) ont pris **> 550ms** (la requête à 800ms)

---

## 🎯 Pourquoi Utiliser le 95e Percentile ?

### ❌ Problème avec la Moyenne

Si vous utilisez la **moyenne** :
```
Moyenne = (150+180+...+800) / 20 = 380ms
```

**Problème** : La moyenne est faussée par les valeurs extrêmes (800ms).
- La plupart des utilisateurs ont une expérience meilleure que 380ms
- Mais certains ont une très mauvaise expérience (800ms)
- La moyenne ne reflète pas la réalité utilisateur

### ✅ Avantage du 95e Percentile

Le **95e percentile** (550ms) vous dit :
- **95% de vos utilisateurs** ont une expérience ≤ 550ms ✅
- **5% de vos utilisateurs** ont une expérience > 550ms ⚠️

C'est **plus représentatif** de l'expérience utilisateur réelle !

---

## 📊 Comparaison : Moyenne vs Médiane vs 95e Percentile

### Exemple avec 100 requêtes

```
Temps de réponse (ms) :
- 90 requêtes : 200-400ms (rapides)
- 5 requêtes : 500-700ms (lentes)
- 5 requêtes : 1000-2000ms (très lentes, exceptions)
```

**Résultats :**
- **Moyenne** : ~450ms (faussée par les valeurs extrêmes)
- **Médiane (50e percentile)** : ~300ms (50% des requêtes)
- **95e percentile** : ~700ms (95% des requêtes)

**Interprétation :**
- La **médiane** vous dit que la moitié des utilisateurs ont ≤ 300ms
- Le **95e percentile** vous dit que 95% des utilisateurs ont ≤ 700ms
- C'est plus réaliste pour définir un objectif de performance

---

## 🎯 Dans Votre Contexte (Tests de Performance)

### Votre Critère Actuel

```latex
\item Endpoints simples (GET) : < 500ms (95e percentile)
```

**Signification :**
- ✅ **95% des requêtes** vers les endpoints simples doivent répondre en **< 500ms**
- ⚠️ **5% des requêtes** peuvent être plus lentes (mais c'est acceptable)

### Exemple Concret

Vous testez `GET /api/establishments` avec 100 requêtes :

```
Résultats :
- 95 requêtes : 150-450ms ✅
- 4 requêtes : 500-600ms ⚠️ (légèrement au-dessus)
- 1 requête : 800ms ⚠️ (exception, peut être ignorée)

95e percentile = 550ms
```

**Verdict :** ❌ **Échec** (550ms > 500ms)

**Action :** Vous devez optimiser pour que 95% des requêtes soient < 500ms.

---

## 📊 Autres Percentiles Courants

### 50e Percentile (Médiane)
- **50% des requêtes** sont plus rapides
- Utile pour voir le comportement "normal"

### 90e Percentile (P90)
- **90% des requêtes** sont plus rapides
- Moins strict que P95
- Utilisé pour des objectifs moins exigeants

### 95e Percentile (P95) ⭐ **Votre Choix**
- **95% des requêtes** sont plus rapides
- **Standard de l'industrie** pour tests de performance
- Équilibre entre réalisme et exigence

### 99e Percentile (P99)
- **99% des requêtes** sont plus rapides
- Très strict, pour applications critiques
- Utile pour identifier les cas extrêmes

---

## 💡 Pourquoi P95 et Pas P99 ?

### P95 (Votre Choix) ✅
- **Réaliste** pour un projet étudiant
- **95% des utilisateurs** satisfaits = excellent
- **5% d'exceptions** acceptables (réseau lent, charge temporaire)

### P99 (Trop Strict) ❌
- **99% des utilisateurs** satisfaits
- **1% d'exceptions** seulement
- Très difficile à atteindre
- Nécessite beaucoup d'optimisation
- Pas nécessaire pour votre contexte

---

## 🎯 Résumé pour Votre PAQP

### Votre Section Actuelle

```latex
\item Critères de performance (95e percentile) :
\begin{itemize}[leftmargin=*]
    \item Endpoints simples (GET) : < 500ms
    \item Endpoints avec calculs : < 1.5s
    \item Endpoints complexes (simulations avec IA) : < 5s
\end{itemize}
```

### Signification

1. **Endpoints simples < 500ms (P95)**
   - 95% des requêtes doivent répondre en < 500ms
   - 5% peuvent être plus lentes (acceptable)

2. **Endpoints avec calculs < 1.5s (P95)**
   - 95% des requêtes doivent répondre en < 1.5s
   - 5% peuvent être plus lentes (acceptable)

3. **Endpoints complexes < 5s (P95)**
   - 95% des requêtes doivent répondre en < 5s
   - 5% peuvent être plus lentes (acceptable)

---

## ✅ Conclusion

**Le 95e percentile est le bon choix** car :
- ✅ **Standard de l'industrie** pour tests de performance
- ✅ **Réaliste** : 95% des utilisateurs satisfaits = excellent
- ✅ **Pragmatique** : Accepte 5% d'exceptions (normales)
- ✅ **Mesurable** : Facile à calculer avec JMeter

**Votre section est correcte !** 🎉


