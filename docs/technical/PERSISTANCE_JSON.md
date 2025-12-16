# 💾 Persistance JSON - SMART MICROGRID

## 🎯 Vue d'Ensemble

Le projet utilise **JSON** pour la persistance locale et la communication avec le backend. La persistance JSON se fait principalement via **SharedPreferences** pour stocker des données localement sur l'appareil.

---

## 📦 Technologies Utilisées

### **1. Package : `shared_preferences`**
- **Version** : ^2.2.2
- **Usage** : Stockage local clé-valeur persistant
- **Format** : JSON encodé en String

### **2. Package : `dart:convert`**
- **Usage** : Encodage/décodage JSON
- **Fonctions** : `jsonEncode()`, `jsonDecode()`

---

## 🔄 Types de Persistance JSON

### **1. Token JWT (Authentification)**

**Service** : `ApiService` (`lib/services/api_service.dart`)

**Stockage** : Token JWT pour l'authentification

```dart
// Sauvegarde du token
static Future<void> _saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

// Récupération du token
static Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

// Suppression du token (logout)
static Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}
```

**Clé utilisée** : `'auth_token'`

**Format stocké** : String (token JWT)

**Utilisation** :
- Sauvegardé après login/register
- Récupéré automatiquement pour chaque requête API
- Supprimé lors du logout

---

### **2. Brouillons de Formulaires**

**Service** : `DraftService` (`lib/services/draft_service.dart`)

**Stockage** : Données des formulaires pour sauvegarde automatique

#### **A. Brouillon FormA1**

**Clé** : `'establishment_draft_form_a1'`

**Données stockées** :
```json
{
  "institutionType": "CHU",
  "institutionName": "CHU Casablanca",
  "numberOfBeds": 500,
  "latitude": 31.6295,
  "longitude": -7.9811,
  "savedAt": "2024-01-15T10:30:00.000Z"
}
```

**Code** :
```dart
// Sauvegarde
static Future<void> saveFormA1Draft({
  required String institutionType,
  required String institutionName,
  required int numberOfBeds,
  required double? latitude,
  required double? longitude,
}) async {
  final prefs = await SharedPreferences.getInstance();
  
  final draft = {
    'institutionType': institutionType,
    'institutionName': institutionName,
    'numberOfBeds': numberOfBeds,
    'latitude': latitude,
    'longitude': longitude,
    'savedAt': DateTime.now().toIso8601String(),
  };
  
  // Encodage JSON et stockage
  await prefs.setString(_draftFormA1Key, jsonEncode(draft));
}

// Récupération
static Future<Map<String, dynamic>?> getFormA1Draft() async {
  final prefs = await SharedPreferences.getInstance();
  final draftJson = prefs.getString(_draftFormA1Key);
  
  if (draftJson == null) return null;
  
  // Décodage JSON
  return jsonDecode(draftJson) as Map<String, dynamic>;
}
```

#### **B. Brouillon FormA2**

**Clé** : `'establishment_draft_form_a2'`

**Données stockées** :
```json
{
  "solarSurface": 500.0,
  "solarSurfaceMin": 400.0,
  "solarSurfaceMax": 600.0,
  "useIntervalSolar": true,
  "nonCriticalSurface": 200.0,
  "nonCriticalSurfaceMin": 150.0,
  "nonCriticalSurfaceMax": 250.0,
  "useIntervalNonCritical": true,
  "monthlyConsumption": 50000.0,
  "monthlyConsumptionMin": 45000.0,
  "monthlyConsumptionMax": 55000.0,
  "useIntervalConsumption": true,
  "savedAt": "2024-01-15T10:35:00.000Z"
}
```

#### **C. Brouillon FormA5**

**Clé** : `'establishment_draft_form_a5'`

**Données stockées** :
```json
{
  "selectedPanel": "panel_001",
  "selectedBattery": "battery_002",
  "selectedInverter": "inverter_001",
  "selectedController": "controller_001",
  "savedAt": "2024-01-15T10:40:00.000Z"
}
```

#### **D. Méthodes Utilitaires**

```dart
// Supprimer tous les brouillons
static Future<void> clearAllDrafts() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_draftFormA1Key);
  await prefs.remove(_draftFormA2Key);
  await prefs.remove(_draftFormA5Key);
}

// Vérifier si un brouillon existe
static Future<bool> hasDraft() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(_draftFormA1Key) ||
         prefs.containsKey(_draftFormA2Key) ||
         prefs.containsKey(_draftFormA5Key);
}
```

---

## 🔄 Communication Backend (JSON)

### **1. Envoi de Données (jsonEncode)**

**Exemple** : Création d'un établissement

```dart
// EstablishmentService.createEstablishment()
final response = await ApiService.post(
  '/establishments',
  request.toJson(), // Conversion objet → JSON
);

// Dans ApiService.post()
static Future<http.Response> post(
  String endpoint,
  Map<String, dynamic> body,
) async {
  final headers = await _getHeaders();
  final url = Uri.parse('$baseUrl$endpoint');
  
  // Encodage JSON du body
  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(body), // ← Encodage JSON
  );
  
  return response;
}
```

