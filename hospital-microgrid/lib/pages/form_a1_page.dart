import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hospital_microgrid/pages/form_a2_page.dart';
import 'package:hospital_microgrid/services/location_service.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/widgets/hierarchical_type_selector.dart';
import 'package:hospital_microgrid/widgets/progress_indicator.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class FormA1Page extends StatefulWidget {
  final Position? position;

  const FormA1Page({
    super.key,
    this.position,
  });

  @override
  State<FormA1Page> createState() => _FormA1PageState();
}

class _FormA1PageState extends State<FormA1Page> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bedsController = TextEditingController();
  String? _selectedTypeBackend; // Valeur backend (ex: 'CHU', 'HOPITAL_REGIONAL')
  Position? _currentPosition;
  SolarZone? _solarZone;
  bool _isLoading = false;
  String? _errorMessage;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
    if (_currentPosition != null) {
      _loadSolarZone();
    } else {
      // V�rifier la permission au d�marrage et demander si n�cessaire
      _checkAndRequestLocation();
    }
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
    _nameController.dispose();
    _bedsController.dispose();
    _mapController.dispose();
    super.dispose();
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

  Future<void> _updateLocationFromMap(double latitude, double longitude) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
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

      final zone = await SolarZoneService.getSolarZoneFromLocation(
        latitude,
        longitude,
      );

      setState(() {
        _currentPosition = position;
        _solarZone = zone;
        _isLoading = false;
      });

      await Future.delayed(const Duration(milliseconds: 50));
      _mapController.move(
        LatLng(latitude, longitude),
        _mapController.camera.zoom,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise � jour: ${e.toString()}';
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
          _errorMessage = 'Le GPS n\'est pas aCoûtiv�';
          _isLoading = false;
        });
        return;
      }

      final position = await LocationService.getCurrentLocation();
      
      if (position == null) {
        setState(() {
          _errorMessage = 'Impossible d\'obtenir votre localisation';
          _isLoading = false;
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

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez obtenir la localisation'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_selectedTypeBackend == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez selectionner un type d\'etablissement'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Navigate to Form A2
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormA2Page(
            institutionType: _selectedTypeBackend!,
            institutionName: _nameController.text,
            location: _currentPosition!,
            numberOfBeds: int.tryParse(_bedsController.text) ?? 0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identification de l\'etablissement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: isDark ? MedicalSolarColors.darkSurface : MedicalSolarColors.offWhite,
        foregroundColor: isDark ? Colors.white : MedicalSolarColors.softGrey,
        elevation: 0,
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
                            : const LatLng(33.5731, -7.5898), // Casablanca par d�faut
                        initialZoom: 12.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                        onTap: (tapPosition, point) async {
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
                                      _errorMessage ?? 'ACoûtivation du GPS requise',
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
                              : Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.my_location, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              // Coordonn�es affich�es en BasÃ© de la carte si position disponible
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
              // Form SeCoûtion
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
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Indicateur de progression
                        const FormProgressIndicator(
                          currentStep: 1,
                          totalSteps: 3,
                          stepLabels: [
                            'Identification',
                            'Technique',
                            '�quipements',
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Type d'�Ã©tablissement
                        Text(
                          'Type d\'�Ã©tablissement',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : MedicalSolarColors.softGrey.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        HierarchicalTypeSelector(
                          selectedValue: _selectedTypeBackend,
                          onChanged: (value) {
                            setState(() {
                              _selectedTypeBackend = value;
                            });
                          },
                          isDark: isDark,
                        ),
                        if (_selectedTypeBackend == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Veuillez s�leCoûtionner un type',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Nom de l'�Ã©tablissement
                        Text(
                          'Nom de l\'�Ã©tablissement',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : MedicalSolarColors.softGrey.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Ex: H�pital Ibn Sina',
                            prefixIcon: const Icon(Icons.business),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                          ),
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Nbr de Lit
                        Text(
                          'Nombre de lits',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : MedicalSolarColors.softGrey.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _bedsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Ex: 150',
                            prefixIcon: const Icon(Icons.bed),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                          ),
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nombre de lits';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Coordinates info
                        if (_currentPosition != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? MedicalSolarColors.softGrey : MedicalSolarColors.offWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.withOpacity(0.2),
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
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : MedicalSolarColors.softGrey.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Next Button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                      ],
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
