import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hospital_microgrid/services/location_service.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/pages/form_b2_page.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class FormB1Page extends StatefulWidget {
  const FormB1Page({super.key});

  @override
  State<FormB1Page> createState() => _FormB1PageState();
}

class _FormB1PageState extends State<FormB1Page> {
  Position? _currentPosition;
  SolarZone? _solarZone;
  bool _isLoading = false;
  String? _errorMessage;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Verifier la permission au demarrage et demander si necessaire
    _checkAndRequestLocation();
    
    // Initialiser la carte sur Casablanca après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(
          const LatLng(33.5731, -7.5898), // Casablanca
          12.0,
        );
      }
    });
  }

  Future<void> _checkAndRequestLocation() async {
    final hasPermission = await LocationService.isLocationPermissionGranted();
    if (!hasPermission) {
      // Ne pas charger automatiquement, attendre que l'utilisateur clique sur le bouton
      setState(() {
        _errorMessage = 'Activation de la localisation requise';
      });
    } else {
      // Si la permission existe, charger automatiquement
      await _loadLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _updateLocationFromMap(double latitude, double longitude) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Creer une Position depuis les coordonnees
      final position = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      // Determiner la zone solaire depuis le backend
      final zone = await SolarZoneService.getSolarZoneFromLocation(
        latitude,
        longitude,
      );

      setState(() {
        _currentPosition = position;
        _solarZone = zone;
        _isLoading = false;
      });

      // Centrer la carte sur la nouvelle position avec animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(
            LatLng(latitude, longitude),
            _mapController.camera.zoom,
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise a jour: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier si la permission est refusée définitivement
      final isPermanentlyDenied = await LocationService.isPermissionPermanentlyDenied();
      if (isPermanentlyDenied) {
        setState(() {
          _errorMessage = 'Permission refusée définitivement. Veuillez l\'activer dans les paramètres.';
          _isLoading = false;
        });
        _showOpenSettingsDialog();
        return;
      }
      
      // Request permission
      final hasPermission = await LocationService.requestLocationPermission();
      
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Permission de localisation requise';
          _isLoading = false;
        });
        return;
      }

      // Check if GPS is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Le GPS n\'est pas active';
          _isLoading = false;
        });
        return;
      }

      // Get location
      final position = await LocationService.getCurrentLocation();
      
      if (position == null) {
        setState(() {
          _errorMessage = 'Impossible d\'obtenir votre localisation';
          _isLoading = false;
        });
        // Centrer sur Casablanca si pas de position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(
              const LatLng(33.5731, -7.5898), // Casablanca
              12.0,
            );
          }
        });
        return;
      }

      // Vérifier que la position est raisonnable (pas San Francisco par défaut du simulateur)
      // Si la position est en dehors du Maroc (latitude < 20 ou > 36, longitude < -17 ou > -1)
      // Utiliser Casablanca par défaut
      if (position.latitude < 20 || position.latitude > 36 || 
          position.longitude < -17 || position.longitude > -1) {
        print('⚠️ Position GPS invalide (hors Maroc): ${position.latitude}, ${position.longitude}');
        print('   Utilisation de Casablanca par défaut');
        // Utiliser Casablanca comme position par défaut
        final casablancaPosition = Position(
          latitude: 33.5731,
          longitude: -7.5898,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        
        final zone = await SolarZoneService.getSolarZoneFromLocation(
          33.5731,
          -7.5898,
        );
        
        setState(() {
          _currentPosition = casablancaPosition;
          _solarZone = zone;
          _isLoading = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(
              const LatLng(33.5731, -7.5898),
              12.0,
            );
          }
        });
        return;
      }

      // Determine solar zone from backend
      final zone = await SolarZoneService.getSolarZoneFromLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _solarZone = zone;
        _isLoading = false;
      });

      // Center map on position (après que le widget soit rendu)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentPosition != null) {
          _mapController.move(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            12.0,
          );
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission refusée'),
        content: const Text(
          'La permission de localisation a été refusée définitivement. '
          'Voulez-vous ouvrir les paramètres pour l\'activer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService.openAppSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentPosition == null || _solarZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez activer le GPS et obtenir votre localisation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormB2Page(
          position: _currentPosition!,
          solarZone: _solarZone!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activation GPS & Carte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? MedicalSolarColors.softGrey : MedicalSolarColors.offWhite,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with zone info
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(SolarZoneService.getZoneColor(_solarZone!))
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.wb_sunny,
                          color: Color(SolarZoneService.getZoneColor(_solarZone!)),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              SolarZoneService.getZoneName(_solarZone!),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              SolarZoneService.getZoneDescription(_solarZone!),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : MedicalSolarColors.softGrey.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.gps_fixed,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : MedicalSolarColors.softGrey.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
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
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _isLoading ? null : _loadLocation,
                        tooltip: 'Actualiser',
                      ),
                    ],
                  ),
                ),
              // Map
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition != null
                            ? LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              )
                            : const LatLng(33.5731, -7.5898), // Casablanca par defaut
                        initialZoom: 12.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                        onTap: (tapPosition, point) async {
                          // Selection manuelle sur la carte
                          await _updateLocationFromMap(point.latitude, point.longitude);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.hospital_microgrid',
                          maxZoom: 19,
                        ),
                        if (_currentPosition != null)
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
                    ),
                    // Overlay pour le chargement ou les erreurs
                    if (_isLoading || (_currentPosition == null && _errorMessage != null))
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [MedicalSolarColors.medicalBlue, MedicalSolarColors.solarGreen],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.location_off,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _errorMessage ?? 'Activation du GPS requise',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: _loadLocation,
                                      icon: const Icon(Icons.gps_fixed),
                                      label: const Text('Activer la localisation'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Cliquez sur la carte pour choisir\nun autre emplacement',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                        ),
                      ),
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
              // Coordinates info
              if (_currentPosition != null && _solarZone != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Localisation',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : MedicalSolarColors.softGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : MedicalSolarColors.softGrey.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '* Cliquez sur la carte pour changer',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white60
                                    : MedicalSolarColors.softGrey.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Next Button
              Container(
                padding: const EdgeInsets.all(16),
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
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MedicalSolarColors.medicalBlue,
                          MedicalSolarColors.solarGreen,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MedicalSolarColors.medicalBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleNext,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continuer',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


