import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:geolocator/geolocator.dart';

import 'package:hospital_microgrid/pages/form_a4_page.dart';



import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class FormA3Page extends StatefulWidget {

 final String institutionType;

 final String institutionName;

 final Position location;

 final int numberOfBeds;

 final double solarSurface;

 final double nonCriticalSurface;

 final double monthlyConsumption;



 const FormA3Page({

 super.key,

 required this.institutionType,

 required this.institutionName,

 required this.location,

 required this.numberOfBeds,

 required this.solarSurface,

 required this.nonCriticalSurface,

 required this.monthlyConsumption,

 });



 @override

 State<FormA3Page> createState() => _FormA3PageState();

}



class _FormA3PageState extends State<FormA3Page> {

 // Simulated data based on inputs

 late List<Map<String, dynamic>> consumptionData;

 late List<Map<String, dynamic>> solarProductionData;

 late List<Map<String, dynamic>> batterySOCData;



 @override

 void initState() {

 super.initState();

 _generateData();

 }



 void _generateData() {

 // Generate consumption data (24 hours)

 consumptionData = List.generate(24, (index) {

// Simulate hourly consumption based on monthly consumption

final baseHourly = widget.monthlyConsumption / (30 * 24);

final variation = (baseHourly * 0.3) * (1 + (index % 12) / 12); // Peak during day

return {

'hour': index,

'consumption': baseHourly + variation,

 };

 });



 // Generate solar production data (24 hours)

 solarProductionData = List.generate(24, (index) {

 double production = 0;

 if (index >= 6 && index <= 18) {

 // Solar production during daylight hours

 final hourOfDay = index - 6;

 final distanceFromPeak = (hourOfDay - 6).abs();

 final efficiency = 1 - (distanceFromPeak / 6) * 0.5;

 // Assume 200W/m� average solar panel efficiency

 production = widget.solarSurface * 0.2 * efficiency;

 }

 return {

 'hour': index,

 'production': production,

 };

 });



 // Generate battery SOC data (24 hours)

 double batteryCapacity = widget.monthlyConsumption * 0.1; // 10% of monthly consumption

 double currentSOC = 50; // Start at 50%

 batterySOCData = List.generate(24, (index) {

 final consumption = consumptionData[index]['consumption'] as double;

 final production = solarProductionData[index]['production'] as double;

 

 // Simulate battery charging/discharging

 final netEnergy = production - consumption;

 if (netEnergy > 0) {

 currentSOC = (currentSOC + (netEnergy / batteryCapacity * 100)).clamp(0, 100);

 } else {

 currentSOC = (currentSOC + (netEnergy / batteryCapacity * 100)).clamp(0, 100);

 }

 

 return {

 'hour': index,

 'soc': currentSOC,

 };

 });

 }



