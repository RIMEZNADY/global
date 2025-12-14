import 'package:flutter/material.dart';

/// Palette "Medical Solar" - Clair, lumineux, respirant, naturel, rassurant
/// 
/// Conçue spécifiquement pour un projet microgrid hôpital :
/// - Bleu ciel médical = hôpital humain
/// - Jaune énergie solaire = soleil (rare en IA)
/// - Vert solaire doux = durabilité
/// - Très lumineuse et différente des apps IA classiques
class MedicalSolarColors {
  // Couleurs principales
  static const Color medicalBlue = Color(0xFF4EA8DE);      // Bleu ciel médical
  static const Color solarGreen = Color(0xFF6BCF9D);       // Vert solaire doux
  static const Color solarYellow = Color(0xFFF4C430);      // Jaune énergie solaire
  static const Color offWhite = Color(0xFFF9FAF7);         // Blanc cassé
  static const Color softGrey = Color(0xFF3A3A3A);         // Gris texte doux
  
  // Variantes pour dark mode
  static const Color medicalBlueDark = Color(0xFF5BB8E8);  // Plus clair pour dark
  static const Color solarGreenDark = Color(0xFF7BCFAD);   // Plus clair pour dark
  static const Color solarYellowDark = Color(0xFFFFD440);  // Plus clair pour dark
  static const Color darkBackground = Color(0xFF1A1F2E);   // Fond dark doux
  static const Color darkSurface = Color(0xFF252B3A);      // Surface dark
  
  // Couleurs sémantiques (Basées sur la palette)
  static const Color success = Color(0xFF6BCF9D);          // Vert solaire
  static const Color warning = Color(0xFFF4C430);          // Jaune solaire
  static const Color error = Color(0xFFE74C3C);            // Rouge doux
  static const Color info = Color(0xFF4EA8DE);             // Bleu médical
  
  // Dégradés
  static const LinearGradient solarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [solarYellow, Color(0xFFFFB800)],
  );
  
  static const LinearGradient medicalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [medicalBlue, Color(0xFF5BB8E8)],
  );
  
  static const LinearGradient ecoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [solarGreen, Color(0xFF7BCFAD)],
  );
  
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [medicalBlue, solarGreen, solarYellow],
    stops: [0.0, 0.5, 1.0],
  );
}

