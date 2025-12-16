import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospital_microgrid/widgets/metric_card.dart';
import 'package:hospital_microgrid/services/ai_service.dart';
import 'package:hospital_microgrid/services/establishment_service.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';
class AIPredictionPageIntegrated extends StatefulWidget {
 const AIPredictionPageIntegrated({super.key});

 @override
 State<AIPredictionPageIntegrated> createState() => _AIPredictionPageIntegratedState();
}

class _AIPredictionPageIntegratedState extends State<AIPredictionPageIntegrated> {
 int? _establishmentId;
 bool _isLoading = true;
 String? _errorMessage;
 int _selectedHorizonDays = 7; // Par defaut 7 jours
 String? _selectedSeason; // null = mode horizon, sinon 'ete', 'hiver', 'printemps', 'automne'
 String _forecastMode = 'horizon'; // 'horizon' ou 'seasonal'
 
 LongTermForecastResponse? _forecast;
 LongTermForecastResponse? _seasonalForecast; // Predictions saisonnieres
 MlRecommendationsResponse? _mlRecommendations;
 AnomalyGraphResponse? _anomalies;
 SimulationResponse? _simulation;

 @override
 void initState() {
 super.initState();
 _loadData();
 }

 Future<void> _loadData() async {
 if (!mounted) return;
 
 setState(() {
 _isLoading = true;
 _errorMessage = null;
 });

 try {
 // Recuperer le premier établissement de l'utilisateur avec timeout
 final establishments = await EstablishmentService.getUserEstablishments()
   .timeout(const Duration(seconds: 5), onTimeout: () {
     throw TimeoutException('Timeout lors de la récupération des établissements', const Duration(seconds: 5));
   });
 if (establishments.isEmpty) {
 if (mounted) {
 setState(() {
 _errorMessage = 'Aucun établissement trouvé. Veuillez créer un établissement d\'abord.';
 _isLoading = false;
 });
 }
 return;
 }

 _establishmentId = establishments.first.id;

 // S'assurer que _selectedSeason est defini si on est en mode seasonal
 if (_forecastMode == 'seasonal' && _selectedSeason == null) {
 _selectedSeason = 'ete';
 }

 // Charger les données individuellement avec timeouts courts pour éviter le blocage
 // Timeout réduit à 8 secondes pour éviter le blocage
 const timeoutDuration = Duration(seconds: 8);
 
 // Charger les prévisions (avec vérification mounted)
 if (mounted) {
 try {
 if (_forecastMode == 'seasonal' && _selectedSeason != null) {
 _seasonalForecast = await AiService.getSeasonalForecast(_establishmentId!, season: _selectedSeason!)
 .timeout(timeoutDuration, onTimeout: () {
 throw TimeoutException('Timeout lors du chargement des prévisions saisonnières', timeoutDuration);
 });
 _forecast = null;
 } else {
 _forecast = await AiService.getForecast(_establishmentId!, horizonDays: _selectedHorizonDays)
 .timeout(timeoutDuration, onTimeout: () {
 throw TimeoutException('Timeout lors du chargement des prévisions', timeoutDuration);
 });
 _seasonalForecast = null;
 }
 } catch (e) {
 debugPrint('Erreur lors du chargement des prévisions: $e');
 // Continuer même si les prévisions échouent
 }
 }
 
 // Charger les recommandations ML (avec vérification mounted)
 if (mounted) {
 try {
 _mlRecommendations = await AiService.getMlRecommendations(_establishmentId!)
 .timeout(timeoutDuration, onTimeout: () {
 throw TimeoutException('Timeout lors du chargement des recommandations ML', timeoutDuration);
 });
 } catch (e) {
 debugPrint('Erreur lors du chargement des recommandations ML: $e');
 // Continuer même si les recommandations échouent
 }
 }
 
 // Charger les anomalies (avec vérification mounted)
 if (mounted) {
 try {
 _anomalies = await AiService.getAnomalies(_establishmentId!, days: 7)
 .timeout(timeoutDuration, onTimeout: () {
 throw TimeoutException('Timeout lors du chargement des anomalies', timeoutDuration);
 });
 } catch (e) {
 debugPrint('Erreur lors du chargement des anomalies: $e');
 // Continuer même si les anomalies échouent
 }
 }
 
 // Charger la simulation (optionnel, peut être ignoré si échoue) (avec vérification mounted)
 if (mounted) {
 try {
 _simulation = await AiService.simulate(
 _establishmentId!,
 startDate: DateTime.now().toIso8601String(),
 days: 3,
 batteryCapacityKwh: 500.0,
 initialSocKwh: 250.0,
 ).timeout(timeoutDuration, onTimeout: () {
 throw TimeoutException('Timeout lors de la simulation', timeoutDuration);
 });
 } catch (e) {
 debugPrint('Erreur lors de la simulation: $e');
 // La simulation est optionnelle, on continue
 }
 }
 
 // Toujours mettre à jour l'état même si certaines données n'ont pas pu être chargées
 if (mounted) {
 setState(() {
 _isLoading = false;
 // Si aucune donnée n'a pu être chargée, afficher un message
 if (_forecast == null && _seasonalForecast == null && _mlRecommendations == null && _anomalies == null) {
 _errorMessage = 'Impossible de charger les données AI. Vérifiez que le service AI est disponible.';
 }
 });
 }
 } catch (e) {
 // Gérer les erreurs critiques (établissements, etc.)
 if (mounted) {
 setState(() {
 final errorMsg = e.toString();
 if (errorMsg.contains('403') || errorMsg.contains('401')) {
 _errorMessage = 'Erreur d\'authentification. Veuillez vous reconnecter.';
 } else if (errorMsg.contains('404')) {
 _errorMessage = 'Ressource non trouvée. Vérifiez que l\'établissement existe.';
 } else {
 _errorMessage = 'Erreur lors du chargement: ${errorMsg.length > 100 ? errorMsg.substring(0, 100) + "..." : errorMsg}';
 }
 _isLoading = false;
 });
 }
 }
 }

