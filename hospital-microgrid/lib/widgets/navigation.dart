import 'package:flutter/material.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class NavigationWidget extends StatelessWidget {
 final String currentPage;
 final Function(String) onPageChange;

 const NavigationWidget({
 super.key,
 required this.currentPage,
 required this.onPageChange,
 });

 @override
 Widget build(BuildContext context) {
 final navItems = [
 {
 'id': 'dashboard',
 'label': 'Dashboard',
 'icon': Icons.bar_chart,
 },
 {
 'id': 'ai-prediction',
 'label': 'AI Prediction',
 'icon': Icons.psychology,
 },
 {
 'id': 'auto-learning',
 'label': 'Auto-Learning',
 'icon': Icons.bolt,
 },
 {
 'id': 'history',
 'label': 'History',
 'icon': Icons.history,
 },
 ];

 return Container(
 decoration: BoxDecoration(
 color: MedicalSolarColors.darkSurface,
 border: Border(
 bottom: BorderSide(
 color: Colors.white.withOpacity(0.1),
 width: 1,
 ),
 ),
 ),
 child: SafeArea(
 bottom: false,
 child: Padding(
 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
 child: LayoutBuilder(
 builder: (context, constraints) {
 final isMobile = constraints.maxWidth < 800;
 
 if (isMobile) {
 return Column(
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(8),
 gradient: const LinearGradient(
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 colors: [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.solarGreen,
 ],
 ),
 ),
 child: const Icon(
 Icons.bolt,
 color: Colors.white,
 size: 24,
 ),
 ),
 const SizedBox(width: 12),
 Text(
 'Hospital Microgrid',
 style: Theme.of(context).textTheme.titleLarge?.copyWith(
 fontWeight: FontWeight.bold,
 color: Colors.white,
 ),
 ),
 ],
 ),
 const SizedBox(height: 16),
 Wrap(
 alignment: WrapAlignment.center,
 spacing: 8,
 runSpacing: 8,
 children: navItems.map((item) {
 final isActive = currentPage == item['id'];
 return TextButton(
 onPressed: () => onPageChange(item['id'] as String),
 style: TextButton.styleFrom(
 backgroundColor: isActive
 ? MedicalSolarColors.medicalBlue
 : Colors.transparent,
 foregroundColor: isActive
 ? Colors.white
 : Colors.white.withOpacity(0.7),
 padding: const EdgeInsets.symmetric(
 horizontal: 12,
 vertical: 8,
 ),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(8),
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 item['icon'] as IconData,
 size: 16,
 ),
 const SizedBox(width: 6),
 Text(
 item['label'] as String,
 style: const TextStyle(
 fontSize: 12,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 );
 }).toList(),
 ),
 ],
 );
 }
 
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Row(
 children: [
 Container(
 width: 40,
 height: 40,
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(8),
 gradient: const LinearGradient(
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 colors: [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.solarGreen,
 ],
 ),
 ),
 child: const Icon(
 Icons.bolt,
 color: Colors.white,
 size: 24,
 ),
 ),
 const SizedBox(width: 12),
 Text(
 'Hospital Microgrid',
 style: Theme.of(context).textTheme.titleLarge?.copyWith(
 fontWeight: FontWeight.bold,
 color: Colors.white,
 ),
 ),
 ],
 ),
 Row(
 children: navItems.map((item) {
 final isActive = currentPage == item['id'];
 return Padding(
 padding: const EdgeInsets.only(left: 8),
 child: TextButton(
 onPressed: () => onPageChange(item['id'] as String),
 style: TextButton.styleFrom(
 backgroundColor: isActive
 ? MedicalSolarColors.medicalBlue
 : Colors.transparent,
 foregroundColor: isActive
 ? Colors.white
 : Colors.white.withOpacity(0.7),
 padding: const EdgeInsets.symmetric(
 horizontal: 16,
 vertical: 8,
 ),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(8),
 ),
 ),
 child: Row(
 children: [
 Icon(
 item['icon'] as IconData,
 size: 16,
 ),
 const SizedBox(width: 8),
 Text(
 item['label'] as String,
 style: const TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w500,
 ),
 ),
 ],
 ),
 ),
 );
 }).toList(),
 ),
 ],
 );
 },
 ),
 ),
 ),
 );
 }
}

