import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hospital_microgrid/services/ai_service.dart';
import 'package:hospital_microgrid/theme/semantic_colors.dart';
import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class AutoLearningPage extends StatefulWidget {
 const AutoLearningPage({super.key});

 @override
 State<AutoLearningPage> createState() => _AutoLearningPageState();
}

class _AutoLearningPageState extends State<AutoLearningPage> {
 MLMetricsResponse? _metrics;
 bool _isLoading = true;
 String? _error;
 bool _isRetraining = false;

 @override
 void initState() {
 super.initState();
 _loadMetrics();
 }

 Future<void> _loadMetrics() async {
 setState(() {
 _isLoading = true;
 _error = null;
 });

 try {
 final metrics = await AiService.getMetrics();
 setState(() {
 _metrics = metrics;
 _isLoading = false;
 });
 } catch (e) {
 setState(() {
 _error = e.toString();
 _isLoading = false;
 });
 }
 }

 Future<void> _triggerRetrain() async {
 setState(() {
 _isRetraining = true;
 });

 try {
 await AiService.retrain();
 // Recharger les mtriques après rentraînement
 await _loadMetrics();
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: const Text('Modèle rentraîn avec succès'),
 backgroundColor: SemanticColors.success(context),
 ),
 );
 }
 } catch (e) {
 if (mounted) {
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text('Erreur lors du rentraînement: ${e.toString()}'),
 backgroundColor: SemanticColors.error(context),
 ),
 );
 }
 } finally {
 if (mounted) {
 setState(() {
 _isRetraining = false;
 });
 }
 }
 }

 @override
 Widget build(BuildContext context) {
 final isDark = Theme.of(context).brightness == Brightness.dark;
 final isMobile = MediaQuery.of(context).size.width < 600;

 return RefreshIndicator(
 onRefresh: _loadMetrics,
 child: SingleChildScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 padding: EdgeInsets.all(isMobile ? 16 : 24),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 const SizedBox(height: 8),
 Text(
 'Auto-Learning & Mtriques ML',
 style: GoogleFonts.inter(
 fontSize: isMobile ? 20 : 24,
 fontWeight: FontWeight.bold,
 color: isDark ? Colors.white : MedicalSolarColors.softGrey,
 ),
 ),
 const SizedBox(height: 8),
 Text(
 'Mtriques relles du modèle Machine Learning et historique d\'entraînement',
 style: GoogleFonts.inter(
 fontSize: 14,
 color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF0F172A).withOpacity(0.7),
 ),
 ),
 const SizedBox(height: 24),
 
 if (_isLoading)
 const Center(child: CircularProgressIndicator())
 else if (_error != null)
 _buildErrorWidget(isDark, isMobile)
 else if (_metrics == null)
 _buildNoDataWidget(isDark, isMobile)
 else ...[
 // Mtriques principales
 _buildMetricsCards(_metrics!, isDark, isMobile),
 const SizedBox(height: 24),
 
 // Informations modèle
 _buildModelInfo(_metrics!, isDark, isMobile),
 const SizedBox(height: 24),
 
 // Comparaison Train vs Test
 _buildTrainTestComparison(_metrics!, isDark, isMobile),
 const SizedBox(height: 24),
 
 // Amlioration (si disponible)
 if (_metrics!.improvement != null) ...[
 _buildImprovementCard(_metrics!.improvement!, isDark, isMobile),
 const SizedBox(height: 24),
 ],
 
 // Bouton rentraînement
 _buildRetrainButton(isDark, isMobile),
 ],
 ],
 ),
 ),
 );
 }

 Widget _buildErrorWidget(bool isDark, bool isMobile) {
 return Container(
 padding: const EdgeInsets.all(24),
 decoration: BoxDecoration(
 color: isDark ? const Color(0xFF1E293B) : Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: SemanticColors.error(context),
 width: 1,
 ),
 ),
 child: Column(
 children: [
 Icon(
 Icons.error_outline,
 color: SemanticColors.error(context),
 size: 48,
 ),
 const SizedBox(height: 16),
 Text(
 'Erreur lors du chargement des mtriques',
 style: GoogleFonts.inter(
 fontSize: 16,
 fontWeight: FontWeight.w600,
 color: isDark ? Colors.white : const Color(0xFF0F172A),
 ),
 ),
 const SizedBox(height: 8),
 Text(
 _error ?? 'Erreur inconnue',
 style: GoogleFonts.inter(
 fontSize: 14,
 color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF0F172A).withOpacity(0.7),
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 );
 }

 Widget _buildNoDataWidget(bool isDark, bool isMobile) {
 return Container(
 padding: const EdgeInsets.all(24),
 decoration: BoxDecoration(
 color: isDark ? const Color(0xFF1E293B) : Colors.orange.shade50,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: isDark ? Colors.white.withOpacity(0.1) : Colors.orange.withOpacity(0.3),
 ),
 ),
 child: Column(
 children: [
 const Icon(
 Icons.info_outline,
 color: Colors.orange,
 size: 48,
 ),
 const SizedBox(height: 16),
 Text(
 'Mtriques non disponibles',
 style: GoogleFonts.inter(
 fontSize: 16,
 fontWeight: FontWeight.w600,
 color: isDark ? Colors.white : const Color(0xFF0F172A),
 ),
 ),
 const SizedBox(height: 8),
 Text(
 'Le modèle n\'a pas encore t entraîn. Utilisez le bouton ci-dessous pour dmarrer l\'entraînement.',
 style: GoogleFonts.inter(
 fontSize: 14,
 color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF0F172A).withOpacity(0.7),
 ),
 textAlign: TextAlign.center,
 ),
 ],
 ),
 );
 }

 Widget _buildMetricsCards(MLMetricsResponse metrics, bool isDark, bool isMobile) {
 final testMetrics = metrics.test;
 
 return isMobile
 ? Column(
 children: [
 _buildMetricCard(
 'MAE (Test)',
 '${testMetrics.mae.toStringAsFixed(2)} kWh',
 'Erreur moyenne absolue sur les donnes de test',
 Icons.show_chart,
 const [Color(0xFF2563EB), Color(0xFF7C3AED)],
 isDark,
 ),
 const SizedBox(height: 12),
 _buildMetricCard(
 'RMSE (Test)',
 '${testMetrics.rmse.toStringAsFixed(2)} kWh',
 'Erreur quadratique moyenne sur les donnes de test',
 Icons.trending_up,
 const [Color(0xFF059669), Color(0xFF10B981)],
 isDark,
 ),
 const SizedBox(height: 12),
 _buildMetricCard(
 'MAPE (Test)',
 '${(testMetrics.mape * 100).toStringAsFixed(2)}%',
 'Erreur moyenne absolue en pourcentage',
 Icons.percent,
 const [Color(0xFF7C3AED), Color(0xFF059669)],
 isDark,
 ),
 ],
 )
 : Row(
 children: [
 Expanded(
 child: _buildMetricCard(
 'MAE (Test)',
 '${testMetrics.mae.toStringAsFixed(2)} kWh',
 'Erreur moyenne absolue sur les donnes de test',
 Icons.show_chart,
 const [Color(0xFF2563EB), Color(0xFF7C3AED)],
 isDark,
 ),
 ),
 const SizedBox(width: 16),
 Expanded(
 child: _buildMetricCard(
 'RMSE (Test)',
 '${testMetrics.rmse.toStringAsFixed(2)} kWh',
 'Erreur quadratique moyenne sur les donnes de test',
 Icons.trending_up,
 const [Color(0xFF059669), Color(0xFF10B981)],
 isDark,
 ),
 ),
 const SizedBox(width: 16),
 Expanded(
 child: _buildMetricCard(
 'MAPE (Test)',
 '${(testMetrics.mape * 100).toStringAsFixed(2)}%',
 'Erreur moyenne absolue en pourcentage',
 Icons.percent,
 const [Color(0xFF7C3AED), Color(0xFF059669)],
 isDark,
 ),
 ),
 ],
 );
 }

 Widget _buildMetricCard(
 String label,
 String value,
 String explanation,
 IconData icon,
 List<Color> gradientColors,
 bool isDark,
 ) {
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 gradient: LinearGradient(
 colors: gradientColors,
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 borderRadius: BorderRadius.circular(16),
 boxShadow: [
 BoxShadow(
 color: gradientColors[0].withOpacity(0.3),
 blurRadius: 12,
 offset: const Offset(0, 4),
 ),
 ],
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Icon(icon, color: Colors.white, size: 32),
 Tooltip(
 message: explanation,
 child: const Icon(
 Icons.info_outline,
 color: Colors.white70,
 size: 20,
 ),
 ),
 ],
 ),
 const SizedBox(height: 16),
 Text(
 value,
 style: GoogleFonts.inter(
 fontSize: 28,
 fontWeight: FontWeight.bold,
 color: Colors.white,
 ),
 ),
 const SizedBox(height: 4),
 Text(
 label,
 style: GoogleFonts.inter(
 fontSize: 14,
 fontWeight: FontWeight.w500,
 color: Colors.white.withOpacity(0.9),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildModelInfo(MLMetricsResponse metrics, bool isDark, bool isMobile) {
 final meta = metrics.meta;
 
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: isDark ? const Color(0xFF1E293B) : Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Informations Modèle',
 style: GoogleFonts.inter(
 fontSize: 18,
 fontWeight: FontWeight.bold,
 color: isDark ? Colors.white : const Color(0xFF0F172A),
 ),
 ),
 const SizedBox(height: 16),
 _buildInfoRow('Type de modèle', meta.model, isDark),
 _buildInfoRow('Nombre de features', '${meta.features}', isDark),
 _buildInfoRow('Échantillons d\'entraînement', '${meta.trainRows}', isDark),
 _buildInfoRow('Échantillons de test', '${meta.testRows}', isDark),
 if (meta.timestamp.isNotEmpty)
 _buildInfoRow(
 'Dernière mise à jour',
 _formatTimestamp(meta.timestamp),
 isDark,
 ),
 ],
 ),
 );
 }

 Widget _buildInfoRow(String label, String value, bool isDark) {
 return Padding(
 padding: const EdgeInsets.symmetric(vertical: 8),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
 label,
 style: GoogleFonts.inter(
 fontSize: 14,
 color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF0F172A).withOpacity(0.7),
 ),
 ),
 Text(
 value,
 style: GoogleFonts.inter(
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: isDark ? Colors.white : const Color(0xFF0F172A),
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildTrainTestComparison(MLMetricsResponse metrics, bool isDark, bool isMobile) {
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 color: isDark ? const Color(0xFF1E293B) : Colors.white,
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
 ),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 'Comparaison Train vs Test',
 style: GoogleFonts.inter(
 fontSize: 18,
 fontWeight: FontWeight.bold,
 color: isDark ? Colors.white : const Color(0xFF0F172A),
 ),
 ),
 const SizedBox(height: 16),
 _buildComparisonRow('MAE', metrics.train.mae, metrics.test.mae, 'kWh', isDark),
 _buildComparisonRow('RMSE', metrics.train.rmse, metrics.test.rmse, 'kWh', isDark),
 _buildComparisonRow('MAPE', metrics.train.mape * 100, metrics.test.mape * 100, '%', isDark),
 const SizedBox(height: 8),
 // DteCoûtion sur-entraînement
 if (_detectOverfitting(metrics))
 Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: SemanticColors.warning(context).withOpacity(0.1),
 borderRadius: BorderRadius.circular(8),
 border: Border.all(
 color: SemanticColors.warning(context),
 width: 1,
 ),
 ),
 child: Row(
 children: [
 Icon(
 Icons.warning_amber_rounded,
 color: SemanticColors.warning(context),
 size: 20,
 ),
 const SizedBox(width: 8),
 Expanded(
 child: Text(
 'Sur-entraînement dteCoût (cart important entre train et test)',
 style: GoogleFonts.inter(
 fontSize: 12,
 color: SemanticColors.warning(context),
 ),
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildComparisonRow(String label, double trainValue, double testValue, String unit, bool isDark) {
 final ratio = trainValue > 0 ? testValue / trainValue : 0;
 
 return Padding(
 padding: const EdgeInsets.symmetric(vertical: 8),
 child: Column(
 children: [
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(
 label,
 style: GoogleFonts.inter(
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: isDark ? Colors.white : MedicalSolarColors.softGrey,
 ),
 ),
 Text(
 'Ratio: ${ratio.toStringAsFixed(2)}x',
 style: GoogleFonts.inter(
 fontSize: 12,
 color: isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF0F172A).withOpacity(0.6),
 ),
 ),
 ],
 ),
 const SizedBox(height: 4),
 Row(
 children: [
 Expanded(
 child: Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: isDark ? Colors.white.withOpacity(0.05) : Colors.blue.shade50,
 borderRadius: BorderRadius.circular(8),
 ),
 child: Text(
 'Train: ${trainValue.toStringAsFixed(2)} $unit',
 style: GoogleFonts.inter(
 fontSize: 12,
 color: isDark ? Colors.white : Colors.blue.shade900,
 ),
 ),
 ),
 ),
 const SizedBox(width: 8),
 Expanded(
 child: Container(
 padding: const EdgeInsets.all(8),
 decoration: BoxDecoration(
 color: isDark ? Colors.white.withOpacity(0.05) : Colors.green.shade50,
 borderRadius: BorderRadius.circular(8),
 ),
 child: Text(
 'Test: ${testValue.toStringAsFixed(2)} $unit',
 style: GoogleFonts.inter(
 fontSize: 12,
 color: isDark ? Colors.white : Colors.green.shade900,
 ),
 ),
 ),
 ),
 ],
 ),
 ],
 ),
 );
 }

 Widget _buildImprovementCard(MLMetricsImprovement improvement, bool isDark, bool isMobile) {
 return Container(
 padding: const EdgeInsets.all(20),
 decoration: BoxDecoration(
 gradient: LinearGradient(
 colors: improvement.improved
 ? [const Color(0xFF059669), const Color(0xFF10B981)]
 : [Colors.orange.shade600, Colors.orange.shade400],
 begin: Alignment.topLeft,
 end: Alignment.bottomRight,
 ),
 borderRadius: BorderRadius.circular(16),
 ),
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Row(
 children: [
 Icon(
 improvement.improved ? Icons.trending_up : Icons.trending_down,
 color: Colors.white,
 size: 32,
 ),
 const SizedBox(width: 12),
 Text(
 improvement.improved ? 'Modèle amlior' : 'Performance dgrade',
 style: GoogleFonts.inter(
 fontSize: 18,
 fontWeight: FontWeight.bold,
 color: Colors.white,
 ),
 ),
 ],
 ),
 const SizedBox(height: 16),
 Row(
 children: [
 Expanded(
 child: _buildImprovementMetric('MAE', improvement.maePct, improvement.improved),
 ),
 const SizedBox(width: 16),
 Expanded(
 child: _buildImprovementMetric('RMSE', improvement.rmsePct, improvement.improved),
 ),
 ],
 ),
 ],
 ),
 );
 }

 Widget _buildImprovementMetric(String label, double pct, bool improved) {
 return Container(
 padding: const EdgeInsets.all(12),
 decoration: BoxDecoration(
 color: Colors.white.withOpacity(0.2),
 borderRadius: BorderRadius.circular(8),
 ),
 child: Column(
 children: [
 Text(
 label,
 style: GoogleFonts.inter(
 fontSize: 12,
 color: Colors.white.withOpacity(0.9),
 ),
 ),
 const SizedBox(height: 4),
 Text(
 '${improved ? '+' : ''}${pct.toStringAsFixed(2)}%',
 style: GoogleFonts.inter(
 fontSize: 20,
 fontWeight: FontWeight.bold,
 color: Colors.white,
 ),
 ),
 ],
 ),
 );
 }

 Widget _buildRetrainButton(bool isDark, bool isMobile) {
 return SizedBox(
 width: double.infinity,
 child: ElevatedButton.icon(
 onPressed: _isRetraining ? null : _triggerRetrain,
 icon: _isRetraining
 ? const SizedBox(
 width: 20,
 height: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : const Icon(Icons.refresh),
 label: Text(
 _isRetraining ? 'Rentraînement en cours...' : 'Rentraîner le modèle',
 style: GoogleFonts.inter(
 fontSize: 16,
 fontWeight: FontWeight.w600,
 ),
 ),
 style: ElevatedButton.styleFrom(
 backgroundColor: const Color(0xFF2563EB),
 foregroundColor: Colors.white,
 padding: const EdgeInsets.symmetric(vertical: 16),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 ),
 );
 }

 bool _detectOverfitting(MLMetricsResponse metrics) {
 final maeRatio = metrics.train.mae > 0 ? metrics.test.mae / metrics.train.mae : 0;
 return maeRatio > 2.0; // Si test MAE > 2x train MAE
 }

 String _formatTimestamp(String timestamp) {
 try {
 final dateTime = DateTime.parse(timestamp);
 return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
 } catch (e) {
 return timestamp;
 }
 }
}

