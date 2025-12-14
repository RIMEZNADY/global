import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:hospital_microgrid/widgets/help_tooltip.dart';



import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

/// Widget pour afficher une m�trique avec un tooltip explicatif professionnel

class MetricCardWithTooltip extends StatelessWidget {

 final String title;

 final String value;

 final String? unit;

 final String explanation;

 final IconData? icon;

 final Color? iconColor;

 final Color? backgroundColor;

 final String? subtitle;



 const MetricCardWithTooltip({

 super.key,

 required this.title,

 required this.value,

 required this.explanation,

 this.unit,

 this.icon,

 this.iconColor,

 this.backgroundColor,

 this.subtitle,

 });



 @override

 Widget build(BuildContext context) {

 final isDark = Theme.of(context).brightness == Brightness.dark;

 final bgColor = backgroundColor ?? 

 (isDark ? MedicalSolarColors.darkSurface : Colors.white);



 return Container(

 padding: const EdgeInsets.all(16),

 decoration: BoxDecoration(

 color: bgColor,

 borderRadius: BorderRadius.circular(12),

 border: Border.all(

 color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),

 ),

 boxShadow: [

 BoxShadow(

 color: Colors.black.withOpacity(0.05),

 blurRadius: 8,

 offset: const Offset(0, 2),

 ),

 ],

 ),

 child: Column(

 crossAxisAlignment: CrossAxisAlignment.start,

 mainAxisSize: MainAxisSize.min,

 children: [

 // Header avec titre et tooltip

 Row(

 children: [

 if (icon != null) ...[

 Icon(

 icon,

 size: 20,

 color: iconColor ?? Theme.of(context).colorScheme.primary,

 ),

 const SizedBox(width: 8),

 ],

 Expanded(

 child: Text(

 title,

 style: GoogleFonts.inter(

 fontSize: 13,

 fontWeight: FontWeight.w600,

 color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),

 ),

 ),

 ),

 HelpTooltip(

 message: explanation,

 title: title,

 iconSize: 16,

 iconColor: isDark ? Colors.white60 : Colors.grey[600],

 ),

 ],

 ),

 const SizedBox(height: 12),

 // Valeur

 Row(

 crossAxisAlignment: CrossAxisAlignment.end,

 children: [

 Flexible(

 child: Text(

 value,

 style: GoogleFonts.inter(

 fontSize: 24,

 fontWeight: FontWeight.bold,

 color: isDark ? Colors.white : MedicalSolarColors.softGrey,

 ),

 overflow: TextOverflow.ellipsis,

 ),

 ),

 if (unit != null) ...[

 const SizedBox(width: 4),

 Padding(

 padding: const EdgeInsets.only(bottom: 4),

 child: Text(

 unit!,

 style: GoogleFonts.inter(

 fontSize: 14,

 fontWeight: FontWeight.w500,

 color: isDark ? Colors.white60 : MedicalSolarColors.softGrey.withOpacity(0.6),

 ),

 ),

 ),

 ],

 ],

 ),

 if (subtitle != null) ...[

 const SizedBox(height: 4),

 Text(

 subtitle!,

 style: GoogleFonts.inter(

 fontSize: 11,

 color: isDark ? Colors.white54 : MedicalSolarColors.softGrey.withOpacity(0.5),

 ),

 ),

 ],

 ],

 ),

 );

 }

}



/// Widget pour un graphique avec tooltip explicatif

class ChartCardWithTooltip extends StatelessWidget {

 final String title;

 final String explanation;

 final Widget chart;

 final IconData? icon;



 const ChartCardWithTooltip({

 super.key,

 required this.title,

 required this.explanation,

 required this.chart,

 this.icon,

 });



 @override

 Widget build(BuildContext context) {

 final isDark = Theme.of(context).brightness == Brightness.dark;



 return Container(

 padding: const EdgeInsets.all(20),

 decoration: BoxDecoration(

 color: isDark ? MedicalSolarColors.darkSurface : Colors.white,

 borderRadius: BorderRadius.circular(16),

 border: Border.all(

 color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),

 ),

 boxShadow: [

 BoxShadow(

 color: Colors.black.withOpacity(0.05),

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

 if (icon != null) ...[

 Icon(

 icon,

 size: 24,

 color: Theme.of(context).colorScheme.primary,

 ),

 const SizedBox(width: 12),

 ],

 Expanded(

 child: Text(

 title,

 style: GoogleFonts.inter(

 fontSize: 18,

 fontWeight: FontWeight.w600,

 color: isDark ? Colors.white : MedicalSolarColors.softGrey,

 ),

 ),

 ),

 HelpTooltip(

 message: explanation,

 title: title,

 iconSize: 18,

 ),

 ],

 ),

 const SizedBox(height: 20),

 chart,

 ],

 ),

 );

 }

}









