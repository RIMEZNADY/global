import 'package:flutter/material.dart';

/// Couleurs smantiques pour feedback utilisateur et tats
/// Palette idale optimise pour UX
class SemanticColors {
 // Couleurs smantiques (Light Mode)
 static const Color successLight = Color(0xFF10B981); // Green 500
 static const Color successLightVariant = Color(0xFF34D399); // Green 400
 static const Color successDark = Color(0xFF059669); // Green 600
 
 static const Color errorLight = Color(0xFFEF4444); // Red 500
 static const Color errorLightVariant = Color(0xFFF87171); // Red 400
 static const Color errorDark = Color(0xFFDC2626); // Red 600
 
 static const Color warningLight = Color(0xFFF59E0B); // Amber 500
 static const Color warningLightVariant = Color(0xFFFBBF24); // Amber 400
 static const Color warningDark = Color(0xFFD97706); // Amber 600
 
 static const Color infoLight = Color(0xFF06B6D4); // Cyan 500
 static const Color infoLightVariant = Color(0xFF22D3EE); // Cyan 400
 static const Color infoDark = Color(0xFF0891B2); // Cyan 600

 // Couleurs smantiques (Dark Mode - plus claires)
 static const Color successDarkMode = Color(0xFF34D399); // Green 400
 static const Color errorDarkMode = Color(0xFFF87171); // Red 400
 static const Color warningDarkMode = Color(0xFFFBBF24); // Amber 400
 static const Color infoDarkMode = Color(0xFF22D3EE); // Cyan 400

 /// Retourne la couleur de succès selon le thème
 static Color success(BuildContext context) {
 return Theme.of(context).brightness == Brightness.dark
 ? successDarkMode
 : successLight;
 }

 /// Retourne la couleur d'erreur selon le thème
 static Color error(BuildContext context) {
 return Theme.of(context).brightness == Brightness.dark
 ? errorDarkMode
 : errorLight;
 }

 /// Retourne la couleur d'avertissement selon le thème
 static Color warning(BuildContext context) {
 return Theme.of(context).brightness == Brightness.dark
 ? warningDarkMode
 : warningLight;
 }

 /// Retourne la couleur d'information selon le thème
 static Color info(BuildContext context) {
 return Theme.of(context).brightness == Brightness.dark
 ? infoDarkMode
 : infoLight;
 }

 // Couleurs pour graphiques d'nergie
 static const Color energyProduction = Color(0xFF10B981); // Vert - Production
 static const Color energyConsumption = Color(0xFF2563EB); // Bleu - Consommation
 static const Color energyGrid = Color(0xFF6B7280); // Gris - Rseau
 static const Color energyBattery = Color(0xFFF59E0B); // Orange - Stockage
}






