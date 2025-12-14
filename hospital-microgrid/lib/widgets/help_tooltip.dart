import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

/// Widget r�utilisable pour afficher une ic�ne d'aide avec tooltip explicatif

class HelpTooltip extends StatelessWidget {

 final String message;

 final String? title;

 final IconData icon;

 final Color? iconColor;

 final double iconSize;



 const HelpTooltip({

 super.key,

 required this.message,

 this.title,

 this.icon = Icons.help_outline,

 this.iconColor,

 this.iconSize = 18,

 });



 @override

 Widget build(BuildContext context) {

 final isDark = Theme.of(context).brightness == Brightness.dark;

 final color = iconColor ?? (isDark ? Colors.white70 : Colors.grey[600]!);

 

 return Tooltip(

 message: title != null ? '$title\n\n$message' : message,

 textStyle: GoogleFonts.inter(

 fontSize: 13,

 color: Colors.white,

 ),

 padding: const EdgeInsets.all(12),

 decoration: BoxDecoration(

 color: isDark ? MedicalSolarColors.darkSurface : MedicalSolarColors.softGrey,

 borderRadius: BorderRadius.circular(8),

 boxShadow: [

 BoxShadow(

 color: Colors.black.withOpacity(0.2),

 blurRadius: 8,

 offset: const Offset(0, 4),

 ),

 ],

 ),

 preferBelow: false,

 verticalOffset: 8,

      waitDuration: const Duration(milliseconds: 300),

      child: GestureDetector(

        onTap: () => _showHelpDialog(context),

        child: Icon(

 icon,

 size: iconSize,

 color: color,

 ),

 ),

 );

 }



 void _showHelpDialog(BuildContext context) {

 final isDark = Theme.of(context).brightness == Brightness.dark;

 

 showDialog(

 context: context,

 builder: (context) => AlertDialog(

 backgroundColor: isDark ? MedicalSolarColors.darkSurface : Colors.white,

 shape: RoundedRectangleBorder(

 borderRadius: BorderRadius.circular(16),

 ),

 title: Row(

 children: [

 Icon(

 Icons.info_outline,

 color: Theme.of(context).colorScheme.primary,

 ),

 const SizedBox(width: 8),

 Expanded(

 child: Text(

 title ?? 'Information',

 style: GoogleFonts.inter(

 fontSize: 18,

 fontWeight: FontWeight.w600,

 color: isDark ? Colors.white : MedicalSolarColors.softGrey,

 ),

 ),

 ),

 ],

 ),

 content: Text(

 message,

 style: GoogleFonts.inter(

 fontSize: 14,

 color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),

 height: 1.5,

 ),

 ),

 actions: [

 TextButton(

 onPressed: () => Navigator.of(context).pop(),

 child: Text(

 'Fermer',

 style: GoogleFonts.inter(

 color: Theme.of(context).colorScheme.primary,

 fontWeight: FontWeight.w600,

 ),

 ),

 ),

 ],

 ),

 );

 }

}



/// Widget pour un champ avec label et tooltip d'aide

class LabelWithHelp extends StatelessWidget {

 final String label;

 final String helpMessage;

 final String? helpTitle;

 final Widget? child;

 final bool required;



 const LabelWithHelp({

 super.key,

 required this.label,

 required this.helpMessage,

 this.helpTitle,

 this.child,

 this.required = false,

 });



 @override

 Widget build(BuildContext context) {

 final isDark = Theme.of(context).brightness == Brightness.dark;

 

 return Column(

 crossAxisAlignment: CrossAxisAlignment.start,

 children: [

 Row(

 children: [

 Text(

 label,

 style: GoogleFonts.inter(

 fontSize: 14,

 fontWeight: FontWeight.w600,

 color: isDark ? Colors.white : MedicalSolarColors.softGrey,

 ),

 ),

 if (required) ...[

 const SizedBox(width: 4),

 Text(

 '*',

 style: GoogleFonts.inter(

 fontSize: 14,

 color: Colors.red,

 fontWeight: FontWeight.bold,

 ),

 ),

 ],

 const SizedBox(width: 8),

 HelpTooltip(

 message: helpMessage,

 title: helpTitle,

 iconSize: 16,

 ),

 ],

 ),

 if (child != null) ...[

 const SizedBox(height: 8),

 child!,

 ],

 ],

 );

 }

}





