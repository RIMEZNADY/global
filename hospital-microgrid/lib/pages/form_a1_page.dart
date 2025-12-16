import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/pages/form_a2_page.dart';
import 'package:hospital_microgrid/pages/map_selection_page.dart';
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

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
    if (_currentPosition != null) {
      _loadSolarZone();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bedsController.dispose();
    super.dispose();
  }

  Future<void> _loadSolarZone() async {
    if (_currentPosition == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final zone = await SolarZoneService.getSolarZoneFromLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      setState(() {
        _solarZone = zone;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Erreur lors du chargement de la zone solaire: $e');
    }
  }

  Future<void> _changeLocation() async {
    final selectedPosition = await Navigator.push<Position>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionPage(
          initialPosition: _currentPosition,
        ),
      ),
    );
    
    if (selectedPosition != null) {
      setState(() {
        _currentPosition = selectedPosition;
      });
      _loadSolarZone();
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with zone info
              if (_currentPosition != null)
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
                          color: (_solarZone != null
                              ? Color(SolarZoneService.getZoneColor(_solarZone!))
                              : MedicalSolarColors.medicalBlue)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.wb_sunny,
                          color: _solarZone != null
                              ? Color(SolarZoneService.getZoneColor(_solarZone!))
                              : MedicalSolarColors.medicalBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_solarZone != null) ...[
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
                            ],
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
                        icon: const Icon(Icons.edit_location),
                        onPressed: _changeLocation,
                        tooltip: 'Changer la localisation',
                      ),
                    ],
                  ),
                ),
              // Location info card
              if (_currentPosition != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (_solarZone != null
                          ? Color(SolarZoneService.getZoneColor(_solarZone!))
                          : MedicalSolarColors.medicalBlue)
                          .withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              color: _solarZone != null
                                  ? Color(SolarZoneService.getZoneColor(_solarZone!))
                                  : MedicalSolarColors.medicalBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Localisation Selectionnee',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _changeLocation,
                              icon: const Icon(Icons.edit_location, size: 18),
                              label: const Text('Modifier'),
                              style: TextButton.styleFrom(
                                foregroundColor: MedicalSolarColors.medicalBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : MedicalSolarColors.softGrey.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_currentPosition == null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MedicalSolarColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MedicalSolarColors.error.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        color: MedicalSolarColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune localisation selectionnee',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _changeLocation,
                        icon: const Icon(Icons.map),
                        label: const Text('Selectionner une localisation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MedicalSolarColors.medicalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Form Section - Make it flexible to prevent overflow
              Flexible(
                child: Container(
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
                            'Equipements',
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Type d'etablissement
                        Text(
                          'Type d\'etablissement',
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
                              'Veuillez selectionner un type',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Nom de l'etablissement
                        Text(
                          'Nom de l\'etablissement',
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
                            hintText: 'Ex: Hopital Ibn Sina',
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
            ),
            ],
          ),
        ),
      ),
    );
  }
}
