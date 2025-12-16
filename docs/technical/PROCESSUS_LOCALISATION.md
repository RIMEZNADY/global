# 📍 Processus de Localisation - SMART MICROGRID

## 🎯 Vue d'Ensemble

Le processus de localisation dans l'application Flutter permet de :
1. **Obtenir la position GPS** de l'utilisateur
2. **Déterminer la zone solaire** (A, B, C, D) selon la position au Maroc
3. **Afficher la position sur une carte** interactive
4. **Utiliser ces données** pour les calculs de dimensionnement

---

## 🔄 Flux Complet du Processus

```
┌─────────────────────────────────────────────────────────────┐
│                    UTILISATEUR CLIQUE                        │
│              "Obtenir ma localisation"                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  ÉTAPE 1 : Vérification Permission                          │
│  LocationService.isLocationPermissionGranted()              │
│  └─→ Utilise permission_handler                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
            ┌──────────┴──────────┐
            │ Permission accordée? │
            └──────────┬──────────┘
                       │
        ┌──────────────┴──────────────┐
        │ NON                          │ OUI
        ▼                              ▼
┌──────────────────┐        ┌──────────────────────────────┐
│ Demander         │        │ ÉTAPE 2 : Vérifier GPS       │
│ Permission       │        │ Geolocator.isLocation        │
│ LocationService. │        │ ServiceEnabled()             │
│ requestLocation  │        └──────────┬───────────────────┘
│ Permission()     │                   │
└──────────────────┘                   ▼
                              ┌──────────────┴──────────────┐
                              │ GPS activé?                  │
                              └──────────────┬──────────────┘
                                             │
                             ┌───────────────┴───────────────┐
                             │ NON                            │ OUI
                             ▼                                ▼
                    ┌──────────────────┐        ┌──────────────────────────┐
                    │ Afficher erreur  │        │ ÉTAPE 3 : Obtenir        │
                    │ "GPS non activé" │        │ Position GPS             │
                    └──────────────────┘        │ LocationService.         │
                                                │ getCurrentLocation()     │
                                                │ └─→ Utilise geolocator   │
                                                └──────────┬───────────────┘
                                                           │
                                                           ▼
                                                ┌──────────────────────────┐
                                                │ Position obtenue?        │
                                                └──────────┬───────────────┘
                                                           │
                                          ┌────────────────┴────────────────┐
                                          │ NON                              │ OUI
                                          ▼                                  ▼
                                 ┌──────────────────┐        ┌──────────────────────────────┐
                                 │ Afficher erreur  │        │ ÉTAPE 4 : Déterminer         │
                                 │ "Impossible      │        │ Zone Solaire                 │
                                 │ d'obtenir        │        │ SolarZoneService.            │
                                 │ localisation"    │        │ getSolarZoneFromLocation()   │
                                 └──────────────────┘        └──────────┬───────────────────┘
                                                                         │
                                                                         ▼
                                                          ┌──────────────────────────────┐
                                                          │ Appel Backend                 │
                                                          │ BackendLocationService.       │
                                                          │ getIrradiationClass()         │
                                                          │ GET /location/irradiation     │
                                                          └──────────┬───────────────────┘
                                                                     │
                                                          ┌──────────┴──────────┐
                                                          │ Backend disponible?  │
                                                          └──────────┬──────────┘
                                                                     │
                                                    ┌────────────────┴────────────────┐
                                                    │ NON                              │ OUI
                                                    ▼                                  ▼
                                        ┌──────────────────┐        ┌──────────────────────────────┐
                                        │ Fallback Local   │        │ Retour Classe Irradiation    │
                                        │ _getSolarZone    │        │ (A, B, C, D)                 │
                                        │ FromLocation     │        │ + Ville la plus proche       │
                                        │ Fallback()       │        └──────────┬───────────────────┘
                                        └──────────────────┘                   │
                                                                               ▼
                                                          ┌──────────────────────────────┐
                                                          │ ÉTAPE 5 : Afficher Résultats │
                                                          │ - Position sur carte          │
                                                          │ - Zone solaire déterminée     │
                                                          │ - Coordonnées GPS             │
                                                          │ - Informations zone           │
                                                          └──────────────────────────────┘
```

---

## 📦 Services Impliqués

### **1. LocationService** (`lib/services/location_service.dart`)

**Responsabilité :** Gestion de la géolocalisation GPS côté Flutter

**Méthodes principales :**

```dart
// 1. Vérifier si la permission est accordée
static Future<bool> isLocationPermissionGranted() async {
  final status = await Permission.location.status;
  return status.isGranted;
}

// 2. Demander la permission
static Future<bool> requestLocationPermission() async {
  final status = await Permission.location.request();
  return status.isGranted;
}

// 3. Obtenir la position actuelle
static Future<Position?> getCurrentLocation() async {
  // Vérifier si GPS activé
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;
  
  // Vérifier permissions
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  
  // Obtenir position
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  
  return position;
}

// 4. Ouvrir les paramètres de localisation
static Future<void> openLocationSettings() async {
  await Geolocator.openLocationSettings();
}
```

