import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/pages/form_a1_page.dart';
import 'package:hospital_microgrid/pages/form_b1_page.dart';
import 'package:hospital_microgrid/pages/map_selection_page.dart';
import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class InstitutionChoicePage extends StatelessWidget {
  final Position? position;
  final SolarZone? solarZone;

  const InstitutionChoicePage({
    super.key,
    this.position,
    this.solarZone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    MedicalSolarColors.darkBackground,
                    MedicalSolarColors.darkSurface,
                  ]
                : [
                    MedicalSolarColors.offWhite,
                    MedicalSolarColors.medicalBlue.withOpacity(0.05),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // EXISTANT Button
                  _buildChoiceButton(
                    context: context,
                    isDark: isDark,
                    label: 'EXISTANT',
                    icon: Icons.local_hospital,
                    onPressed: () async {
                      // Navigate to Map Selection Page first
                      final selectedPosition = await Navigator.push<Position>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapSelectionPage(
                            initialPosition: position,
                          ),
                        ),
                      );
                      
                      // If position selected, navigate to Form A1
                      if (selectedPosition != null) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FormA1Page(
                                position: selectedPosition,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    color: MedicalSolarColors.medicalBlue,
                  ),
                  const SizedBox(height: 20),
                  // NEW Button
                  _buildChoiceButton(
                    context: context,
                    isDark: isDark,
                    label: 'NEW',
                    icon: Icons.add_business,
                    onPressed: () {
                      // Navigate to Form B1 (GPS & Map)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FormB1Page(),
                        ),
                      );
                    },
                    color: MedicalSolarColors.solarGreen,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required bool isDark,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color == MedicalSolarColors.medicalBlue
                ? MedicalSolarColors.solarGreen
                : MedicalSolarColors.solarYellow,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
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
