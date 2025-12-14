import 'package:hospital_microgrid/services/backend_location_service.dart';

/// Zones solaires du Maroc selon le rayonnement solaire
enum SolarZone {
 zone1, // Zone à très fort rayonnement (Sud-Est, Sahara) - Classe A
 zone2, // Zone à fort rayonnement (Centre, Sud) - Classe B
 zone3, // Zone à rayonnement moyen (Nord, Côtes) - Classe C
 zone4, // Zone à rayonnement modr (Rif, Hautes altitudes) - Classe D
}

class SolarZoneService {
 /// Détermine la zone solaire selon les coordonnées GPS depuis le backend
 /// Utilise la Base de données des villes marocaines pour trouver la ville la plus proche
 static Future<SolarZone> getSolarZoneFromLocation(double latitude, double longitude) async {
 try {
 final response = await BackendLocationService.getIrradiationClass(latitude, longitude);
 
 // Convertir la classe d'irradiation (A, B, C, D) en SolarZone
 switch (response.irradiationClass) {
 case 'A':
 return SolarZone.zone1;
 case 'B':
 return SolarZone.zone2;
 case 'C':
 return SolarZone.zone3;
 case 'D':
 return SolarZone.zone4;
 default:
 return SolarZone.zone3; // Par dfaut (Casablanca)
 }
 } catch (e) {
 // En cas d'erreur rseau, utiliser la mthode de fallback locale
 return _getSolarZoneFromLocationFallback(latitude, longitude);
 }
 }

 /// Méthode de fallback si le backend n'est pas disponible
 /// Utilise une logique Basée sur les coordonnées
 static SolarZone _getSolarZoneFromLocationFallback(double latitude, double longitude) {
 // Par dfaut, assigner selon la latitude
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

 /// Obtient le nom de la zone
 static String getZoneName(SolarZone zone) {
 switch (zone) {
 case SolarZone.zone1:
 return 'Zone 1 - Très Fort Rayonnement';
 case SolarZone.zone2:
 return 'Zone 2 - Fort Rayonnement';
 case SolarZone.zone3:
 return 'Zone 3 - Rayonnement Moyen';
 case SolarZone.zone4:
 return 'Zone 4 - Rayonnement Modr';
 }
 }

 /// Obtient la description de la zone
 static String getZoneDescription(SolarZone zone) {
 switch (zone) {
 case SolarZone.zone1:
 return 'Régions du Sud-Est et Sahara\nRayonnement solaire: 6-7 kWh/m²/jour';
 case SolarZone.zone2:
 return 'Centre et Sud du Maroc\nRayonnement solaire: 5-6 kWh/m²/jour';
 case SolarZone.zone3:
 return 'Nord et Côtes\nRayonnement solaire: 4-5 kWh/m²/jour';
 case SolarZone.zone4:
 return 'Rif et Hautes Altitudes\nRayonnement solaire: 3-4 kWh/m²/jour';
 }
 }

 /// Obtient la couleur de la zone
 static int getZoneColor(SolarZone zone) {
 switch (zone) {
 case SolarZone.zone1:
 return 0xFFFF6B35; // Orange vif
 case SolarZone.zone2:
 return 0xFFFFA726; // Orange
 case SolarZone.zone3:
 return 0xFFFFD54F; // Jaune
 case SolarZone.zone4:
 return 0xFF90CAF9; // Bleu clair
 }
 }
}

