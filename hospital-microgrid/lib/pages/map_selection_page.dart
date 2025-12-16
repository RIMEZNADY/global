import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hospital_microgrid/services/location_service.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class MapSelectionPage extends StatefulWidget {
  final Position? initialPosition;

  const MapSelectionPage({
    super.key,
    this.initialPosition,
  });

  @override
  State<MapSelectionPage> createState() => _MapSelectionPageState();
}

class _MapSelectionPageState extends State<MapSelectionPage> {
  Position? _currentPosition;
  SolarZone? _solarZone;
  bool _isLoading = false;
  String? _errorMessage;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    if (_currentPosition != null) {
      _loadSolarZone();
    } else {
      _checkAndRequestLocation();
    }
    
    // Initialiser la carte sur Casablanca par défaut après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(
          const LatLng(33.5731, -7.5898), // Casablanca
          12.0,
        );
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestLocation() async {
    final hasPermission = await LocationService.isLocationPermissionGranted();
    if (!hasPermission) {
      setState(() {
        _errorMessage = 'Activation de la localisation requise';
      });
    } else {
      await _loadLocation();
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
        // Proposer d'ouvrir les paramètres
        _showOpenSettingsDialog();
        return;
      }
      
      final hasPermission = await LocationService.requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Permission de localisation requise';
          _isLoading = false;
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Le GPS n\'est pas active';
          _isLoading = false;
        });
        return;
      }

      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage = 'Impossible d\'obtenir votre localisation.';
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
        _errorMessage = 'Erreur lors de la mise a jour: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSolarZone() async {
    if (_currentPosition == null) return;
    
    try {
      final zone = await SolarZoneService.getSolarZoneFromLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      setState(() {
        _solarZone = zone;
      });
    } catch (e) {
      print('Erreur lors du chargement de la zone solaire: $e');
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

  Future<void> _updateLocationFromMap(double latitude, double longitude) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    setState(() {
      _currentPosition = Position(
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
    });

    try {
      final zone = await SolarZoneService.getSolarZoneFromLocation(
        latitude,
        longitude,
      );

      setState(() {
        _solarZone = zone;
        _isLoading = false;
      });

      // Centrer la carte sur la nouvelle position (après que le widget soit rendu)
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

  void _confirmSelection() {
    if (_currentPosition != null && _solarZone != null) {
      Navigator.pop(context, _currentPosition);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez selectionner une localisation sur la carte'),
          backgroundColor: MedicalSolarColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selection de la Localisation'),
        backgroundColor: isDark ? MedicalSolarColors.darkSurface : MedicalSolarColors.offWhite,
        foregroundColor: isDark ? Colors.white : MedicalSolarColors.softGrey,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? MedicalSolarColors.darkBackground : MedicalSolarColors.offWhite,
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
                                    ? Colors.white
                                    : MedicalSolarColors.softGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.gps_fixed,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white
                                      : MedicalSolarColors.softGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white
                                        : MedicalSolarColors.softGrey,
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
                          await _updateLocationFromMap(point.latitude, point.longitude);
                        },
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
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
                                        : Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_solarZone != null
                                            ? Color(SolarZoneService.getZoneColor(_solarZone!))
                                            : Theme.of(context).colorScheme.primary)
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
                    // Overlay pour le chargement ou les erreurs (seulement si pas de position)
                    if ((_isLoading || (_currentPosition == null && _errorMessage != null)) && _currentPosition == null)
                      Positioned.fill(
                        child: Container(
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
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.primary,
                                              Theme.of(context).colorScheme.secondary,
                                            ],
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
                      ),
                    // Instruction banner for map interaction
                    if (_currentPosition != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: MedicalSolarColors.medicalBlue.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Appuyez sur la carte pour changer l\'emplacement',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Center location button
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
                              : Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.my_location, color: Colors.white),
                          tooltip: 'Centrer sur ma position',
                        ),
                      ),
                  ],
                ),
              ),
              // Coordinates info
              if (_currentPosition != null && _solarZone != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            ? Colors.white
                            : MedicalSolarColors.softGrey,
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
                                    ? Colors.white
                                    : MedicalSolarColors.softGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white
                                    : MedicalSolarColors.softGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '* Cliquez sur la carte pour changer',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white
                                    : MedicalSolarColors.softGrey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Confirm Button
              if (_currentPosition != null && _solarZone != null)
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
                        gradient: LinearGradient(
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
                          onTap: _confirmSelection,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Confirmer et Continuer',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
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

