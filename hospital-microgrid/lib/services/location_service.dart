import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class LocationService {
  /// Demande la permission de localisation
  static Future<bool> requestLocationPermission() async {
    // Sur iOS, utiliser UNIQUEMENT Geolocator (plus fiable et ne nécessite pas permission_handler)
    if (Platform.isIOS) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        final granted = permission == LocationPermission.whileInUse || 
                        permission == LocationPermission.always;
        print('iOS Permission status: $permission, granted: $granted');
        return granted;
      } catch (e) {
        print('❌ Erreur Geolocator iOS: $e');
        return false;
      }
    }
    
    // Sur Android, utiliser permission_handler
    try {
      final status = await ph.Permission.location.request();
      
      // Si la permission est refusée définitivement, proposer d'ouvrir les paramètres
      if (status.isPermanentlyDenied) {
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      print('Erreur permission_handler Android: $e');
      // Fallback sur Geolocator pour Android aussi
      try {
        LocationPermission permission = await Geolocator.requestPermission();
        return permission == LocationPermission.whileInUse || 
               permission == LocationPermission.always;
      } catch (_) {
        return false;
      }
    }
  }

  /// Vérifie si la permission est accordée
  static Future<bool> isLocationPermissionGranted() async {
    // Sur iOS, utiliser UNIQUEMENT Geolocator
    if (Platform.isIOS) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        final granted = permission == LocationPermission.whileInUse || 
                        permission == LocationPermission.always;
        return granted;
      } catch (e) {
        print('❌ Erreur vérification permission iOS: $e');
        return false;
      }
    }
    
    // Sur Android, utiliser permission_handler
    try {
      final status = await ph.Permission.location.status;
      return status.isGranted;
    } catch (e) {
      print('Erreur vérification permission Android: $e');
      // Fallback sur Geolocator
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        return permission == LocationPermission.whileInUse || 
               permission == LocationPermission.always;
      } catch (_) {
        return false;
      }
    }
  }
  
  /// Vérifie si la permission est refusée définitivement
  static Future<bool> isPermissionPermanentlyDenied() async {
    // Sur iOS, utiliser UNIQUEMENT Geolocator
    if (Platform.isIOS) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        return permission == LocationPermission.deniedForever;
      } catch (e) {
        print('❌ Erreur vérification deniedForever iOS: $e');
        return false;
      }
    }
    
    // Sur Android, utiliser permission_handler
    try {
      final status = await ph.Permission.location.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      // Fallback sur Geolocator
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        return permission == LocationPermission.deniedForever;
      } catch (_) {
        return false;
      }
    }
  }
  
  /// Ouvre les paramètres de l'application
  static Future<void> openAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (e) {
      print('Erreur lors de l\'ouverture des paramètres: $e');
    }
  }

  /// Obtient la position actuelle de l'utilisateur
  static Future<Position?> getCurrentLocation() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Services de localisation désactivés');
        return null;
      }

      // Vérifier les permissions (utilise la méthode unifiée)
      final hasPermission = await isLocationPermissionGranted();
      if (!hasPermission) {
        // Essayer de demander la permission
        final granted = await requestLocationPermission();
        if (!granted) {
          print('⚠️ Permission de localisation refusée');
          return null;
        }
      }

      // Double vérification avec Geolocator pour être sûr
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          print('⚠️ Permission refusée par Geolocator');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Permission refusée définitivement');
        return null;
      }

      // Obtenir la position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la localisation: $e');
      return null;
    }
  }

 /// Ouvre les paramètres de localisation
 static Future<void> openLocationSettings() async {
 await Geolocator.openLocationSettings();
 }
}

