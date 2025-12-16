import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/services/solar_zone_service.dart';
import 'package:hospital_microgrid/pages/form_b5_page.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class FormB4Page extends StatefulWidget {
  final Position position;
  final SolarZone solarZone;
  final double globalBudget;
  final double totalSurface;
  final double solarSurface;
  final int population;
  final String hospitalType;
  final String priorite;

  const FormB4Page({
    super.key,
    required this.position,
    required this.solarZone,
    required this.globalBudget,
    required this.totalSurface,
    required this.solarSurface,
    required this.population,
    required this.hospitalType,
    required this.priorite,
  });

  @override
  State<FormB4Page> createState() => _FormB4PageState();
}

class _FormB4PageState extends State<FormB4Page> {
  late Map<String, dynamic> recommendation;

  @override
  void initState() {
    super.initState();
    calculateRecommendation();
  }

  void calculateRecommendation() {
    // Calculate recommendation score based on inputs
    double score = 0.0;
    
    // Score based on solar zone (Zone 1 = highest)
    final zoneScore = {
      SolarZone.zone1: 100.0,
      SolarZone.zone2: 85.0,
      SolarZone.zone3: 70.0,
      SolarZone.zone4: 60.0,
    };
    score += zoneScore[widget.solarZone] ?? 70.0;

    // Adjust score based on solar surface
    if (widget.solarSurface > 3000) {
      score += 10;
    } else if (widget.solarSurface > 1500) {
      score += 5;
    }

    // Adjust score based on budget
    if (widget.globalBudget > 3000000) {
      score += 10;
    } else if (widget.globalBudget > 1500000) {
      score += 5;
    }

    score = score.clamp(0, 100);

    recommendation = {
      'score': score,
      'hospitalType': widget.hospitalType,
      'recommendedType': widget.hospitalType.contains('Régional')
          ? 'Hôpital Régional'
          : widget.hospitalType,
    };
  }

  void _handleNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormB5Page(
          position: widget.position,
          solarZone: widget.solarZone,
          globalBudget: widget.globalBudget,
          totalSurface: widget.totalSurface,
          solarSurface: widget.solarSurface,
          population: widget.population,
          hospitalType: widget.hospitalType,
          priorite: widget.priorite,
          recommendationScore: recommendation['score'] as double,
        ),
      ),
    );
  }

  void _showDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? MedicalSolarColors.softGrey : Colors.white,
        title: Text(
          'Détails de la Recommandation',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score de Recommandation: ${recommendation['score'].toStringAsFixed(1)}/100',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Type: ${recommendation['recommendedType']}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Surface solaire: ${widget.solarSurface.toStringAsFixed(0)} m²',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Budget: ${widget.globalBudget.toStringAsFixed(0)} DH',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Population: ${widget.population.toString()} habitants',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fermer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommandation'),
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
                  'Recommandation',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                  ),
                ),
                const SizedBox(height: 32),
                // Recommendation Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: MedicalSolarColors.medicalBlue.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(SolarZoneService.getZoneColor(widget.solarZone)),
                                  MedicalSolarColors.medicalBlue,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.recommend,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendation['recommendedType'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recommandation Basée sur vos critères',
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
                      const SizedBox(height: 24),
                      // Score
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : MedicalSolarColors.medicalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Score (L)',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.9)
                                        : MedicalSolarColors.softGrey.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${recommendation['score'].toStringAsFixed(1)}/100',
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: MedicalSolarColors.medicalBlue,
                                  ),
                                ),
                              ],
                            ),
                            CircularProgressIndicator(
                              value: (recommendation['score'] as double) / 100,
                              strokeWidth: 8,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                MedicalSolarColors.medicalBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Details Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showDetails,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Voir détails'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: MedicalSolarColors.medicalBlue, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    );
  }
}