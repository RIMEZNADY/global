import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/pages/form_b4_page.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class FormB3Page extends StatefulWidget {
  final Position position;
  final SolarZone solarZone;
  final double globalBudget;
  final double totalSurface;
  final double solarSurface;
  final int population;

  const FormB3Page({
    super.key,
    required this.position,
    required this.solarZone,
    required this.globalBudget,
    required this.totalSurface,
    required this.solarSurface,
    required this.population,
  });

  @override
  State<FormB3Page> createState() => _FormB3PageState();
}

class _FormB3PageState extends State<FormB3Page> {
  String? _selectedHospitalType;
  String? _selectedPriorite;

  final List<String> _hospitalTypes = [
    'Hôpital Régional',
    'CHU (Centre Hospitalier Universitaire)',
    'Hôpital Provincial',
    'Centre de Santé',
    'Clinique',
    'Autre',
  ];

  final List<String> _priorites = [
    'Haute - Production maximale d\'énergie',
    'Moyenne - Équilibre coût/efficacité',
    'Basse - Coût minimal',
  ];

  void _handleNext() {
    if (_selectedHospitalType == null || _selectedPriorite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner le type d\'hôpital et la priorité'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormB4Page(
          position: widget.position,
          solarZone: widget.solarZone,
          globalBudget: widget.globalBudget,
          totalSurface: widget.totalSurface,
          solarSurface: widget.solarSurface,
          population: widget.population,
          hospitalType: _selectedHospitalType!,
          priorite: _selectedPriorite!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objectif & Priorité'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Title
                Text(
                  'Objectif et Priorité',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                  ),
                ),
                const SizedBox(height: 32),
                // 1. Objectif (type d'hôpital)
                Text(
                  'Objectif (type d\'hôpital)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : MedicalSolarColors.softGrey.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedHospitalType,
                  decoration: InputDecoration(
                    hintText: 'Sélectionnez le type d\'hôpital',
                    prefixIcon: const Icon(Icons.local_hospital),
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
                  dropdownColor: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                  ),
                  items: _hospitalTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHospitalType = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // 2. Priorité
                Text(
                  'Priorité',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : MedicalSolarColors.softGrey.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPriorite,
                  decoration: InputDecoration(
                    hintText: 'Sélectionnez la priorité',
                    prefixIcon: const Icon(Icons.priority_high),
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
                  dropdownColor: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                  ),
                  items: _priorites.map((priorite) {
                    return DropdownMenuItem(
                      value: priorite,
                      child: Text(priorite),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriorite = value;
                    });
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
    );
  }
}