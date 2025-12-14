import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hospital_microgrid/services/location_service.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class MapPage extends StatefulWidget {
 const MapPage({super.key});

 @override
 State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
 Position? _currentPosition;
 SolarZone? _solarZone;
 bool _isLoading = false;
 String? _errorMessage;
 final MapController _mapController = MapController();

 @override
 void initState() {
 super.initState();
 _loadLocation();
 }

 Future<void> _loadLocation() async {
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 });

 try {
 // V�rifier la permission
 final hasPermission = await LocationService.isLocationPermissionGranted();
 if (!hasPermission) {
 setState(() {
 _errorMessage = 'Permission de localisation requise';
 _isLoading = false;
 });
 return;
 }

 // V�rifier si le GPS est activé�
 bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
 if (!serviceEnabled) {
 setState(() {
 _errorMessage = 'Le GPS n\'est pas activé�';
 _isLoading = false;
 });
 return;
 }

 // Obtenir la localisation
 final position = await LocationService.getCurrentLocation();
 
 if (position == null) {
 setState(() {
 _errorMessage = 'Impossible d\'obtenir votre localisation';
 _isLoading = false;
 });
 return;
 }

 // D�terminer la zone solaire depuis le backend
 final zone = await SolarZoneService.getSolarZoneFromLocation(
 position.latitude,
 position.longitude,
 );

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

 Future<void> _refreshLocation() async {
 await _loadLocation();
 }

 @override
 Widget build(BuildContext context) {
 final isDark = Theme.of(context).brightness == Brightness.dark;

 return Scaffold(
 body: SafeArea(
 child: Column(
 children: [
 // En-t�te avec informations de la zone
 if (_solarZone != null && _currentPosition != null)
 Container(
 padding: const EdgeInsets.all(16),
 decoration: BoxDecoration(
 color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
 boxShadow: [
 BoxShadow(
 color: Colors.black.withOpacity(0.1),
 blurRadius: 4,
 offset: const Offset(0, 2),
 ),
 ],
 ),
 child: Row(
 children: [
 Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(
 color: Color(SolarZoneService.getZoneColor(_solarZone!))
 .withOpacity(0.2),
 borderRadius: BorderRadius.circular(10),
 ),
 child: Icon(
 Icons.wb_sunny,
 color: Color(SolarZoneService.getZoneColor(_solarZone!)),
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 SolarZoneService.getZoneName(_solarZone!),
 style: const TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: 4),
 Text(
 SolarZoneService.getZoneDescription(_solarZone!),
 style: TextStyle(
 fontSize: 12,
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 ),
 ],
 ),
 ),
 IconButton(
 icon: const Icon(Icons.refresh),
 onPressed: _isLoading ? null : _refreshLocation,
 tooltip: 'Actualiser la localisation',
 ),
 ],
 ),
 ),
 // Carte
 Expanded(
 child: Stack(
 children: [
 // Carte g�ographique
 if (_currentPosition != null)
 FlutterMap(
 mapController: _mapController,
 options: MapOptions(
 initialCenter: LatLng(
 _currentPosition!.latitude,
 _currentPosition!.longitude,
 ),
 initialZoom: 12.0,
 minZoom: 5.0,
 maxZoom: 18.0,
 ),
 children: [
 TileLayer(
 urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
 userAgentPackageName: 'com.example.hospital_microgrid',
 maxZoom: 19,
 ),
 MarkerLayer(
 markers: [
 Marker(
 point: LatLng(
 _currentPosition!.latitude,
 _currentPosition!.longitude,
 ),
 width: 60,
 height: 60,
 child: Container(
 decoration: BoxDecoration(
 color: _solarZone != null
 ? Color(SolarZoneService.getZoneColor(_solarZone!))
 : MedicalSolarColors.medicalBlue,
 shape: BoxShape.circle,
 border: Border.all(
 color: Colors.white,
 width: 4,
 ),
 boxShadow: [
 BoxShadow(
 color: (_solarZone != null
 ? Color(SolarZoneService.getZoneColor(_solarZone!))
 : MedicalSolarColors.medicalBlue)
 .withOpacity(0.5),
 blurRadius: 15,
 spreadRadius: 3,
 ),
 ],
 ),
 child: const Icon(
 Icons.location_on,
 color: Colors.white,
 size: 35,
 ),
 ),
 ),
 ],
 ),
 ],
 )
 else
 Center(
 child: _isLoading
 ? const CircularProgressIndicator()
 : Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.location_off,
 size: 64,
 color: isDark
 ? Colors.white54
 : Colors.grey,
 ),
 const SizedBox(height: 16),
 Text(
 _errorMessage ?? 'Localisation non disponible',
 style: TextStyle(
 fontSize: 16,
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 textAlign: TextAlign.center,
 ),
 const SizedBox(height: 24),
 ElevatedButton.icon(
 onPressed: _refreshLocation,
 icon: const Icon(Icons.refresh),
 label: const Text('Actualiser'),
 style: ElevatedButton.styleFrom(
 padding: const EdgeInsets.symmetric(
 horizontal: 24,
 vertical: 12,
 ),
 ),
 ),
 ],
 ),
 ),
 // Bouton pour centrer sur la position
 if (_currentPosition != null)
 Positioned(
 bottom: 20,
 right: 20,
 child: FloatingActionButton(
 onPressed: () {
 _mapController.move(
 LatLng(
 _currentPosition!.latitude,
 _currentPosition!.longitude,
 ),
 12.0,
 );
 },
 backgroundColor: _solarZone != null
 ? Color(SolarZoneService.getZoneColor(_solarZone!))
 : MedicalSolarColors.medicalBlue,
 child: const Icon(Icons.my_location, color: Colors.white),
 ),
 ),
 ],
 ),
 ),
 // Informations de coordonn�es
 if (_currentPosition != null)
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
 border: Border(
 top: BorderSide(
 color: isDark
 ? Colors.white24
 : Colors.grey.withOpacity(0.2),
 ),
 ),
 ),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.gps_fixed,
 size: 16,
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 const SizedBox(width: 8),
 Text(
 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
 'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
 style: TextStyle(
 fontSize: 12,
 color: isDark
 ? Colors.white70
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 );
 }

 @override
 void dispose() {
 _mapController.dispose();
 super.dispose();
 }
}


