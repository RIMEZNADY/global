import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
 /// Demande la permission de localisation
 static Future<bool> requestLocationPermission() async {
 final status = await Permission.location.request();
 return status.isGranted;
 }

 /// Vrifie si la permission est accorde
 static Future<bool> isLocationPermissionGranted() async {
 final status = await Permission.location.status;
 return status.isGranted;
 }

 /// Obtient la position actuelle de l'utilisateur
 static Future<Position?> getCurrentLocation() async {
 try {
 // Vrifier si les services de localisation sont aCoûtivs
 bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
 if (!serviceEnabled) {
 return null;
 }

 // Vrifier les permissions
 LocationPermission permission = await Geolocator.checkPermission();
 if (permission == LocationPermission.denied) {
 permission = await Geolocator.requestPermission();
 if (permission == LocationPermission.denied) {
 return null;
 }
 }

 if (permission == LocationPermission.deniedForever) {
 return null;
 }

 // Obtenir la position
 Position position = await Geolocator.getCurrentPosition(
 desiredAccuracy: LocationAccuracy.high,
 );

 return position;
 } catch (e) {
 print('Erreur lors de la rcupration de la localisation: $e');
 return null;
 }
 }

 /// Ouvre les paramètres de localisation
 static Future<void> openLocationSettings() async {
 await Geolocator.openLocationSettings();
 }
}

