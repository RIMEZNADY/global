import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/pages/form_a1_page.dart';
import 'package:hospital_microgrid/services/location_service.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class LocationSetupPage extends StatefulWidget {
 const LocationSetupPage({super.key});

 @override
 State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
 bool _isLoading = false;
 bool _permissionGranted = false;
 Position? _currentPosition;
 SolarZone? _solarZone;
 String? _errorMessage;

 @override
 void initState() {
 super.initState();
 _checkPermission();
 }

 Future<void> _checkPermission() async {
 final hasPermission = await LocationService.isLocationPermissionGranted();
 setState(() {
 _permissionGranted = hasPermission;
 });
 }

 Future<void> _requestLocation() async {
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 });

 try {
 // Demander la permission
 final hasPermission = await LocationService.requestLocationPermission();
 
 if (!hasPermission) {
 setState(() {
 _errorMessage = 'Permission de localisation refusé�e. Veuillez l\'aCoûtiver dans les paramé�tres.';
 _isLoading = false;
 });
 return;
 }

 // V�rifier si le GPS est aCoûtiv�
 bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
 if (!serviceEnabled) {
 setState(() {
 _errorMessage = 'Le GPS n\'est pas aCoûtivé�. Veuillez l\'aCoûtiver dans les paramé�tres.';
 _isLoading = false;
 });
 // Proposer d'ouvrir les paramé�tres
 _showEnableGPSDialog();
 return;
 }

 // Obtenir la localisation
 final position = await LocationService.getCurrentLocation();
 
 if (position == null) {
 setState(() {
 _errorMessage = 'Impossible d\'obtenir votre localisation.';
 _isLoading = false;
 });
 return;
 }

 // Dé�terminer la zone solaire depuis le backend
 final zone = await SolarZoneService.getSolarZoneFromLocation(
 position.latitude,
 position.longitude,
 );

 setState(() {
 _currentPosition = position;
 _solarZone = zone;
 _permissionGranted = true;
 _isLoading = false;
 });
 } catch (e) {
 setState(() {
 _errorMessage = 'Erreur: ${e.toString()}';
 _isLoading = false;
 });
 }
 }

 void _showEnableGPSDialog() {
 showDialog(
 context: context,
 builder: (context) => AlertDialog(
 title: const Text('GPS d�saCoûtiv�'),
 content: const Text(
 'Le GPS doit �tre aCoûtiv� pour d�terminer votre zone solaire. '
 'Voulez-vous ouvrir les param�tres ?',
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.pop(context),
 child: const Text('Annuler'),
 ),
 TextButton(
 onPressed: () {
 Navigator.pop(context);
 LocationService.openLocationSettings();
 },
 child: const Text('Ouvrir les param�tres'),
 ),
 ],
 ),
 );
 }

 void _continueToInstitutionChoice() {
 if (_currentPosition != null) {
 Navigator.pushReplacement(
 context,
 MaterialPageRoute(
 builder: (context) => FormA1Page(
 position: _currentPosition!,
 ),
 ),
 );
 }
 }

 @override
 Widget build(BuildContext context) {
 final isDark = Theme.of(context).brightness == Brightness.dark;

 return Scaffold(
 body: SafeArea(
 child: SingleChildScrollView(
 padding: const EdgeInsets.all(24.0),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 const SizedBox(height: 40),
 // Icé�ne GPS
 Container(
 width: 120,
 height: 120,
 decoration: const BoxDecoration(
 shape: BoxShape.circle,
 gradient: LinearGradient(
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 colors: [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.solarGreen,
 ],
 ),
 ),
 child: const Icon(
 Icons.location_on,
 size: 60,
 color: Colors.white,
 ),
 ),
 const SizedBox(height: 32),
 // Titre
 Text(
 'ACoûtivation de la Localisation',
 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
 fontWeight: FontWeight.bold,
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 16),
 // Description
 Text(
 'Pour d�terminer votre zone solaire et optimiser votre microgrid, '
 'nous avons besoin d\'acc�der � votre localisation.',
 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 48),
 // Bouton d'aCoûtivation
 if (!_permissionGranted || _currentPosition == null)
 ElevatedButton(
 onPressed: _isLoading ? null : _requestLocation,
 style: ElevatedButton.styleFrom(
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 child: _isLoading
 ? const SizedBox(
 height: 20,
 width: 20,
 child: CircularProgressIndicator(
 strokeWidth: 2,
 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
 ),
 )
 : const Text(
 'Activer la Localisation',
 style: TextStyle(fontSize: 16),
 ),
 ),
 // R�sultat de la localisation
 if (_currentPosition != null && _solarZone != null) ...[
 const SizedBox(height: 32),
 // Informations de la zone
 Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: isDark
 ? MedicalSolarColors.darkSurface
 : Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: Color(SolarZoneService.getZoneColor(_solarZone!))
 .withOpacity(0.3),
 width: 2,
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Container(
 width: 12,
 height: 12,
 decoration: BoxDecoration(
 shape: BoxShape.circle,
 color: Color(
 SolarZoneService.getZoneColor(_solarZone!),
 ),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Text(
 SolarZoneService.getZoneName(_solarZone!),
 style: const TextStyle(
 fontSize: 18,
 fontWeight: FontWeight.bold,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 12),
 Text(
 SolarZoneService.getZoneDescription(_solarZone!),
 style: TextStyle(
 fontSize: 14,
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 ),
 const SizedBox(height: 16),
 Divider(
 color: isDark
 ? Colors.white24
 : Colors.grey.withOpacity(0.2),
 ),
 const SizedBox(height: 8),
 Row(
 children: [
 Icon(
 Icons.my_location,
 size: 16,
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 const SizedBox(width: 8),
 Text(
 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
 'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
 style: TextStyle(
 fontSize: 12,
 color: isDark
 ? Colors.white60
 : MedicalSolarColors.softGrey.withOpacity(0.6),
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 const SizedBox(height: 24),
 ElevatedButton(
 onPressed: _continueToInstitutionChoice,
 style: ElevatedButton.styleFrom(
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 child: const Text(
 'Continuer',
 style: TextStyle(fontSize: 16),
 ),
 ),
 ],
 // Message d'erreur
 if (_errorMessage != null) ...[
 const SizedBox(height: 24),
 Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: Colors.red.withOpacity(0.1),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(
 color: Colors.red.withOpacity(0.3),
 ),
 ),
 child: Row(
 children: [
 const Icon(Icons.error_outline, color: Colors.red),
 const SizedBox(width: 12),
 Expanded(
 child: Text(
 _errorMessage!,
 style: const TextStyle(color: Colors.red),
 ),
 ),
 ],
 ),
 ),
 ],
 ],
 ),
 ),
 ),
 );
 }
}