**Format envoyé** :
```json
{
  "name": "CHU Casablanca",
  "type": "CHU",
  "numberOfBeds": 500,
  "latitude": 31.6295,
  "longitude": -7.9811,
  "monthlyConsumptionKwh": 50000.0,
  "solarZone": "A"
}
```

### **2. Réception de Données (jsonDecode)**

**Exemple** : Récupération des résultats

```dart
// EstablishmentService.getComprehensiveResults()
final response = await ApiService.get('/establishments/$id/comprehensive-results');

if (response.statusCode == 200) {
  // Décodage JSON → Map
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data;
}
```

**Format reçu** :
```json
{
  "environmental": {
    "annualPvProduction": 120000.0,
    "co2Avoided": 84.0,
    "equivalentTrees": 4200,
    "equivalentCars": 42
  },
  "globalScore": {
    "score": 75.5,
    "autonomyScore": 30.0,
    "economicScore": 22.5,
    "resilienceScore": 15.0,
    "environmentalScore": 8.0
  },
  "financial": {
    "installationCost": 500000.0,
    "annualSavings": 144000.0,
    "roi": 3.5,
    "npv": 1200000.0,
    "irr": 28.8
  }
}
```

---

## 🏗️ Sérialisation/Désérialisation (fromJson/toJson)

### **1. Modèles avec fromJson/toJson**

**Exemple** : `EstablishmentRequest`

```dart
class EstablishmentRequest {
  final String name;
  final String type;
  final int numberOfBeds;
  final double latitude;
  final double longitude;
  final double monthlyConsumptionKwh;
  final String solarZone;
  
  EstablishmentRequest({
    required this.name,
    required this.type,
    required this.numberOfBeds,
    required this.latitude,
    required this.longitude,
    required this.monthlyConsumptionKwh,
    required this.solarZone,
  });
  
  // Conversion objet → JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'numberOfBeds': numberOfBeds,
      'latitude': latitude,
      'longitude': longitude,
      'monthlyConsumptionKwh': monthlyConsumptionKwh,
      'solarZone': solarZone,
    };
  }
  
  // Conversion JSON → objet
  factory EstablishmentRequest.fromJson(Map<String, dynamic> json) {
    return EstablishmentRequest(
      name: json['name'] as String,
      type: json['type'] as String,
      numberOfBeds: json['numberOfBeds'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      monthlyConsumptionKwh: (json['monthlyConsumptionKwh'] as num).toDouble(),
      solarZone: json['solarZone'] as String,
    );
  }
}
```

### **2. Modèles Complexes avec Nested Objects**

**Exemple** : `IrradiationResponse`

```dart
class IrradiationResponse {
  final String irradiationClass;
  final double latitude;
  final double longitude;
  final NearestCity? nearestCity;
  
  IrradiationResponse({
    required this.irradiationClass,
    required this.latitude,
    required this.longitude,
    this.nearestCity,
  });
  
  factory IrradiationResponse.fromJson(Map<String, dynamic> json) {
    return IrradiationResponse(
      irradiationClass: json['irradiationClass'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      nearestCity: json['nearestCity'] != null
        ? NearestCity.fromJson(json['nearestCity'] as Map<String, dynamic>)
        : null,
    );
  }
}

class NearestCity {
  final String name;
  final String region;
  
  NearestCity({
    required this.name,
    required this.region,
  });
  
  factory NearestCity.fromJson(Map<String, dynamic> json) {
    return NearestCity(
      name: json['name'] as String,
      region: json['region'] as String,
    );
  }
}
```

### **3. Modèles avec Listes**

**Exemple** : `LongTermForecastResponse`

```dart
class LongTermForecastResponse {
  final List<ForecastDay> forecast;
  final List<ConfidenceInterval> confidenceIntervals;
  
  LongTermForecastResponse({
    required this.forecast,
    required this.confidenceIntervals,
  });
  
  factory LongTermForecastResponse.fromJson(Map<String, dynamic> json) {
    return LongTermForecastResponse(
      forecast: (json['forecast'] as List<dynamic>?)
        ?.map((e) => ForecastDay.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
      confidenceIntervals: (json['confidenceIntervals'] as List<dynamic>?)
        ?.map((e) => ConfidenceInterval.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    );
  }
}
```

---

## 📍 Emplacements de Stockage

### **Android**
- **Fichier** : `/data/data/com.example.hospital_microgrid/shared_prefs/`
- **Format** : XML (SharedPreferences utilise XML en interne, mais on stocke du JSON en String)

### **iOS**
- **Fichier** : `Library/Preferences/` dans le bundle de l'app
- **Format** : Plist (SharedPreferences utilise Plist en interne)

### **Web**
- **Stockage** : `localStorage` du navigateur
- **Clé** : Préfixée avec le nom de l'app

---

## 🔐 Sécurité

