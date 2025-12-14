import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
/// Widget �l�gant pour afficher la progression dans les formulaires
class FormProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const FormProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels = const [],
  }) : assert(currentStep >= 1 && currentStep <= totalSteps, 'currentStep must be between 1 and totalSteps');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de progression
          _buildProgressBar(context, isDark),
          const SizedBox(height: 16),
          // �Éétapes avec labels
          _buildStepIndicators(context, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, bool isDark) {
    final progress = (currentStep - 1) / (totalSteps - 1);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Stack(
              children: [
                // Barre de fond
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Barre de progression avec d�grad� or
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 6,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          MedicalSolarColors.medicalBlue, // Bleu ciel m�dical
          MedicalSolarColors.solarGreen, // Vert solaire doux
          MedicalSolarColors.solarYellow, // Jaune �énergie solaire
        ],
        stops: [0.0, 0.5, 1.0],
      ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Pourcentage
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB), // Bleu primaire
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepIndicators(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isCurrent = stepNumber == currentStep;
        final hasLabel = index < stepLabels.length;
        
        return Expanded(
          child: Column(
            children: [
              // Cercle de l'�étape
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF059669), // Vert �énergie (�étape compl�t�e)
                            Color(0xFF10B981), // Vert plus clair
                          ],
                        )
                      : isCurrent
                          ? LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.tertiary,
                              ],
                            )
                          : null,
                  color: isCompleted || isCurrent
                      ? null
                      : (isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.3)),
                  border: Border.all(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isCompleted || isCurrent
                      ? [
                          BoxShadow(
                            color: isCompleted
                                ? const Color(0xFF059669).withOpacity(0.4) // Vert pour compl�t�
                                : const Color(0xFF2563EB).withOpacity(0.4), // Bleu pour actuel
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : Text(
                          '$stepNumber',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? Colors.white
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.grey.shade600),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // Label de l'�étape
              if (hasLabel)
                Text(
                  stepLabels[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: isCurrent
                        ? (isDark ? Colors.white : MedicalSolarColors.softGrey)
                        : (isDark
                            ? Colors.white.withOpacity(0.6)
                            : Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
