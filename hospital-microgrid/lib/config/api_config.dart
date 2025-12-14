class ApiConfig {
  // URL du backend pour mobile (Android/iOS)
  // Pour Android Emulator: utiliser 10.0.2.2 au lieu de localhost
  // Pour iOS Simulator: utiliser localhost
  // Pour appareil physique: utiliser l'IP de votre machine sur le réseau local
  static const String backendUrl = 'http://10.0.2.2:8080/api'; // Android Emulator par défaut
  
  // URL du microservice AI
  static const String aiServiceUrl = 'http://10.0.2.2:5000'; // Android Emulator par défaut
}
