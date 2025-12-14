import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hospital_microgrid/pages/form_a5_page.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class FormA4Page extends StatefulWidget {
 final String institutionType;
 final String institutionName;
 final Position location;
 final int numberOfBeds;
 final double solarSurface;
 final double nonCriticalSurface;
 final double monthlyConsumption;
 final double dailyConsumption;
 final double dailyProduction;

 const FormA4Page({
 super.key,
 required this.institutionType,
 required this.institutionName,
 required this.location,
 required this.numberOfBeds,
 required this.solarSurface,
 required this.nonCriticalSurface,
 required this.monthlyConsumption,
 required this.dailyConsumption,
 required this.dailyProduction,
 });

 @override
 State<FormA4Page> createState() => _FormA4PageState();
}

class _FormA4PageState extends State<FormA4Page> {
 late Map<String, dynamic> recommendations;

 @override
 void initState() {
 super.initState();
 _calculateRecommendations();
 }

 void _calculateRecommendations() {
 // Calculate recommendations BasÃ©ed on inputs
 final dailyProductionKwh = widget.dailyProduction;
 final dailyConsumptionKwh = widget.dailyConsumption;
 
 // Calculate autonomy percentage
 final autonomyPercentage = (dailyProductionKwh / dailyConsumptionKwh * 100).clamp(0, 100);
 
 // Calculate recommended PV power (kW) - assume 200W per m�
 final recommendedPVPower = widget.solarSurface * 0.2; // kW
 
 // Calculate recommended battery capacitÃ©y (kWh) - enough for 12 hours of average consumption
 final avgHourlyConsumption = widget.monthlyConsumption / (30 * 24);
 final recommendedBatteryCapacity = avgHourlyConsumption * 12;
 
 // Calculate annual savings (DH/year)
 // Assume grid price: 1.5 DH/kWh, solar production covers autonomy percentage
 final annualGridConsumption = widget.monthlyConsumption * 12 * (1 - autonomyPercentage / 100);
 final annualSavings = annualGridConsumption * 1.5; // DH per year
 
 recommendations = {
 'annualSavings': annualSavings,
 'autonomyPercentage': autonomyPercentage,
 'recommendedPVPower': recommendedPVPower,
 'recommendedBatteryCapacity': recommendedBatteryCapacity,
 };
 }

 void _handleNext() {
 Navigator.push(
 context,
 MaterialPageRoute(
 builder: (context) => FormA5Page(
 institutionType: widget.institutionType,
 institutionName: widget.institutionName,
 location: widget.location,
 numberOfBeds: widget.numberOfBeds,
 solarSurface: widget.solarSurface,
 nonCriticalSurface: widget.nonCriticalSurface,
 monthlyConsumption: widget.monthlyConsumption,
 recommendedPVPower: recommendations['recommendedPVPower'] as double,
 recommendedBatteryCapacity: recommendations['recommendedBatteryCapacity'] as double,
 ),
 ),
 );
 }

