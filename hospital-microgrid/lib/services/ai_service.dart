import 'dart:convert';
import 'package:hospital_microgrid/services/api_service.dart';
import 'package:hospital_microgrid/config/api_config.dart';
import 'package:http/http.dart' as http;

/// Service pour les fonCoûtionnalits AI Phase 2
class AiService {
 /// Rcupère les donnes d'anomalies pour un Ãé©tablissement
 static Future<AnomalyGraphResponse> getAnomalies(int establishmentId, {int days = 7}) async {
 try {
 final response = await ApiService.get('/establishments/$establishmentId/anomalies?days=$days');
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return AnomalyGraphResponse.fromJson(data);
 } else {
 throw AiException('Erreur: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }

 /// Rcupère les recommandations ML pour un Ãé©tablissement
 static Future<MlRecommendationsResponse> getMlRecommendations(int establishmentId) async {
 try {
 final response = await ApiService.get('/establishments/$establishmentId/recommendations/ml');
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return MlRecommendationsResponse.fromJson(data);
 } else {
 throw AiException('Erreur: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }

 /// Rcupère les prvisions long terme pour un Ãé©tablissement
 static Future<LongTermForecastResponse> getForecast(int establishmentId, {int horizonDays = 7}) async {
 try {
 final response = await ApiService.get('/establishments/$establishmentId/forecast?horizonDays=$horizonDays');
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return LongTermForecastResponse.fromJson(data);
 } else {
 throw AiException('Erreur: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }

 /// Rcupère les prvisions saisonnières pour un Ãé©tablissement
 static Future<LongTermForecastResponse> getSeasonalForecast(int establishmentId, {required String season, int? year}) async {
 try {
 final yearParam = year != null ? '&year=$year' : '';
 final response = await ApiService.get('/establishments/$establishmentId/forecast/seasonal?season=$season$yearParam');
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return LongTermForecastResponse.fromJson(data);
 } else {
 throw AiException('Erreur: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }

 /// Rcupère le cluster d'un Ã©tablissement
 static Future<ClusterResponse> getCluster(int establishmentId) async {
 try {
 final response = await ApiService.get('/establishments/$establishmentId/cluster');
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return ClusterResponse.fromJson(data);
 } else {
 throw AiException('Erreur: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }

 /// Lance une simulation avec détection d'anomalies
 static Future<SimulationResponse> simulate(int establishmentId, {
 required String startDate,
 required int days,
 required double batteryCapacityKwh,
 required double initialSocKwh,
 }) async {
 try {
 final response = await ApiService.post(
 '/establishments/$establishmentId/simulate',
 {
 'startDate': startDate,
 'days': days,
 'batterycapacityKwh': batteryCapacityKwh,
 'initialSocKwh': initialSocKwh,
 },
 );
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return SimulationResponse.fromJson(data);
 } else {
 throw AiException('Erreur: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }

 /// Rcupère les mtriques ML du modèle entraîn
 static Future<MLMetricsResponse> getMetrics() async {
 try {
 final url = Uri.parse('${ApiConfig.aiServiceUrl}/metrics');
 final response = await http.get(url);
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return MLMetricsResponse.fromJson(data);
 } else if (response.statusCode == 404) {
 throw AiException('Mtriques non disponibles. Le modèle n\'a pas encore t entraîn.');
 } else {
 throw AiException('Erreur: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }

 /// Dclenche le rentraînement du modèle ML
 static Future<RetrainResponse> retrain() async {
 try {
 final url = Uri.parse('${ApiConfig.aiServiceUrl}/retrain');
 final response = await http.post(url);
 
 if (response.statusCode == 200) {
 final data = jsonDecode(response.body);
 return RetrainResponse.fromJson(data);
 } else {
 throw AiException('Erreur lors du rentraînement: ${response.statusCode}');
 }
 } catch (e) {
 if (e is AiException) {
 rethrow;
 }
 throw AiException('Erreur rseau: $e');
 }
 }
}

// Exceptions
class AiException implements Exception {
 final String message;
 AiException(this.message);
 
 @override
 String toString() => message;
}

// Modèles de donnes

class AnomalyGraphResponse {
 final List<AnomalyDataPoint> anomalies;
 final AnomalyStatistics statistics;

 AnomalyGraphResponse({
 required this.anomalies,
 required this.statistics,
 });

 factory AnomalyGraphResponse.fromJson(Map<String, dynamic> json) {
 return AnomalyGraphResponse(
 anomalies: (json['anomalies'] as List<dynamic>?)
 ?.map((e) => AnomalyDataPoint.fromJson(e))
 .toList() ?? [],
 statistics: AnomalyStatistics.fromJson(json['statistics'] ?? {}),
 );
 }
}

class AnomalyDataPoint {
 final DateTime datetime;
 final bool isAnomaly;
 final String? anomalyType;
 final double anomalyScore;
 final String? recommendation;
 final double consumption;
 final double predictedConsumption;
 final double pvProduction;
 final double expectedPv;
 final double soc;

 AnomalyDataPoint({
 required this.datetime,
 required this.isAnomaly,
 this.anomalyType,
 required this.anomalyScore,
 this.recommendation,
 required this.consumption,
 required this.predictedConsumption,
 required this.pvProduction,
 required this.expectedPv,
 required this.soc,
 });

 factory AnomalyDataPoint.fromJson(Map<String, dynamic> json) {
 return AnomalyDataPoint(
 datetime: DateTime.parse(json['datetime']),
 isAnomaly: json['isAnomaly'] ?? false,
 anomalyType: json['anomalyType'],
 anomalyScore: (json['anomalyScore'] ?? 0.0).toDouble(),
 recommendation: json['recommendation'],
 consumption: (json['consumption'] ?? 0.0).toDouble(),
 predictedConsumption: (json['predictedConsumption'] ?? 0.0).toDouble(),
 pvProduction: (json['pvProduction'] ?? 0.0).toDouble(),
 expectedPv: (json['expectedPv'] ?? 0.0).toDouble(),
 soc: (json['soc'] ?? 0.0).toDouble(),
 );
 }
}

class AnomalyStatistics {
 final int totalAnomalies;
 final int highConsumptionAnomalies;
 final int lowConsumptionAnomalies;
 final int pvMalfunctionAnomalies;
 final int batteryLowAnomalies;
 final double averageAnomalyScore;
 final String mostCommonAnomalyType;

 AnomalyStatistics({
 required this.totalAnomalies,
 required this.highConsumptionAnomalies,
 required this.lowConsumptionAnomalies,
 required this.pvMalfunctionAnomalies,
 required this.batteryLowAnomalies,
 required this.averageAnomalyScore,
 required this.mostCommonAnomalyType,
 });

 factory AnomalyStatistics.fromJson(Map<String, dynamic> json) {
 return AnomalyStatistics(
 totalAnomalies: json['totalAnomalies'] ?? 0,
 highConsumptionAnomalies: json['highConsumptionAnomalies'] ?? 0,
 lowConsumptionAnomalies: json['lowConsumptionAnomalies'] ?? 0,
 pvMalfunctionAnomalies: json['pvMalfunctionAnomalies'] ?? 0,
 batteryLowAnomalies: json['batteryLowAnomalies'] ?? 0,
 averageAnomalyScore: (json['averageAnomalyScore'] ?? 0.0).toDouble(),
 mostCommonAnomalyType: json['mostCommonAnomalyType'] ?? 'none',
 );
 }
}

class MlRecommendationsResponse {
 final double predictedRoiYears;
 final List<Recommendation> recommendations;
 final String confidence;

 MlRecommendationsResponse({
 required this.predictedRoiYears,
 required this.recommendations,
 required this.confidence,
 });

 factory MlRecommendationsResponse.fromJson(Map<String, dynamic> json) {
 return MlRecommendationsResponse(
 predictedRoiYears: (json['predicted_roi_years'] ?? 10.0).toDouble(),
 recommendations: (json['recommendations'] as List<dynamic>?)
 ?.map((e) => Recommendation.fromJson(e))
 .toList() ?? [],
 confidence: json['confidence'] ?? 'low',
 );
 }
}

class Recommendation {
 final String type;
 final String message;
 final String? suggestion;

 Recommendation({
 required this.type,
 required this.message,
 this.suggestion,
 });

 factory Recommendation.fromJson(Map<String, dynamic> json) {
 return Recommendation(
 type: json['type'] ?? 'info',
 message: json['message'] ?? '',
 suggestion: json['suggestion'],
 );
 }
}

class LongTermForecastResponse {
 final List<ForecastDay> predictions;
 final List<ConfidenceInterval> confidenceIntervals;
 final String trend;
 final String method;

 LongTermForecastResponse({
 required this.predictions,
 required this.confidenceIntervals,
 required this.trend,
 required this.method,
 });

 factory LongTermForecastResponse.fromJson(Map<String, dynamic> json) {
 return LongTermForecastResponse(
 predictions: (json['predictions'] as List<dynamic>?)
 ?.map((e) => ForecastDay.fromJson(e))
 .toList() ?? [],
 confidenceIntervals: (json['confidenceIntervals'] as List<dynamic>?)
 ?.map((e) => ConfidenceInterval.fromJson(e))
 .toList() ?? [],
 trend: json['trend'] ?? 'stable',
 method: json['method'] ?? 'simple_average_trend',
 );
 }
}

class ForecastDay {
 final int day;
 final double predictedConsumption;
 final double predictedPvProduction;

 ForecastDay({
 required this.day,
 required this.predictedConsumption,
 required this.predictedPvProduction,
 });

 factory ForecastDay.fromJson(Map<String, dynamic> json) {
 return ForecastDay(
 day: json['day'] ?? 0,
 predictedConsumption: (json['predictedConsumption'] ?? 0.0).toDouble(),
 predictedPvProduction: (json['predictedPvProduction'] ?? 0.0).toDouble(),
 );
 }
}

class ConfidenceInterval {
 final int day;
 final double consumptionLower;
 final double consumptionUpper;
 final double pvLower;
 final double pvUpper;

 ConfidenceInterval({
 required this.day,
 required this.consumptionLower,
 required this.consumptionUpper,
 required this.pvLower,
 required this.pvUpper,
 });

 factory ConfidenceInterval.fromJson(Map<String, dynamic> json) {
 return ConfidenceInterval(
 day: json['day'] ?? 0,
 consumptionLower: (json['consumptionLower'] ?? 0.0).toDouble(),
 consumptionUpper: (json['consumptionUpper'] ?? 0.0).toDouble(),
 pvLower: (json['pvLower'] ?? 0.0).toDouble(),
 pvUpper: (json['pvUpper'] ?? 0.0).toDouble(),
 );
 }
}

class ClusterResponse {
 final int clusterId;
 final double distanceToCenter;
 final String message;

 ClusterResponse({
 required this.clusterId,
 required this.distanceToCenter,
 required this.message,
 });

 factory ClusterResponse.fromJson(Map<String, dynamic> json) {
 return ClusterResponse(
 clusterId: json['cluster_id'] ?? -1,
 distanceToCenter: (json['distance_to_center'] ?? 0.0).toDouble(),
 message: json['message'] ?? '',
 );
 }
}

class SimulationResponse {
 final List<SimulationStep> steps;
 final SimulationSummary summary;

 SimulationResponse({
 required this.steps,
 required this.summary,
 });

 factory SimulationResponse.fromJson(Map<String, dynamic> json) {
 return SimulationResponse(
 steps: (json['steps'] as List<dynamic>?)
 ?.map((e) => SimulationStep.fromJson(e))
 .toList() ?? [],
 summary: SimulationSummary.fromJson(json['summary'] ?? {}),
 );
 }
}

class SimulationStep {
 final DateTime datetime;
 final double predictedConsumption;
 final double pvProduction;
 final double socBattery;
 final double gridImport;
 final double batteryCharge;
 final double batteryDischarge;
 final String? note;
 final bool? hasAnomaly;
 final String? anomalyType;
 final double? anomalyScore;
 final String? anomalyRecommendation;

 SimulationStep({
 required this.datetime,
 required this.predictedConsumption,
 required this.pvProduction,
 required this.socBattery,
 required this.gridImport,
 required this.batteryCharge,
 required this.batteryDischarge,
 this.note,
 this.hasAnomaly,
 this.anomalyType,
 this.anomalyScore,
 this.anomalyRecommendation,
 });

 factory SimulationStep.fromJson(Map<String, dynamic> json) {
 return SimulationStep(
 datetime: DateTime.parse(json['datetime']),
 predictedConsumption: (json['predictedConsumption'] ?? 0.0).toDouble(),
 pvProduction: (json['pvProduction'] ?? 0.0).toDouble(),
 socBattery: (json['socBattery'] ?? 0.0).toDouble(),
 gridImport: (json['gridImport'] ?? 0.0).toDouble(),
 batteryCharge: (json['batteryCharge'] ?? 0.0).toDouble(),
 batteryDischarge: (json['batteryDischarge'] ?? 0.0).toDouble(),
 note: json['note'],
 hasAnomaly: json['hasAnomaly'],
 anomalyType: json['anomalyType'],
 anomalyScore: json['anomalyScore']?.toDouble(),
 anomalyRecommendation: json['anomalyRecommendation'],
 );
 }
}

class SimulationSummary {
 final double totalConsumption;
 final double totalPvProduction;
 final double totalGridImport;
 final double averageAutonomy;
 final double totalSavings;
 final double recommendedPvPower;
 final double recommendedBatteryCapacity;

 SimulationSummary({
 required this.totalConsumption,
 required this.totalPvProduction,
 required this.totalGridImport,
 required this.averageAutonomy,
 required this.totalSavings,
 required this.recommendedPvPower,
 required this.recommendedBatteryCapacity,
 });

 factory SimulationSummary.fromJson(Map<String, dynamic> json) {
 return SimulationSummary(
 totalConsumption: (json['totalConsumption'] ?? 0.0).toDouble(),
 totalPvProduction: (json['totalPvProduction'] ?? 0.0).toDouble(),
 totalGridImport: (json['totalGridImport'] ?? 0.0).toDouble(),
 averageAutonomy: (json['averageAutonomy'] ?? 0.0).toDouble(),
 totalSavings: (json['totalSavings'] ?? 0.0).toDouble(),
 recommendedPvPower: (json['recommendedPvPower'] ?? 0.0).toDouble(),
 recommendedBatteryCapacity: (json['recommendedBatteryCapacity'] ?? 0.0).toDouble(),
 );
 }
}

/// Mtriques ML du modèle entraîn
class MLMetricsResponse {
 final MLMetrics train;
 final MLMetrics test;
 final MLMetricsMeta meta;
 final MLMetricsImprovement? improvement;

 MLMetricsResponse({
 required this.train,
 required this.test,
 required this.meta,
 this.improvement,
 });

 factory MLMetricsResponse.fromJson(Map<String, dynamic> json) {
 return MLMetricsResponse(
 train: MLMetrics.fromJson(json['train'] ?? {}),
 test: MLMetrics.fromJson(json['test'] ?? {}),
 meta: MLMetricsMeta.fromJson(json['meta'] ?? {}),
 improvement: json['improvement'] != null
 ? MLMetricsImprovement.fromJson(json['improvement'])
 : null,
 );
 }
}

class MLMetrics {
 final double mae;
 final double rmse;
 final double mape;

 MLMetrics({
 required this.mae,
 required this.rmse,
 required this.mape,
 });

 factory MLMetrics.fromJson(Map<String, dynamic> json) {
 return MLMetrics(
 mae: (json['mae'] ?? 0.0).toDouble(),
 rmse: (json['rmse'] ?? 0.0).toDouble(),
 mape: (json['mape'] ?? 0.0).toDouble(),
 );
 }
}

class MLMetricsMeta {
 final String model;
 final String timestamp;
 final int features;
 final int trainRows;
 final int testRows;

 MLMetricsMeta({
 required this.model,
 required this.timestamp,
 required this.features,
 required this.trainRows,
 required this.testRows,
 });

 factory MLMetricsMeta.fromJson(Map<String, dynamic> json) {
 return MLMetricsMeta(
 model: json['model'] ?? 'Unknown',
 timestamp: json['timestamp'] ?? '',
 features: json['features'] ?? 0,
 trainRows: json['train_rows'] ?? 0,
 testRows: json['test_rows'] ?? 0,
 );
 }
}

class MLMetricsImprovement {
 final bool improved;
 final double maePct;
 final double rmsePct;

 MLMetricsImprovement({
 required this.improved,
 required this.maePct,
 required this.rmsePct,
 });

 factory MLMetricsImprovement.fromJson(Map<String, dynamic> json) {
 return MLMetricsImprovement(
 improved: json['improved'] ?? false,
 maePct: (json['mae_pct'] ?? 0.0).toDouble(),
 rmsePct: (json['rmse_pct'] ?? 0.0).toDouble(),
 );
 }
}

/// Rponse du rentraînement
class RetrainResponse {
 final String status;
 final Map<String, dynamic>? metrics;

 RetrainResponse({
 required this.status,
 this.metrics,
 });

 factory RetrainResponse.fromJson(Map<String, dynamic> json) {
 return RetrainResponse(
 status: json['status'] ?? 'unknown',
 metrics: json['metrics'],
 );
 }
}


