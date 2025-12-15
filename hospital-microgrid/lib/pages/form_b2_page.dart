import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/services/backend_location_service.dart';
import 'package:hospital_microgrid/pages/form_b3_page.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class FormB2Page extends StatefulWidget {
  final Position position;
  final SolarZone solarZone;

  const FormB2Page({
    super.key,
    required this.position,
    required this.solarZone,
  });

  @override
  State<FormB2Page> createState() => _FormB2PageState();
}

class _FormB2PageState extends State<FormB2Page> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour valeurs exactes
  final _budgetController = TextEditingController();
  final _totalSurfaceController = TextEditingController();
  final _solarSurfaceController = TextEditingController();
  final _populationController = TextEditingController();
  
  // Contrôleurs pour intervalles (min/max)
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _totalSurfaceMinController = TextEditingController();
  final _totalSurfaceMaxController = TextEditingController();
  final _solarSurfaceMinController = TextEditingController();
  final _solarSurfaceMaxController = TextEditingController();
  final _populationMinController = TextEditingController();
  final _populationMaxController = TextEditingController();
  
  // Flags pour utiliser intervalle ou valeur exacte
  bool _useIntervalBudget = false;
  bool _useIntervalTotalSurface = false;
  bool _useIntervalSolarSurface = false;
  bool _useIntervalPopulation = false;

  // Auto-estimated values Based on location
  String? _estimatedBudget;
  String? _estimatedSurface;
  int? _estimatedPopulation;
  bool _isLoadingPopulation = false;

  @override
  void initState() {
    super.initState();
    _estimateValues();
    _estimatePopulation();
  }

  void _estimateValues() {
    // Auto-estimate Based on solar zone and location
    // Zone 1 (very high): higher estimates
    // Zone 4 (moderate): lower estimates
    final zoneMultiplier = {
      SolarZone.zone1: 1.2,
      SolarZone.zone2: 1.1,
      SolarZone.zone3: 1.0,
      SolarZone.zone4: 0.9,
    };

    final multiplier = zoneMultiplier[widget.solarZone] ?? 1.0;
    
    // Estimate budget (DH) Based on location
    const baseBudget = 2000000.0; // Base 2M DH
    final estimatedBudget = baseBudget * multiplier;
    _estimatedBudget = estimatedBudget.toStringAsFixed(0);

    // Estimate surface (m²) Based on location
    const baseSurface = 5000.0; // Base 5000 m²
    final estimatedSurface = baseSurface * multiplier;
    _estimatedSurface = estimatedSurface.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _totalSurfaceController.dispose();
    _solarSurfaceController.dispose();
    _populationController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _totalSurfaceMinController.dispose();
    _totalSurfaceMaxController.dispose();
    _solarSurfaceMinController.dispose();
    _solarSurfaceMaxController.dispose();
    _populationMinController.dispose();
    _populationMaxController.dispose();
    super.dispose();
  }

  void _useEstimatedBudget() {
    setState(() {
      _budgetController.text = _estimatedBudget ?? '';
    });
  }

  void _useEstimatedSurface() {
    setState(() {
      _totalSurfaceController.text = _estimatedSurface ?? '';
    });
  }
  
  Future<void> _estimatePopulation({String? establishmentType, int? numberOfBeds}) async {
    setState(() {
      _isLoadingPopulation = true;
    });
    
    try {
      final estimated = await BackendLocationService.estimatePopulation(
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        establishmentType: establishmentType,
        numberOfBeds: numberOfBeds,
      );
      
      setState(() {
        _estimatedPopulation = estimated;
        _isLoadingPopulation = false;
      });
      
      // Remplir automatiquement le champ si vide
      if (_populationController.text.isEmpty && !_useIntervalPopulation) {
        _populationController.text = estimated.toString();
      }
    } catch (e) {
      setState(() {
        _isLoadingPopulation = false;
        // En cas d'erreur, utiliser une estimation basique basée sur la zone
        final zoneMultiplier = {
          SolarZone.zone1: 800000,
          SolarZone.zone2: 600000,
          SolarZone.zone3: 500000,
          SolarZone.zone4: 100000,
        };
        _estimatedPopulation = zoneMultiplier[widget.solarZone] ?? 50000;
      });
    }
  }
  
  void _useEstimatedPopulation() {
    if (_estimatedPopulation != null) {
      setState(() {
        if (_useIntervalPopulation) {
          // Pour intervalle, mettre ±20%
          final min = (_estimatedPopulation! * 0.8).round();
          final max = (_estimatedPopulation! * 1.2).round();
          _populationMinController.text = min.toString();
          _populationMaxController.text = max.toString();
        } else {
          _populationController.text = _estimatedPopulation.toString();
        }
      });
    }
  }

  // Helper function to validate and get value from interval or exact
  double? _getValueFromField({
    required bool useInterval,
    required TextEditingController exactController,
    required TextEditingController minController,
    required TextEditingController maxController,
    required String fieldName,
  }) {
    if (useInterval) {
      final min = double.tryParse(minController.text);
      final max = double.tryParse(maxController.text);
      
      if (min == null || max == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez entrer des valeurs valides pour l\'intervalle de $fieldName'),
            backgroundColor: MedicalSolarColors.error,
          ),
        );
        return null;
      }
      
      if (min >= max) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La valeur minimale doit être inférieure à la valeur maximale pour $fieldName'),
            backgroundColor: MedicalSolarColors.error,
          ),
        );
        return null;
      }
      
      // Return average for calculations
      return (min + max) / 2;
    } else {
      final value = double.tryParse(exactController.text);
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez entrer une valeur valide pour $fieldName'),
            backgroundColor: MedicalSolarColors.error,
          ),
        );
        return null;
      }
      return value;
    }
  }
  
  int? _getIntValueFromField({
    required bool useInterval,
    required TextEditingController exactController,
    required TextEditingController minController,
    required TextEditingController maxController,
    required String fieldName,
  }) {
    if (useInterval) {
      final min = int.tryParse(minController.text);
      final max = int.tryParse(maxController.text);
      
      if (min == null || max == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez entrer des valeurs valides pour l\'intervalle de $fieldName'),
            backgroundColor: MedicalSolarColors.error,
          ),
        );
        return null;
      }
      
      if (min >= max) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La valeur minimale doit être inférieure à la valeur maximale pour $fieldName'),
            backgroundColor: MedicalSolarColors.error,
          ),
        );
        return null;
      }
      
      // Return average for calculations
      return ((min + max) / 2).round();
    } else {
      final value = int.tryParse(exactController.text);
      if (value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez entrer une valeur valide pour $fieldName'),
            backgroundColor: MedicalSolarColors.error,
          ),
        );
        return null;
      }
      return value;
    }
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Get values using helper functions
    final budget = _getValueFromField(
      useInterval: _useIntervalBudget,
      exactController: _budgetController,
      minController: _budgetMinController,
      maxController: _budgetMaxController,
      fieldName: 'Budget global',
    );
    
    final totalSurface = _getValueFromField(
      useInterval: _useIntervalTotalSurface,
      exactController: _totalSurfaceController,
      minController: _totalSurfaceMinController,
      maxController: _totalSurfaceMaxController,
      fieldName: 'Surface Total',
    );
    
    final solarSurface = _getValueFromField(
      useInterval: _useIntervalSolarSurface,
      exactController: _solarSurfaceController,
      minController: _solarSurfaceMinController,
      maxController: _solarSurfaceMaxController,
      fieldName: 'Surface Solaire',
    );
    
    final population = _getIntValueFromField(
      useInterval: _useIntervalPopulation,
      exactController: _populationController,
      minController: _populationMinController,
      maxController: _populationMaxController,
      fieldName: 'Population',
    );
    
    if (budget == null || totalSurface == null || solarSurface == null || population == null) {
      return; // Error already shown by helper functions
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormB3Page(
          position: widget.position,
          solarZone: widget.solarZone,
          globalBudget: budget,
          totalSurface: totalSurface,
          solarSurface: solarSurface,
          population: population,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations du Projet'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Zone info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(SolarZoneService.getZoneColor(widget.solarZone))
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(SolarZoneService.getZoneColor(widget.solarZone))
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          color: Color(SolarZoneService.getZoneColor(widget.solarZone)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SolarZoneService.getZoneName(widget.solarZone),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Valeurs auto-estimées basées sur la localisation',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Informations du Projet',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 1. Budget global
                  Text(
                    'Budget global (DH)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : MedicalSolarColors.softGrey.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Toggle for interval/exact value
                  Row(
                    children: [
                      Text(
                        'Valeur exacte',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                      Switch(
                        value: _useIntervalBudget,
                        onChanged: (value) {
                          setState(() {
                            _useIntervalBudget = value;
                          });
                        },
                        activeColor: MedicalSolarColors.medicalBlue,
                      ),
                      Text(
                        'Intervalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _useEstimatedBudget,
                        icon: const Icon(Icons.auto_fix_high, size: 20),
                        label: Text(
                          'V.E',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_useIntervalBudget)
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 2000000',
                        prefixIcon: const Icon(Icons.attach_money),
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
                          borderSide: const BorderSide(
                            color: MedicalSolarColors.medicalBlue,
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
                          return 'Veuillez entrer le budget';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _budgetMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'Ex: 1500000',
                              prefixIcon: const Icon(Icons.arrow_downward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Min requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _budgetMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'Ex: 2500000',
                              prefixIcon: const Icon(Icons.arrow_upward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Max requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // 2. Surface Total (m²)
                  Text(
                    'Surface Total (m²)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : MedicalSolarColors.softGrey.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Toggle for interval/exact value
                  Row(
                    children: [
                      Text(
                        'Valeur exacte',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                      Switch(
                        value: _useIntervalTotalSurface,
                        onChanged: (value) {
                          setState(() {
                            _useIntervalTotalSurface = value;
                          });
                        },
                        activeColor: MedicalSolarColors.medicalBlue,
                      ),
                      Text(
                        'Intervalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _useEstimatedSurface,
                        icon: const Icon(Icons.auto_fix_high, size: 20),
                        label: Text(
                          'V.E',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_useIntervalTotalSurface)
                    TextFormField(
                      controller: _totalSurfaceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 5000',
                        suffixText: 'm²',
                        prefixIcon: const Icon(Icons.square_foot),
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
                          borderSide: const BorderSide(
                            color: MedicalSolarColors.medicalBlue,
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
                          return 'Veuillez entrer la surface';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalSurfaceMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'Ex: 4000',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_downward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Min requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _totalSurfaceMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'Ex: 6000',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_upward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Max requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // 3. Surface non critique exploitable pour panneaux (m²)
                  Text(
                    'Surface non critique exploitable pour panneaux (m²)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : MedicalSolarColors.softGrey.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Toggle for interval/exact value
                  Row(
                    children: [
                      Text(
                        'Valeur exacte',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                      Switch(
                        value: _useIntervalSolarSurface,
                        onChanged: (value) {
                          setState(() {
                            _useIntervalSolarSurface = value;
                          });
                        },
                        activeColor: MedicalSolarColors.medicalBlue,
                      ),
                      Text(
                        'Intervalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_useIntervalSolarSurface)
                    TextFormField(
                      controller: _solarSurfaceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 2000',
                        suffixText: 'm²',
                        prefixIcon: const Icon(Icons.solar_power),
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
                          borderSide: const BorderSide(
                            color: MedicalSolarColors.medicalBlue,
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
                          return 'Veuillez entrer la surface';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _solarSurfaceMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'Ex: 1500',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_downward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Min requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _solarSurfaceMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'Ex: 2500',
                              suffixText: 'm²',
                              prefixIcon: const Icon(Icons.arrow_upward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Max requis';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // 4. Population environnante
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Population environnante',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : MedicalSolarColors.softGrey.withOpacity(0.8),
                          ),
                        ),
                      ),
                      if (_estimatedPopulation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MedicalSolarColors.medicalBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: MedicalSolarColors.medicalBlue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Est: ${_estimatedPopulation!.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: MedicalSolarColors.medicalBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Toggle for interval/exact value
                  Row(
                    children: [
                      Text(
                        'Valeur exacte',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                      Switch(
                        value: _useIntervalPopulation,
                        onChanged: (value) {
                          setState(() {
                            _useIntervalPopulation = value;
                          });
                        },
                        activeColor: MedicalSolarColors.medicalBlue,
                      ),
                      Text(
                        'Intervalle',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : MedicalSolarColors.softGrey.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingPopulation)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Tooltip(
                          message: _estimatedPopulation != null
                              ? 'Population estimée: ${_estimatedPopulation!.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} habitants\nBasée sur la localisation et la zone solaire'
                              : 'Estimer la population basée sur la localisation',
                          child: TextButton.icon(
                            onPressed: _useEstimatedPopulation,
                            icon: const Icon(Icons.auto_fix_high, size: 20),
                            label: Text(
                              'Estimer',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_useIntervalPopulation)
                    TextFormField(
                      controller: _populationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 50000',
                        prefixIcon: const Icon(Icons.people),
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
                          borderSide: const BorderSide(
                            color: MedicalSolarColors.medicalBlue,
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
                          return 'Veuillez entrer la population';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _populationMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'Ex: 40000',
                              prefixIcon: const Icon(Icons.arrow_downward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Min requis';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _populationMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'Ex: 60000',
                              prefixIcon: const Icon(Icons.arrow_upward),
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
                                borderSide: const BorderSide(
                                  color: MedicalSolarColors.medicalBlue,
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
                                return 'Max requis';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  // Next Button
                  Container(
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
                                'Suivant',
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
    );
  }
}