 @override
 Widget build(BuildContext context) {
 final isDark = Theme.of(context).brightness == Brightness.dark;
 final isMobile = MediaQuery.of(context).size.width < 600;

 return Scaffold(
 appBar: AppBar(
 title: const Text('Recommandations'),
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
 padding: EdgeInsets.all(isMobile ? 16 : 24),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 const SizedBox(height: 20),
 // Title
 Text(
 'Recommandations du Systé�me',
 style: GoogleFonts.inter(
 fontSize: 24,
 fontWeight: FontWeight.bold,
 color: isDark ? Colors.white : MedicalSolarColors.softGrey,
 ),
 ),
 const SizedBox(height: 8),
 Text(
 'BasÃé©é�es sur votre consommation et votre surface disponible',
 style: GoogleFonts.inter(
 fontSize: 14,
 color: isDark
 ? Colors.white.withOpacity(0.7)
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 ),
 const SizedBox(height: 32),
 // 1. �conomie possible
 _buildRecommendationCard(
 context: context,
 isDark: isDark,
 isMobile: isMobile,
 icon: Icons.savings,
 title: 'é�conomie possible',
 value: '${recommendations['annualSavings'].toStringAsFixed(0)}',
 unit: 'DH/an',
 gradient: const LinearGradient(
 colors: [Color(0xFF10B981), Color(0xFF059669)],
 ),
 ),
 const SizedBox(height: 20),
 // 2. Pourcentage d'autonomie possible
 _buildRecommendationCard(
 context: context,
 isDark: isDark,
 isMobile: isMobile,
 icon: Icons.battery_charging_full,
 title: 'Pourcentage d\'autonomie possible',
 value: '${recommendations['autonomyPercentage'].toStringAsFixed(1)}',
 unit: '%',
 gradient: const LinearGradient(
 colors: [MedicalSolarColors.solarGreen, Color(0xFF0891B2)],
 ),
 ),
 const SizedBox(height: 20),
 // 3. Puissance PV recommandé�e
 _buildRecommendationCard(
 context: context,
 isDark: isDark,
 isMobile: isMobile,
 icon: Icons.solar_power,
 title: 'Puissance PV recommand�e',
 value: '${recommendations['recommendedPVPower'].toStringAsFixed(2)}',
 unit: 'kW',
 gradient: const LinearGradient(
 colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
 ),
 ),
 const SizedBox(height: 20),
 // 4. capacitÃé©é� batterie recommandé�e
 _buildRecommendationCard(
 context: context,
 isDark: isDark,
 isMobile: isMobile,
 icon: Icons.battery_std,
 title: 'capacitÃ©� batterie recommand�e',
 value: '${recommendations['recommendedBatteryCapacity'].toStringAsFixed(2)}',
 unit: 'kWh',
 gradient: const LinearGradient(
 colors: [Color(0xFF8B5CF6), MedicalSolarColors.medicalBlue],
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
 const SizedBox(height: 24),
 ],
 ),
 ),
 ),
 ),
 );
 }

 Widget _buildRecommendationCard({
 required BuildContext context,
 required bool isDark,
 required bool isMobile,
 required IconData icon,
 required String title,
 required String value,
 required String unit,
 required Gradient gradient,
 }) {
 return Container(
 padding: EdgeInsets.all(isMobile ? 20 : 24),
 decoration: BoxDecoration(
 color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: isDark
 ? Colors.white.withOpacity(0.1)
 : Colors.grey.withOpacity(0.2),
 width: 1,
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
 child: Row(
 children: [
 Container(
 width: 56,
 height: 56,
 decoration: BoxDecoration(
 gradient: gradient,
 borderRadius: BorderRadius.circular(12),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withOpacity(0.2),
 blurRadius: 8,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Icon(icon, color: Colors.white, size: 28),
 ),
 const SizedBox(width: 20),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 title,
 style: GoogleFonts.inter(
 fontSize: isMobile ? 14 : 16,
 fontWeight: FontWeight.w600,
 color: isDark
 ? Colors.white.withOpacity(0.9)
 : MedicalSolarColors.softGrey.withOpacity(0.8),
 ),
 ),
 const SizedBox(height: 8),
 RichText(
 text: TextSpan(
 style: GoogleFonts.inter(
 fontSize: isMobile ? 24 : 28,
 fontWeight: FontWeight.bold,
 color: isDark ? Colors.white : MedicalSolarColors.softGrey,
 ),
 children: [
 TextSpan(text: value),
 const TextSpan(
 text: ' ',
 style: TextStyle(fontSize: 16),
 ),
 TextSpan(
 text: unit,
 style: TextStyle(
 fontSize: isMobile ? 14 : 16,
 fontWeight: FontWeight.normal,
 color: isDark
 ? Colors.white.withOpacity(0.7)
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }
}