**Packages utilisés :**
- `geolocator` : Obtenir la position GPS
- `permission_handler` : Gérer les permissions

---

### **2. SolarZoneService** (`lib/services/solar_zone_service.dart`)

**Responsabilité :** Déterminer la zone solaire selon les coordonnées GPS

**Méthode principale :**

```dart
static Future<SolarZone> getSolarZoneFromLocation(
  double latitude, 
  double longitude
) async {
  try {
    // Appel backend pour obtenir la classe d'irradiation
    final response = await BackendLocationService.getIrradiationClass(
      latitude, 
      longitude
    );
    
    // Convertir classe (A, B, C, D) en SolarZone
    switch (response.irradiationClass) {
      case 'A': return SolarZone.zone1; // Très fort rayonnement
      case 'B': return SolarZone.zone2; // Fort rayonnement
      case 'C': return SolarZone.zone3; // Rayonnement moyen
      case 'D': return SolarZone.zone4; // Rayonnement modéré
      default: return SolarZone.zone3; // Par défaut
    }
  } catch (e) {
    // Fallback si backend indisponible
    return _getSolarZoneFromLocationFallback(latitude, longitude);
  }
}
```

**Méthode de fallback (si backend indisponible) :**

```dart
static SolarZone _getSolarZoneFromLocationFallback(
  double latitude, 
  double longitude
) {
  // Logique basée sur la latitude
  if (latitude < 30.0) {
    return SolarZone.zone1; // Sud (Classe A)
  } else if (latitude < 32.0) {
    return SolarZone.zone2; // Centre (Classe B)
  } else if (latitude < 34.0) {
    return SolarZone.zone3; // Nord (Classe C)
  } else {
    return SolarZone.zone4; // Rif (Classe D)
  }
}
```

**Zones solaires :**

| Zone | Classe | Rayonnement | Régions |
|------|--------|-------------|---------|
| zone1 | A | 6-7 kWh/m²/jour | Sud-Est, Sahara |
| zone2 | B | 5-6 kWh/m²/jour | Centre, Sud |
| zone3 | C | 4-5 kWh/m²/jour | Nord, Côtes |
| zone4 | D | 3-4 kWh/m²/jour | Rif, Hautes altitudes |

---

### **3. BackendLocationService** (`lib/services/backend_location_service.dart`)

**Responsabilité :** Communication avec le backend pour obtenir la classe d'irradiation

**Méthode principale :**

```dart
static Future<IrradiationResponse> getIrradiationClass(
  double latitude,
  double longitude,
) async {
  // Appel API backend
  final response = await ApiService.get(
    '/location/irradiation?latitude=$latitude&longitude=$longitude',
    includeAuth: false, // Endpoint public
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return IrradiationResponse.fromJson(data);
  } else {
    throw Exception('Erreur: ${response.statusCode}');
  }
}
```

**Réponse du backend :**

```json
{
  "irradiationClass": "A",
  "latitude": 31.6295,
  "longitude": -7.9811,
  "nearestCity": {
    "name": "Marrakech",
    "region": "Marrakech-Safi"
  }
}
```

---

## 🎨 Utilisation dans les Pages

### **Exemple : FormA1Page**

```dart
class _FormA1PageState extends State<FormA1Page> {
  Position? _currentPosition;
  SolarZone? _solarZone;
  bool _isLoading = false;
  
  // Méthode appelée quand l'utilisateur clique sur "Obtenir ma localisation"
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ÉTAPE 1 : Vérifier/Demander permission
      final hasPermission = await LocationService.requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Permission de localisation requise';
          _isLoading = false;
        });
        return;
      }

      // ÉTAPE 2 : Vérifier si GPS activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Le GPS n\'est pas activé';
          _isLoading = false;
        });
        return;
      }

      // ÉTAPE 3 : Obtenir position GPS
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage = 'Impossible d\'obtenir votre localisation';
          _isLoading = false;
        });
        return;
      }

      // ÉTAPE 4 : Déterminer zone solaire
      final zone = await SolarZoneService.getSolarZoneFromLocation(
        position.latitude,
        position.longitude,
      );

      // ÉTAPE 5 : Mettre à jour l'état
      setState(() {
        _currentPosition = position;
        _solarZone = zone;
        _isLoading = false;
      });

      // Centrer la carte sur la position
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        12.0,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
```

---

## 🗺️ Affichage sur la Carte

### **Utilisation de flutter_map**

