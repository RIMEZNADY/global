# 🎯 Génération du Dataset ROI d'Entraînement

## 📊 Objectif

Créer un dataset synthétique complet et persisté pour améliorer les performances du modèle ROI.

## 🚀 Utilisation

### 1. Générer le dataset

```bash
cd ai_microservices
python scripts/generate_roi_training_dataset.py
```

Cela va :
- Générer **1200 échantillons** couvrant tous les types d'établissements
- Sauvegarder dans `data_clean/roi_training_dataset.json` et `.parquet`
- Afficher des statistiques détaillées

### 2. Entraîner le modèle avec le nouveau dataset

Le modèle chargera automatiquement le dataset depuis le fichier lors de l'entraînement :

```bash
python -m src.train_roi_model
```

Ou via l'API :

```bash
curl -X POST http://localhost:8000/api/train/roi
```

## ✅ Avantages

1. **Performance améliorée** : 1200 échantillons vs 200 précédemment (6x plus)
2. **Couverture complète** : Tous les 17 types d'établissements avec variantes
3. **Réutilisable** : Dataset persisté, pas besoin de régénérer à chaque fois
4. **Rapide** : Chargement Parquet plus rapide que génération
5. **Reproductible** : Même dataset = mêmes résultats

## 📈 Amélioration Attendue

- **Précision ROI** : +15-25% grâce à plus de données
- **Couverture types** : 100% des types (vs 41% précédemment)
- **Robustesse** : Meilleure généralisation sur cas marginaux
- **Temps d'entraînement** : Plus rapide (chargement vs génération)

## 🔄 Mise à jour du Dataset

Pour régénérer le dataset avec plus d'échantillons :

1. Modifier `num_samples` dans `scripts/generate_roi_training_dataset.py`
2. Exécuter le script
3. Réentraîner le modèle









