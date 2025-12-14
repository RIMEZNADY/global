import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
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
  final _budgetController = TextEditingController();
  final _totalSurfaceController = TextEditingController();
  final _solarSurfaceController = TextEditingController();
  final _populationController = TextEditingController();

  // Auto-estimated values Based on location
  String? _estimatedBudget;
  String? _estimatedSurface;

  @override
  void initState() {
    super.initState();
    _estimateValues();
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

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormB3Page(
            position: widget.position,
            solarZone: widget.solarZone,
            globalBudget: double.tryParse(_budgetController.text) ?? 0,
            totalSurface: double.tryParse(_totalSurfaceController.text) ?? 0,
            solarSurface: double.tryParse(_solarSurfaceController.text) ?? 0,
            population: int.tryParse(_populationController.text) ?? 0,
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
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
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
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
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  ),
                  const SizedBox(height: 24),
                  // 4. Population environnante
                  Text(
                    'Population environnante',
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
