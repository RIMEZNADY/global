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
    final hasPermission =
        await LocationService.isLocationPermissionGranted();
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
      final hasPermission =
          await LocationService.requestLocationPermission();

      if (!hasPermission) {
        setState(() {
          _errorMessage =
              'Location permission denied. Please enable it in settings.';
          _isLoading = false;
        });
        return;
      }

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'GPS is disabled. Please enable location services.';
          _isLoading = false;
        });
        _showEnableGPSDialog();
        return;
      }

      final position = await LocationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _errorMessage = 'Unable to retrieve current location.';
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
        _permissionGranted = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showEnableGPSDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Disabled'),
        content: const Text(
          'Location services are required to determine the solar zone. '
          'Would you like to open settings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService.openLocationSettings();
            },
            child: const Text('Open Settings'),
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
          builder: (_) => FormA1Page(
            position: _currentPosition!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              /// GPS Icon
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

              /// Title
              Text(
                'Location Access',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              /// Description
              Text(
                'We need your location to determine the solar zone '
                'and optimize the microgrid configuration.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? Colors.white70
                          : MedicalSolarColors.softGrey.withOpacity(0.7),
                    ),
              ),

              const SizedBox(height: 48),

              /// Activate location button
              if (!_permissionGranted || _currentPosition == null)
                ElevatedButton(
                  onPressed: _isLoading ? null : _requestLocation,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
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
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Enable Location',
                          style: TextStyle(fontSize: 16),
                        ),
                ),

              const SizedBox(height: 24),

              /// Continue
              if (_currentPosition != null)
                ElevatedButton(
                  onPressed: _continueToInstitutionChoice,
                  child: const Text('Continue'),
                ),

              /// Error message
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
                      const Icon(Icons.error_outline,
                          color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              const TextStyle(color: Colors.red),
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
