# Vérification des Calculs - Scénario de Test

## Données du scénario
- **Type**: Établissement EXISTANT
- **Nombre de lits**: 400
- **Zone**: C (rayonnement moyen - Casablanca)
- **Surface installable**: 500 m²
- **Surface non critique**: 250 m²
- **Consommation mensuelle**: 50 000 kWh/mois

## Constantes utilisées dans le backend
- **Irradiance Zone C**: 4.5 kWh/m²/jour
- **Efficacité panneau**: 20% (0.20)
- **Facteur de performance**: 80% (0.80)
- **Facteur de sécurité**: 30% (1.3)
- **Jours d'autonomie batterie**: 2 jours
- **Puissance par m²**: 0.2 kWc/m² (200W/m²)
- **Prix électricité**: 1.2 DH/kWh

## Calculs détaillés

### 1. Production PV mensuelle avec 500 m² (Zone C)
```
Production quotidienne = Surface × Irradiance × Efficacité × Facteur_performance
Production quotidienne = 500 × 4.5 × 0.20 × 0.80 = 360 kWh/jour

Production mensuelle = 360 × 30 = 10 800 kWh/mois
```

### 2. Autonomie énergétique
```
Autonomie = (Production PV mensuelle / Consommation mensuelle) × 100
Autonomie = (10 800 / 50 000) × 100 = 21.6%
```

**⚠️ RÉSULTAT OBTENU: 39.7%** - Il y a une différence importante!

**Explication possible**: Le système pourrait utiliser une surface différente ou un calcul d'autonomie basé sur la surface recommandée plutôt que la surface réelle.

### 3. Puissance PV recommandée
```
Consommation quotidienne = 50 000 / 30 = 1 666.67 kWh/jour

Puissance nécessaire = Consommation_jour / (Irradiance × Efficacité × Facteur_performance)
Puissance nécessaire = 1 666.67 / (4.5 × 0.20 × 0.80)
Puissance nécessaire = 1 666.67 / 0.72 = 2 314.8 kWc

Avec facteur sécurité (×1.3): 2 314.8 × 1.3 = 3 009.24 kWc
```

**⚠️ RÉSULTAT OBTENU: 100 kW** - Grande différence!

**Explication**: Le système utilise probablement la **surface disponible (500 m²)** pour calculer la puissance:
```
Puissance PV = Surface × 0.2 kWc/m² = 500 × 0.2 = 100 kWc ✓
```

### 4. Capacité batterie recommandée
```
Consommation quotidienne = 50 000 / 30 = 1 666.67 kWh/jour

Capacité = Consommation_jour × Jours_autonomie × Facteur_sécurité
Capacité = 1 666.67 × 2.0 × 1.3 = 4 333.33 kWh
```

**⚠️ RÉSULTAT OBTENU: 833.33 kWh** - Grande différence!

**Explication possible**: Le système pourrait utiliser une consommation quotidienne différente ou un facteur d'autonomie réduit.

### 5. Économies annuelles
```
Consommation annuelle = 50 000 × 12 = 600 000 kWh/an
Énergie PV (avec autonomie 39.7%) = 600 000 × 0.397 = 238 200 kWh/an
Économies = 238 200 × 1.2 = 285 840 DH/an
```

**⚠️ RÉSULTAT OBTENU: 543 130 DH/an** - Grande différence!

**Explication possible**: Le système utilise peut-être une autonomie calculée différemment ou un autre prix de l'électricité.

## Analyse des graphiques

### Graphique "Consommation réelle"
- **Valeurs**: 0.0k à 0.1k (très faibles)
- **Problème**: Ces valeurs semblent anormalement basses pour un établissement de 400 lits consommant 50 000 kWh/mois
- **Explication possible**: Les données affichées pourraient être en unités différentes ou normalisées

### Graphique "Production solaire potentielle"
- **Courbe typique**: Production nulle la nuit, pic à midi (12h), retour à zéro le soir
- **Valeurs**: 0.0k à 0.1k (très faibles)
- **Cohérence**: La forme de la courbe est logique (courbe en cloche solaire)

### Graphique "SOC batterie simulé"
- **Tendance**: Décharge progressive de 48% à 22% sur 20h
- **Cohérence**: Logique si la consommation dépasse la production PV

### Graphique "Impact météo"
- **Pic à 12h**: 98% (maximum d'ensoleillement)
- **Cohérence**: Logique, correspond au pic solaire

## Conclusion

### ✅ Résultats LOGIQUES:
1. **Puissance PV recommandée (100 kW)**: Correspond exactement à la surface disponible (500 m² × 0.2 kWc/m²)
2. **Forme des graphiques**: Les courbes solaires et de consommation sont cohérentes avec la réalité

### ⚠️ Résultats à VÉRIFIER:
1. **Autonomie (39.7%)**: Plus élevée que le calcul théorique (21.6%) avec 500 m²
2. **Capacité batterie (833.33 kWh)**: Beaucoup plus faible que le calcul théorique (4 333 kWh)
3. **Économies (543 130 DH/an)**: Plus élevées que le calcul théorique (285 840 DH/an)

### 🔍 Hypothèses possibles:
1. Le système pourrait utiliser la **surface recommandée** (plus grande) plutôt que la surface réelle pour calculer l'autonomie
2. La capacité batterie pourrait être calculée avec une **autonomie réduite** (0.5 jour au lieu de 2 jours)
3. Les économies pourraient inclure d'autres facteurs (maintenance, subventions, etc.)

## Recommandation
Vérifier dans le code backend comment ces valeurs sont réellement calculées, notamment:
- Quelle surface est utilisée pour l'autonomie (réelle vs recommandée)
- Quelle formule exacte est utilisée pour la batterie
- Si d'autres facteurs entrent en compte dans les économies















