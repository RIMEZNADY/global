import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // URL du backend pour mobile (Android/iOS)
  // Pour Android Emulator: utiliser 10.0.2.2 au lieu de localhost
  // Pour iOS Simulator: utiliser localhost
  // Pour appareil physique: utiliser l'IP de votre machine sur le réseau local
  static String get backendUrl {
    if (kIsWeb || Platform.isIOS) {
      return 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else {
      return 'http://localhost:8080/api'; // Par défaut
    }
  }
  
  // URL du microservice AI
  static String get aiServiceUrl {
    if (kIsWeb || Platform.isIOS) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000'; // Par défaut
    }
  }
}
