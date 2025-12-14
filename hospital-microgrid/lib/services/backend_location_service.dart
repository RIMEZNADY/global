import 'dart:convert';
import 'package:hospital_microgrid/services/api_service.dart';

/// Service pour obtenir la classe d'irradiation solaire depuis le backend
class BackendLocationService {
 /// Obtient la classe d'irradiation solaire selon les coordonnes GPS
 /// Retourne la classe d'irradiation (A, B, C, D) et la ville la plus proche
 static Future<IrradiationResponse> getIrradiationClass(
 double latitude,
 double longitude,
 ) async {
 try {
 final response = await ApiService.get(
 '/location/irradiation?latitude=$latitude&longitude=$longitude',
 includeAuth: false, // Endpoint public
 );

 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return IrradiationResponse.fromJson(data);
 } else {
      throw Exception('Erreur lors de la récupération de la classe d\'irradiation: ${response.statusCode}');
 }
 } catch (e) {
 throw Exception('Erreur rseau: $e');
 }
 }
}

/// Réponse de l'endpoint d'irradiation
class IrradiationResponse {
 final String irradiationClass; // A, B, C, D
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

 /// Convertit la classe d'irradiation (A, B, C, D) en SolarZone
 /// A -> zone1, B -> zone2, C -> zone3, D -> zone4
 String get solarZoneName {
 switch (irradiationClass) {
 case 'A':
 return 'zone1';
 case 'B':
 return 'zone2';
 case 'C':
 return 'zone3';
 case 'D':
 return 'zone4';
 default:
 return 'zone3'; // Par dfaut (Casablanca)
 }
 }
}

/// Informations sur la ville la plus proche
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