### **1. Token JWT**
- ✅ Stocké de manière sécurisée via SharedPreferences
- ✅ Supprimé lors du logout
- ✅ Inclus automatiquement dans les headers API

### **2. Brouillons**
- ⚠️ Stockés localement (non chiffrés)
- ⚠️ Accessibles uniquement à l'application
- ✅ Supprimés après création de l'établissement

### **3. Données Sensibles**
- ❌ **Ne JAMAIS stocker** de mots de passe en local
- ❌ **Ne JAMAIS stocker** de données sensibles en JSON non chiffré
- ✅ Utiliser le backend pour stocker les données sensibles

---

## 🔄 Flux Complet de Persistance

### **1. Sauvegarde d'un Brouillon**

```
Utilisateur remplit FormA1
  ↓
DraftService.saveFormA1Draft()
  ↓
Création Map<String, dynamic>
  ↓
jsonEncode(draft) → String JSON
  ↓
SharedPreferences.setString('establishment_draft_form_a1', jsonString)
  ↓
Stockage persistant sur l'appareil
```

### **2. Récupération d'un Brouillon**

```
Application démarre
  ↓
DraftService.getFormA1Draft()
  ↓
SharedPreferences.getString('establishment_draft_form_a1')
  ↓
jsonDecode(jsonString) → Map<String, dynamic>
  ↓
Remplissage automatique du formulaire
```

### **3. Communication Backend**

```
Objet Dart (EstablishmentRequest)
  ↓
toJson() → Map<String, dynamic>
  ↓
jsonEncode() → String JSON
  ↓
HTTP POST avec body JSON
  ↓
Backend reçoit JSON
  ↓
Backend répond avec JSON
  ↓
jsonDecode() → Map<String, dynamic>
  ↓
fromJson() → Objet Dart (EstablishmentResponse)
```

---

## 📊 Résumé des Clés SharedPreferences

| Clé | Type | Usage | Service |
|-----|------|-------|---------|
| `auth_token` | String | Token JWT | ApiService |
| `establishment_draft_form_a1` | String (JSON) | Brouillon FormA1 | DraftService |
| `establishment_draft_form_a2` | String (JSON) | Brouillon FormA2 | DraftService |
| `establishment_draft_form_a5` | String (JSON) | Brouillon FormA5 | DraftService |

---

## 💡 Bonnes Pratiques Appliquées

### **1. Encodage/Décodage**
- ✅ Utilisation de `jsonEncode()` / `jsonDecode()` de `dart:convert`
- ✅ Gestion des erreurs avec try-catch
- ✅ Vérification de null avant décodage

### **2. Modèles de Données**
- ✅ Méthodes `toJson()` et `fromJson()` pour chaque modèle
- ✅ Type safety avec casts explicites
- ✅ Gestion des valeurs optionnelles (null)

### **3. Stockage Local**
- ✅ Clés constantes pour éviter les erreurs
- ✅ Préfixes pour organiser les clés
- ✅ Méthodes utilitaires (clear, has)

### **4. Communication API**
- ✅ Headers `Content-Type: application/json`
- ✅ Encodage automatique dans ApiService
- ✅ Décodage avec gestion d'erreurs

---

## 🎯 Points Importants pour la Présentation

### **À expliquer :**

1. **Persistance locale avec SharedPreferences**
   - Stockage clé-valeur persistant
   - JSON encodé en String
   - Utilisé pour token JWT et brouillons

2. **Sérialisation/Désérialisation**
   - `toJson()` : Objet → JSON
   - `fromJson()` : JSON → Objet
   - Modèles typés pour type safety

3. **Communication Backend**
   - `jsonEncode()` pour envoyer
   - `jsonDecode()` pour recevoir
   - Format JSON standardisé

4. **Sécurité**
   - Token JWT stocké localement
   - Pas de mots de passe en local
   - Brouillons non chiffrés (données non sensibles)

---

## 📝 Exemple Complet

```dart
// 1. Créer un objet
final establishment = EstablishmentRequest(
  name: 'CHU Casablanca',
  type: 'CHU',
  numberOfBeds: 500,
  latitude: 31.6295,
  longitude: -7.9811,
  monthlyConsumptionKwh: 50000.0,
  solarZone: 'A',
);

// 2. Convertir en JSON
final json = establishment.toJson();
// {
//   "name": "CHU Casablanca",
//   "type": "CHU",
//   ...
// }

// 3. Encoder pour envoi
final jsonString = jsonEncode(json);

// 4. Stocker localement (brouillon)
final prefs = await SharedPreferences.getInstance();
await prefs.setString('establishment_draft_form_a1', jsonString);

// 5. Récupérer et décoder
final savedJsonString = prefs.getString('establishment_draft_form_a1');
final savedJson = jsonDecode(savedJsonString!) as Map<String, dynamic>;
final restoredEstablishment = EstablishmentRequest.fromJson(savedJson);
```

---

**La persistance JSON permet de sauvegarder localement les données et de communiquer efficacement avec le backend ! 🚀**