 Future<void> _onRefresh() async {
 if (!mounted) return;
 await _loadData();
 }

 @override
 Widget build(BuildContext context) {
 final isMobile = MediaQuery.of(context).size.width < 600;
 
 if (_isLoading) {
 return Scaffold(
 body: Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 const CircularProgressIndicator(),
 const SizedBox(height: 16),
 Text(
 'Chargement des donnéees AI...',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.7)
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 ),
 ),
 ],
 ),
 ),
 );
 }

 if (_errorMessage != null) {
 return Scaffold(
 body: Center(
 child: Padding(
 padding: const EdgeInsets.all(24.0),
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 Icon(
 Icons.error_outline,
 size: 64,
 color: Colors.red.withOpacity(0.7),
 ),
 const SizedBox(height: 16),
 Text(
 _errorMessage!,
 textAlign: TextAlign.center,
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 16,
 ),
 ),
 const SizedBox(height: 24),
 ElevatedButton(
 onPressed: () {
 if (mounted) {
 _loadData();
 }
 },
 child: const Text('Réessayer'),
 ),
 ],
 ),
 ),
 ),
 );
 }
 
 return RefreshIndicator(
 onRefresh: _onRefresh,
 color: MedicalSolarColors.medicalBlue,
 child: SingleChildScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 padding: EdgeInsets.symmetric(
 horizontal: isMobile ? 16 : 20,
 vertical: 16,
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const SizedBox(height: 16),
 Text(
 'Machine Learning : Prvisions Consommation (XGBoost/RandomForest) & Production PV (GradientBoosting)',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark 
 ? Colors.white.withOpacity(0.7) 
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 fontSize: 14,
 fontWeight: FontWeight.w500,
 ),
 ),
 const SizedBox(height: 20),
 // Metrics Cards
 _buildMetricsCards(isMobile),
 const SizedBox(height: 24),
 // Forecast Chart (horizon ou saisonnier)
 if (_forecast != null) _buildForecastChart(_forecast!, isMobile),
 if (_seasonalForecast != null) _buildForecastChart(_seasonalForecast!, isMobile, isSeasonal: true, season: _selectedSeason),
 const SizedBox(height: 24),
 // Anomalies Chart
 if (_anomalies != null) _buildAnomaliesCard(_anomalies!),
 const SizedBox(height: 24),
 // ML Recommendations
 if (_mlRecommendations != null) _buildMlRecommendationsCard(_mlRecommendations!),
 ],
 ),
 ),
 );
 }

 double _average(List<double> values) {
 if (values.isEmpty) return 0.0;
 return values.reduce((a, b) => a + b) / values.length;
 }

 double _maxValue(List<double> values) {
 if (values.isEmpty) return 0.0;
 return values.reduce((a, b) => a > b ? a : b);
 }

 Widget _buildMetricsCards(bool isMobile) {
 final roi = _mlRecommendations?.predictedRoiYears ?? 0.0;
 final totalAnomalies = _anomalies?.statistics.totalAnomalies ?? 0;
 final avgConsumption = _forecast?.predictions.isNotEmpty == true
 ? _average(_forecast!.predictions.map((e) => e.predictedConsumption).toList())
 : 0.0;
 final avgPv = _forecast?.predictions.isNotEmpty == true
 ? _average(_forecast!.predictions.map((e) => e.predictedPvProduction).toList())
 : 0.0;

 if (isMobile) {
 return SizedBox(
 height: 140,
 child: ListView(
 scrollDirection: Axis.horizontal,
 padding: const EdgeInsets.symmetric(vertical: 4),
 children: [
 MetricCard(
 icon: Icons.trending_up,
 label: 'ROI Préedit ${_mlRecommendations?.confidence == "high" ? "?? ML" : ""}',
 value: '${roi.toStringAsFixed(1)} ans',
 change: roi < 10 ? 'Excellent' : roi < 20 ? 'Bon' : 'Modéerée',
 gradientColors: const [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.solarGreen,
 ],
 ),
 const SizedBox(width: 12),
 MetricCard(
 icon: Icons.warning_amber,
 label: 'Anomalies',
 value: '$totalAnomalies',
 change: totalAnomalies > 0 ? 'Déetectéees' : 'Aucune',
 gradientColors: const [
 MedicalSolarColors.solarGreen,
 MedicalSolarColors.medicalBlue,
 ],
 ),
 const SizedBox(width: 12),
 MetricCard(
 icon: Icons.bolt,
 label: 'Consommation Moy.',
 value: '${(avgConsumption / 1000).toStringAsFixed(1)} MW',
 change: '7 jours',
 gradientColors: const [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.medicalBlue,
 ],
 ),
 const SizedBox(width: 12),
 MetricCard(
 icon: Icons.solar_power,
 label: 'PV Moyen',
 value: '${(avgPv / 1000).toStringAsFixed(1)} MW',
 change: '7 jours',
 gradientColors: const [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.medicalBlue,
 ],
 ),
 ],
 ),
 );
 }

 return LayoutBuilder(
 builder: (context, constraints) {
 int crossAxisCount = 4;
 if (constraints.maxWidth < 1200) crossAxisCount = 2;
 
 return GridView.count(
 crossAxisCount: crossAxisCount,
 shrinkWrap: true,
 physics: const NeverScrollableScrollPhysics(),
 crossAxisSpacing: 16,
 mainAxisSpacing: 16,
 childAspectRatio: 1.2,
 children: [
 MetricCard(
 icon: Icons.trending_up,
 label: 'ROI Préedit ${_mlRecommendations?.confidence == "high" ? "?? ML" : ""}',
 value: '${roi.toStringAsFixed(1)} ans',
 change: roi < 10 ? 'Excellent' : roi < 20 ? 'Bon' : 'Modéerée',
 gradientColors: const [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.solarGreen,
 ],
 ),
 MetricCard(
 icon: Icons.warning_amber,
 label: 'Anomalies',
 value: '$totalAnomalies',
 change: totalAnomalies > 0 ? 'Déetectéees' : 'Aucune',
 gradientColors: const [
 MedicalSolarColors.solarGreen,
 MedicalSolarColors.medicalBlue,
 ],
 ),
 MetricCard(
 icon: Icons.bolt,
 label: 'Consommation Moy.',
 value: '${(avgConsumption / 1000).toStringAsFixed(1)} MW',
 change: '7 jours',
 gradientColors: const [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.medicalBlue,
 ],
 ),
 MetricCard(
 icon: Icons.solar_power,
 label: 'PV Moyen',
 value: '${(avgPv / 1000).toStringAsFixed(1)} MW',
 change: '7 jours',
 gradientColors: const [
 MedicalSolarColors.medicalBlue,
 MedicalSolarColors.medicalBlue,
 ],
 ),
 ],
 );
 },
 );
 }

 Widget _buildForecastChart(LongTermForecastResponse forecast, bool isMobile, {bool isSeasonal = false, String? season}) {
 if (forecast.predictions.isEmpty) {
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: Theme.of(context).cardColor,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.1)
 : Colors.grey.withOpacity(0.2),
 ),
 ),
 child: const Center(
 child: Text('Aucune donnéee de préevision disponible'),
 ),
 );
 }

 final maxConsumption = _maxValue(forecast.predictions.map((e) => e.predictedConsumption).toList());
 final isML = forecast.method == 'ml_random_forest';
 
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: Theme.of(context).cardColor,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.1)
 : Colors.grey.withOpacity(0.2),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Text(
 'Préevision ',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 18,
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(width: 8),
 // Selecteur de mode (Horizon ou Saison)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.1)
 : Colors.grey.withOpacity(0.1),
 borderRadius: BorderRadius.circular(6),
 ),
 child: DropdownButton<String>(
 value: _forecastMode,
 underline: const SizedBox(),
 isDense: true,
 icon: Icon(
 Icons.arrow_drop_down,
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 size: 20,
 ),
 items: const [
 DropdownMenuItem(value: 'horizon', child: Text('Par horizon')),
 DropdownMenuItem(value: 'seasonal', child: Text('Par saison')),
 ],
 onChanged: (String? newValue) {
 if (newValue != null && newValue != _forecastMode) {
 setState(() {
 _forecastMode = newValue;
 if (newValue == 'seasonal' && _selectedSeason == null) {
 _selectedSeason = 'ete'; // Par defaut ete
 }
 });
 _loadData();
 }
 },
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 13,
 ),
 ),
 ),
 const SizedBox(width: 8),
 // Selecteur selon le mode
 if (_forecastMode == 'horizon')
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 decoration: BoxDecoration(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.15)
 : Colors.blue.withOpacity(0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.3)
 : Colors.blue.withOpacity(0.4),
 width: 1.5,
 ),
 ),
 child: DropdownButton<int>(
 value: _selectedHorizonDays,
 underline: const SizedBox(),
 isDense: true,
 icon: Icon(
 Icons.arrow_drop_down,
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : Colors.blue,
 size: 24,
 ),
 items: const [
 DropdownMenuItem(value: 7, child: Text('7 jours')),
 DropdownMenuItem(value: 14, child: Text('14 jours')),
 DropdownMenuItem(value: 30, child: Text('30 jours')),
 ],
 onChanged: (int? newValue) {
 if (newValue != null && newValue != _selectedHorizonDays) {
 setState(() {
 _selectedHorizonDays = newValue;
 });
 _loadData();
 }
 },
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : Colors.blue,
 fontSize: 15,
 fontWeight: FontWeight.w600,
 ),
 ),
 )
 else
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 decoration: BoxDecoration(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.15)
 : Colors.orange.withOpacity(0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.3)
 : Colors.orange.withOpacity(0.4),
 width: 1.5,
 ),
 ),
 child: DropdownButton<String>(
 value: _selectedSeason ?? 'ete',
 underline: const SizedBox(),
 isDense: true,
 icon: Icon(
 Icons.arrow_drop_down,
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : Colors.orange,
 size: 24,
 ),
 items: const [
 DropdownMenuItem(value: 'ete', child: Text('éetée')),
 DropdownMenuItem(value: 'hiver', child: Text('Hiver')),
 DropdownMenuItem(value: 'printemps', child: Text('Printemps')),
 DropdownMenuItem(value: 'automne', child: Text('Automne')),
 ],
 onChanged: (String? newValue) {
 if (newValue != null && newValue != _selectedSeason) {
 setState(() {
 _selectedSeason = newValue;
 });
 _loadData();
 }
 },
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : Colors.orange,
 fontSize: 15,
 fontWeight: FontWeight.w600,
 ),
 ),
 ),
 Text(
 isSeasonal 
 ? ' - Consommation & Production PV (${_getSeasonName(season ?? "ete")})'
 : ' - Consommation & Production PV',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 18,
 fontWeight: FontWeight.w600,
 ),
 ),
 ],
 ),
 ],
 ),
 ),
 if (isML)
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.green.withOpacity(0.2),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: Colors.green, width: 1),
 ),
 child: const Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.psychology, size: 16, color: Colors.green),
 SizedBox(width: 4),
 Text(
 'ML',
 style: TextStyle(
 color: Colors.green,
 fontSize: 12,
 fontWeight: FontWeight.bold,
 ),
 ),
 ],
 ),
 )
 else
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
 decoration: BoxDecoration(
 color: Colors.orange.withOpacity(0.2),
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: Colors.orange, width: 1),
 ),
 child: const Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(Icons.calculate, size: 16, color: Colors.orange),
 SizedBox(width: 4),
 Text(
 'Calcul',
 style: TextStyle(
 color: Colors.orange,
 fontSize: 12,
 fontWeight: FontWeight.bold,
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 const SizedBox(height: 24),
 SizedBox(
 height: isMobile ? 320 : 400,
 width: double.infinity,
 child: LineChart(
 LineChartData(
 gridData: FlGridData(
 show: true,
 drawVerticalLine: false,
 horizontalInterval: 200,
 getDrawingHorizontalLine: (value) {
 return FlLine(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.1)
 : Colors.grey.withOpacity(0.2),
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
 interval: forecast.predictions.length <= 7 ? 1 : (forecast.predictions.length <= 14 ? 2 : 3),
 getTitlesWidget: (value, meta) {
 final dayIndex = value.toInt();
 if (dayIndex >= 0 && dayIndex < forecast.predictions.length) {
 return Padding(
 padding: const EdgeInsets.only(top: 8),
 child: Text(
 'J${dayIndex + 1}',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.5)
 : Colors.grey.withOpacity(0.7),
 fontSize: 12,
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
 reservedSize: 40,
 getTitlesWidget: (value, meta) {
 return Text(
 '${(value / 1000).toStringAsFixed(1)}k',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.5)
 : Colors.grey.withOpacity(0.7),
 fontSize: 12,
 ),
 );
 },
 ),
 ),
 ),
 borderData: FlBorderData(show: false),
 minX: 0,
 maxX: (forecast.predictions.length - 1).toDouble(),
 minY: 0,
 maxY: maxConsumption * 1.2,
 lineBarsData: [
 LineChartBarData(
 spots: forecast.predictions.asMap().entries.map((e) {
 return FlSpot(
 e.key.toDouble(),
 e.value.predictedConsumption,
 );
 }).toList(),
 isCurved: true,
 gradient: const LinearGradient(
 colors: [MedicalSolarColors.medicalBlue, MedicalSolarColors.medicalBlueDark],
 ),
 barWidth: 3,
 isStrokeCapRound: true,
 dotData: const FlDotData(show: false),
 ),
 LineChartBarData(
 spots: forecast.predictions.asMap().entries.map((e) {
 return FlSpot(
 e.key.toDouble(),
 e.value.predictedPvProduction,
 );
 }).toList(),
 isCurved: true,
 gradient: const LinearGradient(
 colors: [Color(0xFF00E5FF), Color(0xFF006064)],
 ),
 barWidth: 3,
 isStrokeCapRound: true,
 dotData: const FlDotData(show: false),
 ),
 ],
 lineTouchData: LineTouchData(
 touchTooltipData: LineTouchTooltipData(
 getTooltipItems: (List<LineBarSpot> touchedSpots) {
 return touchedSpots.map((LineBarSpot touchedSpot) {
 return LineTooltipItem(
 '${touchedSpot.y.toInt()} kWh',
 TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontWeight: FontWeight.bold,
 ),
 );
 }).toList();
 },
 ),
 ),
 ),
 ),
 ),
 const SizedBox(height: 16),
 Row(
 children: [
 _buildLegendItem('Consommation', const Color(0xFF7C3AED)),
 const SizedBox(width: 24),
 _buildLegendItem('Production PV', const Color(0xFF00E5FF)),
 ],
 ),
 ],
 ),
 );
 }

 String _getSeasonName(String season) {
 switch (season.toLowerCase()) {
 case 'ete':
 return 'éetée';
 case 'hiver':
 return 'Hiver';
 case 'printemps':
 return 'Printemps';
 case 'automne':
 return 'Automne';
 default:
 return 'éetée';
 }
 }

 Widget _buildLegendItem(String label, Color color) {
 return Row(
 children: [
 Container(
 width: 12,
 height: 12,
 decoration: BoxDecoration(
 color: color,
 shape: BoxShape.circle,
 ),
 ),
 const SizedBox(width: 8),
 Text(
 label,
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.7)
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 fontSize: 14,
 ),
 ),
 ],
 );
 }

 Widget _buildAnomaliesCard(AnomalyGraphResponse anomalies) {
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: Theme.of(context).cardColor,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.1)
 : Colors.grey.withOpacity(0.2),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Déetection d\'Anomalies',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 18,
 fontWeight: FontWeight.w600,
 ),
 ),
 const SizedBox(height: 16),
 Row(
 children: [
 Expanded(
 child: _buildStatItem(
 'Total',
 '${anomalies.statistics.totalAnomalies}',
 Icons.warning_amber,
 ),
 ),
 Expanded(
 child: _buildStatItem(
 'Type Principal',
 anomalies.statistics.mostCommonAnomalyType,
 Icons.info_outline,
 ),
 ),
 Expanded(
 child: _buildStatItem(
 'Score Moyen',
 anomalies.statistics.averageAnomalyScore.toStringAsFixed(2),
 Icons.assessment,
 ),
 ),
 ],
 ),
 if (anomalies.anomalies.where((a) => a.isAnomaly).isNotEmpty) ...[
 const SizedBox(height: 16),
 const Divider(),
 const SizedBox(height: 16),
 Text(
 'Anomalies réecentes:',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.7)
 : MedicalSolarColors.softGrey.withOpacity(0.7),
 fontSize: 14,
 fontWeight: FontWeight.w500,
 ),
 ),
 const SizedBox(height: 12),
 ...anomalies.anomalies
 .where((a) => a.isAnomaly)
 .take(5)
 .map((anomaly) => Padding(
 padding: const EdgeInsets.only(bottom: 12),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const Icon(
 Icons.warning,
 color: Colors.orange,
 size: 20,
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 anomaly.anomalyType ?? 'Anomalie inconnue',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 14,
 fontWeight: FontWeight.w500,
 ),
 ),
 if (anomaly.recommendation != null) ...[
 const SizedBox(height: 4),
 Text(
 anomaly.recommendation!,
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.6)
 : MedicalSolarColors.softGrey.withOpacity(0.6),
 fontSize: 12,
 ),
 ),
 ],
 ],
 ),
 ),
 ],
 ),
 )),
 ],
 ],
 ),
 );
 }

 Widget _buildStatItem(String label, String value, IconData icon) {
 return Column(
 children: [
 Icon(icon, size: 24, color: MedicalSolarColors.medicalBlue),
 const SizedBox(height: 8),
 Text(
 value,
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 18,
 fontWeight: FontWeight.bold,
 ),
 ),
 const SizedBox(height: 4),
 Text(
 label,
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.6)
 : MedicalSolarColors.softGrey.withOpacity(0.6),
 fontSize: 12,
 ),
 ),
 ],
 );
 }

 Widget _buildMlRecommendationsCard(MlRecommendationsResponse recommendations) {
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: Theme.of(context).cardColor,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.1)
 : Colors.grey.withOpacity(0.2),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
 'Recommandations ML',
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 18,
 fontWeight: FontWeight.w600,
 ),
 ),
 Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 decoration: BoxDecoration(
 color: recommendations.confidence == 'high'
 ? Colors.green.withOpacity(0.2)
 : Colors.orange.withOpacity(0.2),
 borderRadius: BorderRadius.circular(12),
 ),
 child: Text(
 'Confiance: ${recommendations.confidence}',
 style: TextStyle(
 color: recommendations.confidence == 'high'
 ? Colors.green
 : Colors.orange,
 fontSize: 12,
 fontWeight: FontWeight.w500,
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 16),
 if (recommendations.recommendations.isNotEmpty)
 ...recommendations.recommendations.map((rec) => Padding(
 padding: const EdgeInsets.only(bottom: 16),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(
 width: 8,
 height: 8,
 margin: const EdgeInsets.only(top: 8, right: 12),
 decoration: BoxDecoration(
 color: rec.type == 'success'
 ? Colors.green
 : rec.type == 'warning'
 ? Colors.orange
 : MedicalSolarColors.medicalBlue,
 shape: BoxShape.circle,
 ),
 ),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 rec.message,
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white
 : MedicalSolarColors.softGrey,
 fontSize: 16,
 fontWeight: FontWeight.w500,
 ),
 ),
 if (rec.suggestion != null) ...[
 const SizedBox(height: 4),
 Text(
 rec.suggestion!,
 style: TextStyle(
 color: Theme.of(context).brightness == Brightness.dark
 ? Colors.white.withOpacity(0.6)
 : MedicalSolarColors.softGrey.withOpacity(0.6),
 fontSize: 14,
 ),
 ),
 ],
 ],
 ),
 ),
 ],
 ),
 )),
 ],
 ),
 );
 }
}


