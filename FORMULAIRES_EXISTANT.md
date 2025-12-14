# 📋 Éléments des Formulaires - Cas "EXISTANT"

## 🔄 Flux des Formulaires pour "EXISTANT"

**EXISTANT** → `FormA1Page` → `FormA2Page` → `FormA3Page` → `FormA4Page` → `FormA5Page`

---

## 📝 **FORMULAIRE A1** (`form_a1_page.dart`)

### **Titre** : "Identification de l'établissement"

### **Éléments du formulaire** :

1. **Type d'établissement** (HierarchicalTypeSelector)
   - Sélection hiérarchique du type d'établissement
   - Valeurs backend : `CHU`, `HOPITAL_REGIONAL`, etc.
   - **Obligatoire** ✅

2. **Nom de l'établissement** (TextFormField)
   - Exemple : "Hôpital Ibn Sina"
   - **Obligatoire** ✅
   - Validation : Ne peut pas être vide

3. **Nombre de lits** (TextFormField)
   - Type : Nombre entier
   - Exemple : 150
   - **Obligatoire** ✅
   - Validation : Doit être un nombre valide

4. **Localisation** (Carte interactive)
   - Carte avec marqueur pour sélectionner la position
   - Coordonnées GPS (latitude, longitude)
   - Zone solaire automatiquement détectée depuis les coordonnées
   - **Obligatoire** ✅
   - Bouton "Activer GPS" pour obtenir la position actuelle
   - Affichage des coordonnées : `Lat: X.XXXXXX, Lng: Y.YYYYYY`

### **Données transmises à FormA2** :
- `institutionType` (String)
- `institutionName` (String)
- `location` (Position - latitude/longitude)
- `numberOfBeds` (int)

---

## 📝 **FORMULAIRE A2** (`form_a2_page.dart`)

### **Titre** : "Informations techniques"

### **Éléments du formulaire** :

**Tous les champs supportent maintenant le mode "Valeur exacte" ou "Intervalle"** ✅

1. **Surface installable pour panneau solaire (m²)**
   - **Mode 1 : Valeur exacte** (par défaut)
     - Un seul champ numérique
     - Exemple : 500 m²
     - **Obligatoire** ✅
   
   - **Mode 2 : Intervalle** (toggle activable)
     - Champ "Min" (minimum)
     - Champ "Max" (maximum)
     - Exemple : Min 400 m², Max 600 m²
     - **Validation** : Min < Max
     - **Calcul** : Si intervalle, utilise la moyenne (Min + Max) / 2

2. **Surface non critiques dispo (m²)**
   - **Mode 1 : Valeur exacte** (par défaut)
     - Un seul champ numérique
     - Exemple : 200 m²
     - **Obligatoire** ✅
   
   - **Mode 2 : Intervalle** (toggle activable)
     - Champ "Min" (minimum)
     - Champ "Max" (maximum)
     - Exemple : Min 150 m², Max 250 m²
     - **Validation** : Min < Max
     - **Calcul** : Si intervalle, utilise la moyenne (Min + Max) / 2

3. **Consommation mensuelle actuelle (Kwh)**
   - **Mode 1 : Valeur exacte** (par défaut)
     - Un seul champ numérique
     - Exemple : 50000 Kwh
     - **Obligatoire** ✅
   
   - **Mode 2 : Intervalle** (toggle activable)
     - Champ "Min" (minimum)
     - Champ "Max" (maximum)
     - Exemple : Min 40000 Kwh, Max 60000 Kwh
     - **Validation** : Min < Max
     - **Calcul** : Si intervalle, utilise la moyenne (Min + Max) / 2

### **Données transmises à FormA5** (saut direct, pas de A3/A4 dans le flux actuel) :
- `institutionType` (String)
- `institutionName` (String)
- `location` (Position)
- `numberOfBeds` (int)
- `solarSurface` (double) - moyenne si intervalle
- `nonCriticalSurface` (double)
- `monthlyConsumption` (double)
- `recommendedPVPower` (double) - calculé : `solarSurface * 0.2` (200W/m²)
- `recommendedBatteryCapacity` (double) - calculé : `avgHourlyConsumption * 12` (12h d'autonomie)

---

## 📊 **Résumé des Champs Obligatoires**

### **FormA1** :
- ✅ Type d'établissement
- ✅ Nom de l'établissement
- ✅ Nombre de lits
- ✅ Localisation (GPS)

### **FormA2** :
- ✅ Surface installable (exacte ou intervalle)
- ✅ Surface non critiques (exacte ou intervalle)
- ✅ Consommation mensuelle (exacte ou intervalle)

---

## 🔄 **Note sur le Flux**

Dans le code actuel, `FormA2` navigue directement vers `FormA5` (sélection des équipements), en sautant `FormA3` (graphiques) et `FormA4` (recommandations). Cependant, `FormA3` et `FormA4` existent dans le code et peuvent être utilisés si nécessaire.

---

## 📤 **Données Finales Envoyées au Backend**

Lors de la création de l'établissement dans `FormA5`, les données suivantes sont envoyées :

```dart
EstablishmentRequest(
  name: institutionName,                    // Depuis A1
  type: institutionType,                    // Depuis A1
  numberOfBeds: numberOfBeds,               // Depuis A1
  latitude: location.latitude,              // Depuis A1
  longitude: location.longitude,             // Depuis A1
  installableSurfaceM2: solarSurface,       // Depuis A2
  nonCriticalSurfaceM2: nonCriticalSurface,  // Depuis A2
  monthlyConsumptionKwh: monthlyConsumption, // Depuis A2
  existingPvInstalled: false,               // Toujours false pour "EXISTANT"
)
```