 void _handleNext() {

 Navigator.push(

 context,

 MaterialPageRoute(

 builder: (context) => FormA4Page(

 institutionType: widget.institutionType,

 institutionName: widget.institutionName,

 location: widget.location,

 numberOfBeds: widget.numberOfBeds,

 solarSurface: widget.solarSurface,

 nonCriticalSurface: widget.nonCriticalSurface,

 monthlyConsumption: widget.monthlyConsumption,

 dailyConsumption: consumptionData.map((e) => e['consumption'] as double).reduce((a, b) => a + b),

 dailyProduction: solarProductionData.map((e) => e['production'] as double).reduce((a, b) => a + b),

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

 title: const Text('Analyse et Graphiques'),

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

 'Analyse de Consommation',

 style: GoogleFonts.inter(

 fontSize: 24,

 fontWeight: FontWeight.bold,

 color: isDark ? Colors.white : MedicalSolarColors.softGrey,

 ),

 ),

 const SizedBox(height: 8),

 Text(

 'Analyse BasÃe©e�e sur vos donne�es',

 style: GoogleFonts.inter(

 fontSize: 14,

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 ),

 ),

 const SizedBox(height: 32),

 // 1. Consommation r�elle

 _buildChartCard(

 context: context,

 isDark: isDark,

 isMobile: isMobile,

 title: 'Consommation re�elle',

 chart: _buildConsumptionChart(isDark, isMobile),

 ),

 const SizedBox(height: 24),

 // 2. Production solaire potentielle

 _buildChartCard(

 context: context,

 isDark: isDark,

 isMobile: isMobile,

 title: 'Production solaire potentielle',

 chart: _buildSolarProductionChart(isDark, isMobile),

 ),

 const SizedBox(height: 24),

 // 3. SOC batterie simul�

 _buildChartCard(

 context: context,

 isDark: isDark,

 isMobile: isMobile,

 title: 'SOC batterie simule�',

 chart: _buildBatterySOCChart(isDark, isMobile),

 ),

 const SizedBox(height: 24),

 // 4. ImpaCoût m�t�o (ensoleillement)

 _buildChartCard(

 context: context,

 isDark: isDark,

 isMobile: isMobile,

 title: 'ImpaCoût me�te�o (ensoleillement, irradiation)',

 chart: _buildWeatherImpactChart(isDark, isMobile),

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

 const SizedBox(height: 24),

 ],

 ),

 ),

 ),

 ),

 );

 }



 Widget _buildChartCard({

 required BuildContext context,

 required bool isDark,

 required bool isMobile,

 required String title,

 required Widget chart,

 }) {

 return Container(

 padding: EdgeInsets.all(isMobile ? 16 : 20),

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

 child: Column(

 crossAxisAlignment: CrossAxisAlignment.start,

 children: [

 Text(

 title,

 style: GoogleFonts.inter(

 fontSize: isMobile ? 16 : 18,

 fontWeight: FontWeight.w600,

 color: isDark ? Colors.white : MedicalSolarColors.softGrey,

 ),

 ),

 SizedBox(height: isMobile ? 16 : 24),

 chart,

 ],

 ),

 );

 }



 Widget _buildConsumptionChart(bool isDark, bool isMobile) {

 final maxConsumption = consumptionData

 .map((e) => e['consumption'] as double)

 .reduce((a, b) => a > b ? a : b);



 return SizedBox(

 height: isMobile ? 250 : 300,

 child: LineChart(

 LineChartData(

 gridData: FlGridData(

 show: true,

 drawVerticalLine: false,

 getDrawingHorizontalLine: (value) {

 return FlLine(

 color: isDark

 ? Colors.white.withOpacity(0.15)

 : MedicalSolarColors.softGrey.withOpacity(0.15),

 strokeWidth: 1,

 dashArray: [5, 5],

 );

 },

 ),

 titlesData: FlTitlesData(

 show: true,

 rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 bottomTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: 30,

 interval: 4,

 getTitlesWidget: (value, meta) {

 final hour = value.toInt();

 if (hour % 4 == 0 && hour < 24) {

 return Padding(

 padding: const EdgeInsets.only(top: 8),

 child: Text(

 '$hour h',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 ),

 );

 }

 return const Text('');

 },

 ),

 ),

 leftTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: isMobile ? 35 : 40,

 getTitlesWidget: (value, meta) {

 return Text(

 '${(value / 1000).toStringAsFixed(1)}k',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 );

 },

 ),

 ),

 ),

 borderData: FlBorderData(show: false),

 minX: 0,

 maxX: 23,

 minY: 0,

 maxY: maxConsumption * 1.2,

 lineBarsData: [

 LineChartBarData(

 spots: consumptionData.map((e) {

 return FlSpot(

 (e['hour'] as int).toDouble(),

 e['consumption'] as double,

 );

 }).toList(),

 isCurved: true,

 gradient: const LinearGradient(

 colors: [MedicalSolarColors.medicalBlue, MedicalSolarColors.solarGreen],

 ),

 barWidth: 3,

 isStrokeCapRound: true,

 dotData: const FlDotData(show: false),

 belowBarData: BarAreaData(

 show: true,

 gradient: LinearGradient(

 colors: [

 MedicalSolarColors.medicalBlue.withOpacity(0.3),

 MedicalSolarColors.medicalBlue.withOpacity(0),

 ],

 begin: Alignment.topCenter,

 end: Alignment.bottomCenter,

 ),

 ),

 ),

 ],

 ),

 ),

 );

 }



 Widget _buildSolarProductionChart(bool isDark, bool isMobile) {

 final maxProduction = solarProductionData

 .map((e) => e['production'] as double)

 .reduce((a, b) => a > b ? a : b);



 return SizedBox(

 height: isMobile ? 250 : 300,

 child: LineChart(

 LineChartData(

 gridData: FlGridData(

 show: true,

 drawVerticalLine: false,

 getDrawingHorizontalLine: (value) {

 return FlLine(

 color: isDark

 ? Colors.white.withOpacity(0.15)

 : MedicalSolarColors.softGrey.withOpacity(0.15),

 strokeWidth: 1,

 dashArray: [5, 5],

 );

 },

 ),

 titlesData: FlTitlesData(

 show: true,

 rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 bottomTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: 30,

 interval: 4,

 getTitlesWidget: (value, meta) {

 final hour = value.toInt();

 if (hour % 4 == 0 && hour < 24) {

 return Padding(

 padding: const EdgeInsets.only(top: 8),

 child: Text(

 '$hour h',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 ),

 );

 }

 return const Text('');

 },

 ),

 ),

 leftTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: isMobile ? 35 : 40,

 getTitlesWidget: (value, meta) {

 return Text(

 '${(value / 1000).toStringAsFixed(1)}k',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 );

 },

 ),

 ),

 ),

 borderData: FlBorderData(show: false),

 minX: 0,

 maxX: 23,

 minY: 0,

 maxY: maxProduction > 0 ? maxProduction * 1.2 : 100,

 lineBarsData: [

 LineChartBarData(

 spots: solarProductionData.map((e) {

 return FlSpot(

 (e['hour'] as int).toDouble(),

 e['production'] as double,

 );

 }).toList(),

 isCurved: true,

 gradient: const LinearGradient(

 colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],

 ),

 barWidth: 3,

 isStrokeCapRound: true,

 dotData: const FlDotData(show: false),

 belowBarData: BarAreaData(

 show: true,

 gradient: LinearGradient(

 colors: [

 const Color(0xFFFFD700).withOpacity(0.3),

 const Color(0xFFFFD700).withOpacity(0),

 ],

 begin: Alignment.topCenter,

 end: Alignment.bottomCenter,

 ),

 ),

 ),

 ],

 ),

 ),

 );

 }



 Widget _buildBatterySOCChart(bool isDark, bool isMobile) {

 return SizedBox(

 height: isMobile ? 250 : 300,

 child: LineChart(

 LineChartData(

 gridData: FlGridData(

 show: true,

 drawVerticalLine: false,

 getDrawingHorizontalLine: (value) {

 return FlLine(

 color: isDark

 ? Colors.white.withOpacity(0.15)

 : MedicalSolarColors.softGrey.withOpacity(0.15),

 strokeWidth: 1,

 dashArray: [5, 5],

 );

 },

 ),

 titlesData: FlTitlesData(

 show: true,

 rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 bottomTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: 30,

 interval: 4,

 getTitlesWidget: (value, meta) {

 final hour = value.toInt();

 if (hour % 4 == 0 && hour < 24) {

 return Padding(

 padding: const EdgeInsets.only(top: 8),

 child: Text(

 '$hour h',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 ),

 );

 }

 return const Text('');

 },

 ),

 ),

 leftTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: isMobile ? 35 : 40,

 getTitlesWidget: (value, meta) {

 return Text(

 '${value.toInt()}%',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 );

 },

 ),

 ),

 ),

 borderData: FlBorderData(show: false),

 minX: 0,

 maxX: 23,

 minY: 0,

 maxY: 100,

 lineBarsData: [

 LineChartBarData(

 spots: batterySOCData.map((e) {

 return FlSpot(

 (e['hour'] as int).toDouble(),

 e['soc'] as double,

 );

 }).toList(),

 isCurved: true,

 gradient: const LinearGradient(

 colors: [MedicalSolarColors.solarGreen, Color(0xFF8B5CF6)],

 ),

 barWidth: 3,

 isStrokeCapRound: true,

 dotData: const FlDotData(show: false),

 belowBarData: BarAreaData(

 show: true,

 gradient: LinearGradient(

 colors: [

 MedicalSolarColors.solarGreen.withOpacity(0.3),

 MedicalSolarColors.solarGreen.withOpacity(0),

 ],

 begin: Alignment.topCenter,

 end: Alignment.bottomCenter,

 ),

 ),

 ),

 ],

 ),

 ),

 );

 }