```dart
FlutterMap(
  mapController: _mapController,
  options: MapOptions(
    initialCenter: LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    ),
    initialZoom: 12.0,
  ),
  children: [
    // Tiles OpenStreetMap
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.hospital_microgrid',
    ),
    // Marqueur de position
    MarkerLayer(
      markers: [
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Color(SolarZoneService.getZoneColor(_solarZone!)),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Icon(Icons.location_on, color: Colors.white),
          ),
        ),
      ],
    ),
  ],
)
```

---

## 🔐 Gestion des Permissions

### **Android (android/app/src/main/AndroidManifest.xml)**

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### **iOS (ios/Runner/Info.plist)**

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cette application a besoin de votre localisation pour déterminer la zone solaire.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Cette application a besoin de votre localisation pour déterminer la zone solaire.</string>
```

---

## ⚠️ Gestion des Erreurs

### **Cas d'erreur possibles :**

1. **Permission refusée**
   - Message : "Permission de localisation requise"
   - Solution : Rediriger vers les paramètres

2. **GPS désactivé**
   - Message : "Le GPS n'est pas activé"
   - Solution : Proposer d'ouvrir les paramètres GPS

3. **Position non disponible**
   - Message : "Impossible d'obtenir votre localisation"
   - Solution : Réessayer ou saisie manuelle

4. **Backend indisponible**
   - Fallback : Utiliser la méthode locale basée sur latitude
   - L'application continue de fonctionner

---

## 📊 Données Utilisées

### **Position GPS (Position)**

```dart
class Position {
  double latitude;   // Ex: 31.6295
  double longitude;  // Ex: -7.9811
  double accuracy;   // Précision en mètres
  double altitude;   // Altitude en mètres
  double speed;      // Vitesse en m/s
  DateTime timestamp; // Date/heure
}
```

### **Zone Solaire (SolarZone)**

```dart
enum SolarZone {
  zone1, // Classe A - Très fort rayonnement
  zone2, // Classe B - Fort rayonnement
  zone3, // Classe C - Rayonnement moyen
  zone4, // Classe D - Rayonnement modéré
}
```

### **Réponse Backend (IrradiationResponse)**

```dart
class IrradiationResponse {
  String irradiationClass;  // "A", "B", "C", ou "D"
  double latitude;
  double longitude;
  NearestCity? nearestCity; // Ville la plus proche
}
```

---

## 🎯 Utilisation des Données

Une fois la localisation obtenue, les données sont utilisées pour :

1. **Calculs de dimensionnement**
   - La zone solaire détermine l'irradiation moyenne
   - Utilisée dans `PvCalculationService` pour calculer la production PV

2. **Affichage dans les formulaires**
   - Coordonnées GPS affichées
   - Zone solaire affichée avec description
   - Carte interactive avec marqueur

3. **Envoi au backend**
   - Latitude/longitude envoyées lors de la création d'établissement
   - Zone solaire utilisée pour les calculs backend

---

## 🔄 Rafraîchissement Automatique

Dans certaines pages (MapPage), un bouton permet de rafraîchir la localisation :

```dart
Future<void> _refreshLocation() async {
  await _loadLocation(); // Relance tout le processus
}
```

---

## 📝 Résumé du Processus

1. ✅ **Vérification permission** → `LocationService.isLocationPermissionGranted()`
2. ✅ **Demande permission si nécessaire** → `LocationService.requestLocationPermission()`
3. ✅ **Vérification GPS activé** → `Geolocator.isLocationServiceEnabled()`
4. ✅ **Obtenir position GPS** → `LocationService.getCurrentLocation()`
5. ✅ **Déterminer zone solaire** → `SolarZoneService.getSolarZoneFromLocation()`
   - Appel backend : `BackendLocationService.getIrradiationClass()`
   - Fallback local si backend indisponible
6. ✅ **Afficher résultats** → Carte, coordonnées, zone solaire

---

## 💡 Points Importants pour la Présentation

### **À expliquer :**

1. **Séparation des responsabilités**
   - `LocationService` : GPS côté Flutter
   - `SolarZoneService` : Logique métier zone solaire
   - `BackendLocationService` : Communication API

2. **Gestion des erreurs robuste**
   - Vérifications à chaque étape
   - Messages d'erreur clairs
   - Fallback si backend indisponible

3. **Expérience utilisateur**
   - Permissions gérées automatiquement
   - Feedback visuel (loading, erreurs)
   - Carte interactive avec marqueur

4. **Packages Flutter utilisés**
   - `geolocator` : GPS
   - `permission_handler` : Permissions
   - `flutter_map` : Cartes
   - `latlong2` : Coordonnées

---

**Ce processus garantit une localisation fiable et une détermination précise de la zone solaire pour les calculs de dimensionnement ! 🚀**