Widget _buildWeatherImpactChart(bool isDark, bool isMobile) {

// Simulate weather impact (sunshine hours, irradiation)

final weatherData = List.generate(24, (index) {

double impact = 0;

if (index >= 6 && index <= 18) {

final hourOfDay = index - 6;

impact = 80 + (hourOfDay < 6 ? hourOfDay * 3 : (12 - hourOfDay) * 3);

}

return {'hour': index, 'impact': impact};

 });



 return SizedBox(

 height: isMobile ? 250 : 300,

 child: BarChart(

 BarChartData(

 gridData: FlGridData(

 show: true,

 drawVerticalLine: false,

 getDrawingHorizontalLine: (value) {

 return FlLine(

 color: isDark

 ? Colors.white.withOpacity(0.15)

 : MedicalSolarColors.softGrey.withOpacity(0.15),

 strokeWidth: 1,

 dashArray: [5, 5],

 );

 },

 ),

 titlesData: FlTitlesData(

 show: true,

 rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

 bottomTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: 30,

 interval: 4,

 getTitlesWidget: (value, meta) {

 final hour = value.toInt();

 if (hour % 4 == 0 && hour < 24) {

 return Padding(

 padding: const EdgeInsets.only(top: 8),

 child: Text(

 '$hour h',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 ),

 );

 }

 return const Text('');

 },

 ),

 ),

 leftTitles: AxisTitles(

 sideTitles: SideTitles(

 showTitles: true,

 reservedSize: isMobile ? 35 : 40,

 getTitlesWidget: (value, meta) {

 return Text(

 '${value.toInt()}%',

 style: TextStyle(

 color: isDark

 ? Colors.white.withOpacity(0.7)

 : MedicalSolarColors.softGrey.withOpacity(0.7),

 fontSize: isMobile ? 10 : 12,

 ),

 );

 },

 ),

 ),

 ),

 borderData: FlBorderData(show: false),

 barGroups: weatherData.asMap().entries.map((e) {

 return BarChartGroupData(

 x: e.key,

 barRods: [

 BarChartRodData(

 toY: (e.value['impact'] as double),

 gradient: const LinearGradient(

 colors: [Color(0xFFFFD700), Color(0xFFFFA500)],

 begin: Alignment.bottomCenter,

 end: Alignment.topCenter,

 ),

 width: isMobile ? 12 : 16,

 borderRadius: const BorderRadius.vertical(

 top: Radius.circular(8),

 ),

 ),

 ],

 );

 }).toList(),

 ),

 ),

 );

 }

}



