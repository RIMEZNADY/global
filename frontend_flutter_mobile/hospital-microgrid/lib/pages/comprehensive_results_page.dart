import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospital_microgrid/services/establishment_service.dart';
import 'package:hospital_microgrid/services/ai_service.dart';
import 'package:hospital_microgrid/main.dart';
import 'package:hospital_microgrid/providers/theme_provider.dart';
import 'package:hospital_microgrid/services/pdf_export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class ComprehensiveResultsPage extends StatefulWidget {
  final int establishmentId;
  final ThemeProvider themeProvider;

  const ComprehensiveResultsPage({
    super.key,
    required this.establishmentId,
    required this.themeProvider,
  });

  @override
  State<ComprehensiveResultsPage> createState() => _ComprehensiveResultsPageState();
}

class _ComprehensiveResultsPageState extends State<ComprehensiveResultsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _comprehensiveResults;
  RecommendationsResponse? _recommendations;
  LongTermForecastResponse? _forecast;
  MlRecommendationsResponse? _mlRecommendations;
  AnomalyGraphResponse? _anomalies;
  EstablishmentResponse? _establishment;
  
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    if (_autoRefreshEnabled) {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted && _autoRefreshEnabled) {
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les données essentielles d'abord
      final essentialResults = await Future.wait([
        EstablishmentService.getComprehensiveResults(widget.establishmentId),
        EstablishmentService.getRecommendations(widget.establishmentId),
        EstablishmentService.getEstablishment(widget.establishmentId),
      ]);

      setState(() {
        _comprehensiveResults = essentialResults[0] as Map<String, dynamic>?;
        _recommendations = essentialResults[1] as RecommendationsResponse?;
        _establishment = essentialResults[2] as EstablishmentResponse?;
        _isLoading = false;
      });

      // Charger les données AI de manière asynchrone avec timeout
      _loadAIData();
    } catch (e) {
      setState(() {
        _error = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAIData() async {
    try {
      // Charger les données AI avec timeout individuel pour éviter les blocages
      final aiResults = await Future.wait([
        AiService.getForecast(widget.establishmentId, horizonDays: 7)
            .timeout(const Duration(seconds: 10))
            .catchError((e) {
              print('⚠️ Erreur lors du chargement des prévisions: $e');
              return LongTermForecastResponse(
                predictions: [],
                confidenceIntervals: [],
                trend: 'stable',
                method: 'none',
              );
            }),
        AiService.getMlRecommendations(widget.establishmentId)
            .timeout(const Duration(seconds: 10))
            .catchError((e) {
              print('⚠️ Erreur lors du chargement des recommandations ML: $e');
              return MlRecommendationsResponse(
                predictedRoiYears: 0,
                recommendations: [],
                confidence: 'low',
              );
            }),
        AiService.getAnomalies(widget.establishmentId, days: 7)
            .timeout(const Duration(seconds: 10))
            .catchError((e) {
              print('⚠️ Erreur lors du chargement des anomalies: $e');
              return AnomalyGraphResponse(
                anomalies: [],
                statistics: AnomalyStatistics(
                  totalAnomalies: 0,
                  highConsumptionAnomalies: 0,
                  lowConsumptionAnomalies: 0,
                  pvMalfunctionAnomalies: 0,
                  batteryLowAnomalies: 0,
                  averageAnomalyScore: 0.0,
                  mostCommonAnomalyType: 'none',
                ),
              );
            }),
      ]);

      if (mounted) {
        setState(() {
          _forecast = aiResults[0] as LongTermForecastResponse?;
          _mlRecommendations = aiResults[1] as MlRecommendationsResponse?;
          _anomalies = aiResults[2] as AnomalyGraphResponse?;
        });
      }
    } catch (e) {
      print('⚠️ Erreur lors du chargement des données AI: $e');
      // Ne pas bloquer l'application si les données AI échouent
      if (mounted) {
        setState(() {
          _forecast ??= LongTermForecastResponse(
            predictions: [],
            confidenceIntervals: [],
            trend: 'stable',
            method: 'none',
          );
          _mlRecommendations ??= MlRecommendationsResponse(
            predictedRoiYears: 0,
            recommendations: [],
            confidence: 'low',
          );
          _anomalies ??= AnomalyGraphResponse(
            anomalies: [],
            statistics: AnomalyStatistics(
              totalAnomalies: 0,
              highConsumptionAnomalies: 0,
              lowConsumptionAnomalies: 0,
              pvMalfunctionAnomalies: 0,
              batteryLowAnomalies: 0,
              averageAnomalyScore: 0.0,
              mostCommonAnomalyType: 'none',
            ),
          );
        });
      }
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });
    if (_autoRefreshEnabled) {
      _startAutoRefresh();
    } else {
      _autoRefreshTimer?.cancel();
    }
  }

  void _goToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          themeProvider: widget.themeProvider,
          initialIndex: 0,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _exportPdf() async {
    if (_comprehensiveResults == null || _recommendations == null || _establishment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données non disponibles pour l\'export')),
      );
      return;
    }

    try {
      await PdfExportService.exportResultsToPdf(
        establishment: _establishment!,
        recommendations: _recommendations!,
        comprehensiveResults: _comprehensiveResults!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exporté avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export: $e')),
        );
      }
    }
  }

  Future<void> _shareResults() async {
    if (_comprehensiveResults == null) return;
    
    final globalScore = _comprehensiveResults!['globalScore']?['score'] ?? 0;
    final autonomy = _comprehensiveResults!['environmental']?['autonomyPercentage'] ?? 0;
    final annualSavings = _comprehensiveResults!['financial']?['annualSavings'] ?? 0;
    
    final text = '''
Résultats Microgrid Solaire

Score Global: ${globalScore.toStringAsFixed(1)}/100
Autonomie: ${autonomy.toStringAsFixed(1)}%
Économies Annuelles: ${annualSavings.toStringAsFixed(0)} DH/an
''';
    
    await Share.share(text);
  }

  // Détecte si c'est un établissement NEW (projet futur) ou EXISTANT (avec consommation réelle)
  bool get _isNewEstablishment {
    return _establishment?.monthlyConsumptionKwh == null && 
           _establishment?.projectBudgetDh != null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Résultats Complets')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Chargement des résultats...',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.7) : MedicalSolarColors.softGrey.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _comprehensiveResults == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Résultats Complets')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: MedicalSolarColors.error.withOpacity(0.7)),
                const SizedBox(height: 16),
                Text(_error ?? 'Données non disponibles', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats Complets'),
        actions: [
          IconButton(
            icon: Icon(_autoRefreshEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoRefresh,
            tooltip: _autoRefreshEnabled ? 'Pause auto-refresh' : 'Reprendre auto-refresh',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportPdf();
                  break;
                case 'share':
                  _shareResults();
                  break;
                case 'dashboard':
                  _goToDashboard();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Exporter PDF')),
              const PopupMenuItem(value: 'share', child: Text('Partager')),
              const PopupMenuItem(value: 'dashboard', child: Text('Retour Dashboard')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          indicatorColor: MedicalSolarColors.medicalBlue,
          indicatorWeight: 3,
          labelColor: MedicalSolarColors.medicalBlue,
          unselectedLabelColor: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.6),
          labelStyle: GoogleFonts.inter(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w500),
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard_rounded, size: 20),
              text: isMobile ? 'Vue d\'ensemble' : 'Vue d\'ensemble',
            ),
            Tab(
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
              text: isMobile ? 'Financier' : 'Financier',
            ),
            Tab(
              icon: const Icon(Icons.eco_rounded, size: 20),
              text: isMobile ? 'Environnemental' : 'Environnemental',
            ),
            Tab(
              icon: const Icon(Icons.build_rounded, size: 20),
              text: isMobile ? 'Technique' : 'Technique',
            ),
            Tab(
              icon: const Icon(Icons.compare_arrows_rounded, size: 20),
              text: isMobile ? 'Comparatif' : 'Comparatif',
            ),
            Tab(
              icon: const Icon(Icons.warning_rounded, size: 20),
              text: isMobile ? 'Alertes' : 'Alertes',
            ),
            Tab(
              icon: const Icon(Icons.psychology_rounded, size: 20),
              text: isMobile ? 'IA' : 'Prédictions IA',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(isDark, isMobile),
          _buildFinancialTab(isDark, isMobile),
          _buildEnvironmentalTab(isDark, isMobile),
          _buildTechnicalTab(isDark, isMobile),
          _buildComparisonTab(isDark, isMobile),
          _buildAlertsTab(isDark, isMobile),
          _buildAIPredictionsTab(isDark, isMobile),
        ],
      ),
    );
  }

  // ONGLET 1: VUE D'ENSEMBLE
  Widget _buildOverviewTab(bool isDark, bool isMobile) {
    final globalScore = _comprehensiveResults!['globalScore'] as Map<String, dynamic>?;
    final financial = _comprehensiveResults!['financial'] as Map<String, dynamic>?;
    final beforeAfter = _comprehensiveResults!['beforeAfter'] as Map<String, dynamic>?;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Score Global
          if (globalScore != null) _buildGlobalScoreCard(globalScore, isDark),
          const SizedBox(height: 24),
          // Métriques principales
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Autonomie Énergétique',
                  '${(globalScore?['autonomyScore'] ?? 0).toStringAsFixed(1)}%',
                  Icons.battery_charging_full_rounded,
                  MedicalSolarColors.solarGreen,
                  isDark,
                  tooltip: 'Pourcentage d\'énergie produite par le système solaire par rapport à la consommation totale. Plus ce pourcentage est élevé, plus vous êtes indépendant du réseau.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Économies Annuelles',
                  '${(financial?['annualSavings'] ?? 0).toStringAsFixed(0)} DH/an',
                  Icons.savings_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                  tooltip: 'Montant économisé chaque année grâce à la production solaire et à la réduction de la facture d\'électricité.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'ROI',
                  '${(financial?['roi'] ?? 0).toStringAsFixed(1)} ans',
                  Icons.trending_up_rounded,
                  MedicalSolarColors.solarYellow,
                  isDark,
                  tooltip: 'Retour sur Investissement : nombre d\'années nécessaires pour récupérer l\'investissement initial grâce aux économies réalisées.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Score Global',
                  '${(globalScore?['score'] ?? 0).toStringAsFixed(1)}/100',
                  Icons.star_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                  tooltip: 'Score composite évaluant la qualité globale du projet (Autonomie 40%, Économique 30%, Résilience 20%, Environnemental 10%).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Scores par catégorie
          Text(
            'Scores par Catégorie',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
            ),
          ),
          const SizedBox(height: 16),
          if (globalScore != null) _buildCategoryScores(globalScore, isDark),
          const SizedBox(height: 24),
          // Section Amélioration (si PV existant)
          if (beforeAfter != null && beforeAfter['hasExistingPv'] == true) ...[
            _buildImprovementCard(beforeAfter, isDark),
            const SizedBox(height: 24),
          ],
          // Graphique Comparatif
          if (beforeAfter != null) _buildBeforeAfterChart(beforeAfter, isDark, isMobile, isNew: _isNewEstablishment),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGlobalScoreCard(Map<String, dynamic> globalScore, bool isDark) {
    final score = (globalScore['score'] ?? 0).toDouble();
    final color = score >= 80
        ? MedicalSolarColors.solarGreen
        : score >= 60
            ? MedicalSolarColors.medicalBlue
            : score >= 40
                ? MedicalSolarColors.solarYellow
                : MedicalSolarColors.error;

    return Tooltip(
      message: 'Score composite évaluant la qualité globale du projet de microgrid. Basé sur 4 catégories : Autonomie (40%), Économique (30%), Résilience (20%), Environnemental (10%).',
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.25),
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.4), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, size: 56, color: Color(0xFFFFD700)),
            ),
            const SizedBox(height: 20),
            Text(
              'Score Global',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '/ 100',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                score >= 80 ? 'Excellent' : score >= 60 ? 'Bon' : score >= 40 ? 'Moyen' : 'À améliorer',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDark, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? title,
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryScores(Map<String, dynamic> globalScore, bool isDark) {
    final categories = [
      {
        'name': 'Autonomie',
        'score': globalScore['autonomyScore'] ?? 0,
        'weight': 40,
        'color': MedicalSolarColors.solarGreen,
        'icon': Icons.battery_charging_full_rounded,
        'tooltip': 'Capacité du système à produire suffisamment d\'énergie pour couvrir les besoins. Poids : 40% du score global.',
      },
      {
        'name': 'Économique',
        'score': globalScore['economicScore'] ?? 0,
        'weight': 30,
        'color': MedicalSolarColors.medicalBlue,
        'icon': Icons.account_balance_wallet_rounded,
        'tooltip': 'Rentabilité financière du projet (ROI, économies, NPV). Poids : 30% du score global.',
      },
      {
        'name': 'Résilience',
        'score': globalScore['resilienceScore'] ?? 0,
        'weight': 20,
        'color': MedicalSolarColors.solarYellow,
        'icon': Icons.shield_rounded,
        'tooltip': 'Capacité du système à maintenir l\'alimentation en cas de panne réseau. Poids : 20% du score global.',
      },
      {
        'name': 'Environnemental',
        'score': globalScore['environmentalScore'] ?? 0,
        'weight': 10,
        'color': MedicalSolarColors.solarGreen,
        'icon': Icons.eco_rounded,
        'tooltip': 'Impact positif sur l\'environnement (CO₂ évité, équivalents arbres/voitures). Poids : 10% du score global.',
      },
    ];

    return Column(
      children: categories.map((cat) {
        final score = (cat['score'] as num).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Tooltip(
            message: cat['tooltip'] as String,
            preferBelow: false,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    (cat['color'] as Color).withOpacity(isDark ? 0.15 : 0.08),
                    (cat['color'] as Color).withOpacity(isDark ? 0.08 : 0.04),
                  ],
                ),
                color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (cat['color'] as Color).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${cat['weight']}% du score global',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: score / 100,
                            minHeight: 8,
                            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(cat['color'] as Color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    score.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cat['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImprovementCard(Map<String, dynamic> beforeAfter, bool isDark) {
    final beforeAutonomy = (beforeAfter['beforeAutonomy'] ?? 0).toDouble();
    final afterAutonomy = (beforeAfter['afterAutonomy'] ?? 0).toDouble();
    final autonomyGain = (beforeAfter['autonomyGain'] ?? 0).toDouble();
    final annualSavingsGain = (beforeAfter['annualSavingsGain'] ?? 0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MedicalSolarColors.solarGreen.withOpacity(0.2),
            MedicalSolarColors.medicalBlue.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MedicalSolarColors.solarGreen.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: MedicalSolarColors.solarGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MedicalSolarColors.solarGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up_rounded, color: MedicalSolarColors.solarGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amélioration Réelle',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gain par rapport à votre installation actuelle',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildImprovementMetric(
                  'Autonomie',
                  '${beforeAutonomy.toStringAsFixed(1)}%',
                  '${afterAutonomy.toStringAsFixed(1)}%',
                  '+${autonomyGain.toStringAsFixed(1)}%',
                  Icons.battery_charging_full_rounded,
                  MedicalSolarColors.solarGreen,
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImprovementMetric(
                  'Économies annuelles',
                  '${((beforeAfter['beforeAnnualBill'] ?? 0) - (beforeAfter['afterAnnualBill'] ?? 0) - annualSavingsGain).toStringAsFixed(0)} DH',
                  '${((beforeAfter['beforeAnnualBill'] ?? 0) - (beforeAfter['afterAnnualBill'] ?? 0)).toStringAsFixed(0)} DH',
                  '+${annualSavingsGain.toStringAsFixed(0)} DH',
                  Icons.savings_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementMetric(
    String label,
    String current,
    String projected,
    String gain,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface.withOpacity(0.5) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actuel',
                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : MedicalSolarColors.softGrey.withOpacity(0.6)),
                  ),
                  Text(
                    current,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : MedicalSolarColors.softGrey),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: color),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Projeté',
                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : MedicalSolarColors.softGrey.withOpacity(0.6)),
                  ),
                  Text(
                    projected,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  gain,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterChart(Map<String, dynamic> beforeAfter, bool isDark, bool isMobile, {bool isNew = false}) {
    final beforeMonthlyBill = (beforeAfter['beforeMonthlyBill'] ?? 0).toDouble();
    final afterMonthlyBill = (beforeAfter['afterMonthlyBill'] ?? 0).toDouble();

    final groups = [
      BarChartGroupData(x: 0, barRods: [
        BarChartRodData(toY: beforeMonthlyBill, color: MedicalSolarColors.error.withOpacity(0.7)),
        BarChartRodData(toY: afterMonthlyBill, color: MedicalSolarColors.solarGreen),
      ]),
    ];

    final title = isNew ? 'Comparaison Projeté' : 'Comparaison Avant/Après';
    final tooltipMessage = isNew 
        ? 'Comparaison de la facture mensuelle projetée sans microgrid (réseau uniquement) vs avec microgrid solaire. La différence représente les économies mensuelles estimées.'
        : 'Comparaison de la facture mensuelle avant et après l\'installation du microgrid solaire. La différence représente vos économies mensuelles.';
    
    return Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? MedicalSolarColors.darkSurface : Colors.white,
              isDark ? MedicalSolarColors.darkSurface.withOpacity(0.8) : Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MedicalSolarColors.medicalBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isNew ? Icons.insights_rounded : Icons.compare_arrows_rounded,
                    color: MedicalSolarColors.medicalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isNew)
                        Text(
                          'Projection avec et sans microgrid',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: isMobile ? 280 : 320,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Facture Mensuelle',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1000,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  isNew ? 'Sans microgrid' : 'Avant',
                  Colors.red.shade400,
                  isDark,
                ),
                const SizedBox(width: 24),
                _buildLegendItem(
                  isNew ? 'Avec microgrid' : 'Après',
                  MedicalSolarColors.solarGreen,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // ONGLET 2: FINANCIER
  Widget _buildFinancialTab(bool isDark, bool isMobile) {
    final financial = _comprehensiveResults!['financial'] as Map<String, dynamic>?;
    if (financial == null) {
      return const Center(child: Text('Données financières non disponibles'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Coût d\'Installation',
                  '${(financial['installationCost'] ?? 0).toStringAsFixed(0)} DH',
                  Icons.construction_rounded,
                  Colors.red.shade400,
                  isDark,
                  tooltip: 'Coût total d\'installation du système microgrid incluant les panneaux solaires, batteries, onduleurs et installation.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Économies Annuelles',
                  '${(financial['annualSavings'] ?? 0).toStringAsFixed(0)} DH/an',
                  Icons.savings_rounded,
                  MedicalSolarColors.solarGreen,
                  isDark,
                  tooltip: _isNewEstablishment
                      ? 'Montant économisé estimé chaque année grâce à la production solaire projetée et à la réduction de la facture d\'électricité.'
                      : 'Montant économisé chaque année grâce à la production solaire et à la réduction de la facture d\'électricité.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'ROI',
                  '${(financial['roi'] ?? 0).toStringAsFixed(1)} ans',
                  Icons.trending_up_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                  tooltip: 'Retour sur Investissement : nombre d\'années nécessaires pour récupérer l\'investissement initial grâce aux économies réalisées.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'NPV (20 ans)',
                  '${(financial['npv'] ?? 0).toStringAsFixed(0)} DH',
                  Icons.account_balance_wallet_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                  tooltip: 'Valeur Actuelle Nette sur 20 ans : différence entre la valeur actuelle des économies futures et l\'investissement initial.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'IRR',
            '${(financial['irr'] ?? 0).toStringAsFixed(1)}%',
            Icons.show_chart_rounded,
            const Color(0xFFFFD700),
            isDark,
            tooltip: 'Taux de Rendement Interne : taux d\'actualisation qui rend la valeur actuelle nette égale à zéro. Plus élevé = meilleur investissement.',
          ),
          const SizedBox(height: 24),
          _buildFinancialEvolutionChart(financial, isDark, isMobile),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFinancialEvolutionChart(Map<String, dynamic> financial, bool isDark, bool isMobile) {
    final annualSavings = (financial['annualSavings'] ?? 0).toDouble();
    final spots = List.generate(20, (index) {
      return FlSpot((index + 1).toDouble(), annualSavings * (index + 1));
    });

    return Tooltip(
      message: 'Évolution des économies cumulées sur 20 ans. Cette courbe montre comment vos économies s\'accumulent année après année.',
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? MedicalSolarColors.darkSurface : Colors.white,
              isDark ? MedicalSolarColors.darkSurface.withOpacity(0.8) : Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.15) : Colors.grey.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MedicalSolarColors.solarGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: MedicalSolarColors.solarGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Évolution Financière (20 ans)',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: isMobile ? 280 : 320,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [MedicalSolarColors.medicalBlue, MedicalSolarColors.solarGreen],
                      ),
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            MedicalSolarColors.medicalBlue.withOpacity(0.3),
                            MedicalSolarColors.solarGreen.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ONGLET 3: ENVIRONNEMENTAL
  Widget _buildEnvironmentalTab(bool isDark, bool isMobile) {
    final environmental = _comprehensiveResults!['environmental'] as Map<String, dynamic>?;
    if (environmental == null) {
      return const Center(child: Text('Données environnementales non disponibles'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Production PV Annuelle',
                  '${(environmental['annualPvProduction'] ?? 0).toStringAsFixed(0)} kWh/an',
                  Icons.solar_power_rounded,
                  MedicalSolarColors.solarYellow,
                  isDark,
                  tooltip: 'Quantité totale d\'électricité produite par les panneaux solaires sur une année complète.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'CO₂ Évité',
                  '${(environmental['co2Avoided'] ?? 0).toStringAsFixed(2)} t/an',
                  Icons.eco_rounded,
                  MedicalSolarColors.solarGreen,
                  isDark,
                  tooltip: 'Quantité de dioxyde de carbone évitée chaque année grâce à la production d\'énergie solaire (vs énergie fossile).',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Équivalent Arbres',
                  '${(environmental['equivalentTrees'] ?? 0).toStringAsFixed(0)} arbres',
                  Icons.park_rounded,
                  MedicalSolarColors.solarGreen,
                  isDark,
                  tooltip: 'Nombre d\'arbres qu\'il faudrait planter pour absorber la même quantité de CO₂ que celle évitée par votre installation.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Équivalent Voitures',
                  '${(environmental['equivalentCars'] ?? 0).toStringAsFixed(0)} voitures',
                  Icons.directions_car_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                  tooltip: 'Nombre de voitures qu\'il faudrait retirer de la route pour avoir le même impact environnemental positif.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ONGLET 4: TECHNIQUE
  Widget _buildTechnicalTab(bool isDark, bool isMobile) {
    if (_recommendations == null) {
      return const Center(child: Text('Recommandations techniques non disponibles'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Puissance PV Recommandée',
                  '${_recommendations!.recommendedPvPower.toStringAsFixed(2)} kW',
                  Icons.solar_power_rounded,
                  MedicalSolarColors.solarYellow,
                  isDark,
                  tooltip: 'Puissance crête recommandée pour les panneaux solaires, calculée pour optimiser la production selon votre consommation.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Capacité Batterie Recommandée',
                  '${_recommendations!.recommendedBatteryCapacity.toStringAsFixed(2)} kWh',
                  Icons.battery_charging_full_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                  tooltip: 'Capacité de stockage recommandée pour les batteries, permettant d\'assurer l\'autonomie énergétique souhaitée.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Surface PV Nécessaire',
                  '${_recommendations!.recommendedPvSurface.toStringAsFixed(0)} m²',
                  Icons.grid_view_rounded,
                  MedicalSolarColors.solarGreen,
                  isDark,
                  tooltip: 'Surface totale nécessaire pour installer les panneaux solaires recommandés, en tenant compte de l\'orientation et de l\'inclinaison optimale.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Autonomie Énergétique',
                  '${_recommendations!.energyAutonomy.toStringAsFixed(1)}%',
                  Icons.battery_charging_full_rounded,
                  MedicalSolarColors.medicalBlue,
                  isDark,
                  tooltip: 'Pourcentage d\'énergie produite par le système solaire par rapport à la consommation totale de l\'établissement.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ONGLET 5: COMPARATIF
  Widget _buildComparisonTab(bool isDark, bool isMobile) {
    final beforeAfter = _comprehensiveResults!['beforeAfter'] as Map<String, dynamic>?;
    if (beforeAfter == null) {
      return const Center(child: Text('Données comparatives non disponibles'));
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildComparisonTable(beforeAfter, isDark, isNew: _isNewEstablishment),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MedicalSolarColors.medicalBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, color: MedicalSolarColors.medicalBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scénarios What-If',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Simulez différents scénarios pour voir l\'impact',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildWhatIfScenarios(isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(Map<String, dynamic> beforeAfter, bool isDark, {bool isNew = false}) {
    final beforeLabel = isNew ? 'Sans microgrid' : 'Avant';
    final afterLabel = isNew ? 'Avec microgrid' : 'Après';
    final hasExistingPv = beforeAfter['hasExistingPv'] == true;
    final beforeAutonomy = (beforeAfter['beforeAutonomy'] ?? 0).toDouble();
    final afterAutonomy = (beforeAfter['afterAutonomy'] ?? 0).toDouble();
    final autonomyGain = (beforeAfter['autonomyGain'] ?? 0).toDouble();
    
    final rows = [
      [
        'Consommation réseau',
        '${(beforeAfter['beforeGridConsumption'] ?? beforeAfter['beforeMonthlyConsumption'] ?? 0).toStringAsFixed(0)} kWh',
        '${(beforeAfter['afterGridConsumption'] ?? beforeAfter['afterMonthlyConsumption'] ?? 0).toStringAsFixed(0)} kWh',
      ],
      [
        'Facture mensuelle',
        '${(beforeAfter['beforeMonthlyBill'] ?? 0).toStringAsFixed(0)} DH',
        '${(beforeAfter['afterMonthlyBill'] ?? 0).toStringAsFixed(0)} DH',
      ],
      [
        'Facture annuelle',
        '${(beforeAfter['beforeAnnualBill'] ?? 0).toStringAsFixed(0)} DH',
        '${(beforeAfter['afterAnnualBill'] ?? 0).toStringAsFixed(0)} DH',
      ],
      [
        'Autonomie énergétique',
        hasExistingPv 
            ? '${beforeAutonomy.toStringAsFixed(1)}% (actuelle)'
            : (isNew ? '0% (réseau uniquement)' : '0%'),
        '${afterAutonomy.toStringAsFixed(1)}%',
      ],
    ];
    
    // Ajouter une ligne de gain si PV existant
    if (hasExistingPv && autonomyGain > 0) {
      rows.add([
        'Gain d\'autonomie',
        '',
        '+${autonomyGain.toStringAsFixed(1)}%',
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: MedicalSolarColors.medicalBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            children: [
              _buildTableCell('Métrique', isDark, isHeader: true),
              _buildTableCell(beforeLabel, isDark, isHeader: true),
              _buildTableCell(afterLabel, isDark, isHeader: true),
            ],
          ),
          ...rows.map((row) {
            final isGainRow = row[0] == 'Gain d\'autonomie';
            
            return TableRow(
              decoration: isGainRow ? BoxDecoration(
                color: MedicalSolarColors.solarGreen.withOpacity(isDark ? 0.15 : 0.08),
              ) : null,
              children: [
                _buildTableCell(row[0], isDark, isGain: isGainRow),
                _buildTableCell(row[1], isDark, isGain: isGainRow),
                _buildTableCell(row[2], isDark, isGain: isGainRow),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, bool isDark, {bool isHeader = false, bool isGain = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (isGain) ...[
            const Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: MedicalSolarColors.solarGreen,
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: isHeader ? 14 : (isGain ? 13 : 13),
                fontWeight: isHeader ? FontWeight.bold : (isGain ? FontWeight.w600 : FontWeight.normal),
                color: isGain 
                    ? MedicalSolarColors.solarGreen
                    : (isDark ? Colors.white : MedicalSolarColors.softGrey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIfScenarios(bool isDark) {
    return Column(
      children: [
        _buildScenarioCard(
          'Augmentation de 20% de la consommation',
          'Simulez l\'impact si votre consommation augmente de 20%',
          Icons.trending_up_rounded,
          () => _runWhatIfScenario('consumption', 1.2),
          isDark,
          color: Colors.orange.shade400,
        ),
        const SizedBox(height: 14),
        _buildScenarioCard(
          'Ajout de 100 m² de panneaux solaires',
          'Voyez les bénéfices d\'augmenter la surface PV de 100 m²',
          Icons.add_circle_rounded,
          () => _runWhatIfScenario('surface', 100),
          isDark,
          color: const Color(0xFFFFD700),
        ),
        const SizedBox(height: 14),
        _buildScenarioCard(
          'Doublement de la capacité batterie',
          'Évaluez l\'impact d\'une batterie deux fois plus grande',
          Icons.battery_charging_full_rounded,
          () => _runWhatIfScenario('battery', 2.0),
          isDark,
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 14),
        _buildScenarioCard(
          'Hausse de 20% du prix de l\'électricité',
          'Anticipez l\'impact d\'une augmentation des tarifs',
          Icons.price_change_rounded,
          () => _runWhatIfScenario('price', 1.2),
          isDark,
          color: Colors.red.shade400,
        ),
      ],
    );
  }

  Widget _buildScenarioCard(String title, String description, IconData icon, VoidCallback onTap, bool isDark, {Color? color}) {
    final scenarioColor = color ?? MedicalSolarColors.medicalBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: MedicalSolarColors.medicalBlue.withOpacity(0.2),
        highlightColor: MedicalSolarColors.medicalBlue.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                scenarioColor.withOpacity(isDark ? 0.15 : 0.08),
                scenarioColor.withOpacity(isDark ? 0.08 : 0.04),
              ],
            ),
            color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scenarioColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: scenarioColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scenarioColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scenarioColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 20, color: scenarioColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runWhatIfScenario(String type, double value) async {
    if (!mounted || _comprehensiveResults == null || _establishment == null) return;
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // Calculer les résultats du scénario
      final scenarioResults = _calculateScenarioResults(type, value);
      
      if (!mounted) return;
      Navigator.pop(context); // Fermer le loading
      
      // Afficher le dialog avec les résultats
      _showScenarioResultsDialog(type, value, scenarioResults);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du calcul du scénario: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _calculateScenarioResults(String type, double value) {
    final currentResults = _comprehensiveResults!;
    final establishment = _establishment!;
    final beforeAfter = currentResults['beforeAfter'] as Map<String, dynamic>?;
    final financial = currentResults['financial'] as Map<String, dynamic>?;
    final recommendations = _recommendations;
    
    // Valeurs actuelles
    final currentAutonomy = (currentResults['autonomy'] ?? 0).toDouble();
    final currentAnnualSavings = (financial?['annualSavings'] ?? 0).toDouble();
    final currentRoi = (financial?['roi'] ?? 0).toDouble();
    final currentMonthlyBill = (beforeAfter?['afterMonthlyBill'] ?? 0).toDouble();
    final currentAnnualBill = (beforeAfter?['afterAnnualBill'] ?? 0).toDouble();
    final currentPvPower = (recommendations?.recommendedPvPower ?? 0).toDouble();
    final currentBatteryCapacity = (recommendations?.recommendedBatteryCapacity ?? 0).toDouble();
    final currentMonthlyConsumption = establishment.monthlyConsumptionKwh ?? 50000.0;
    const currentElectricityPrice = 1.2; // DH/kWh
    
    // Calculer les nouvelles valeurs selon le type de scénario
    double newAutonomy = currentAutonomy;
    double newAnnualSavings = currentAnnualSavings;
    double newRoi = currentRoi;
    double newMonthlyBill = currentMonthlyBill;
    double newAnnualBill = currentAnnualBill;
    double newPvPower = currentPvPower;
    double newBatteryCapacity = currentBatteryCapacity;
    double newMonthlyConsumption = currentMonthlyConsumption;
    double newElectricityPrice = currentElectricityPrice;
    String scenarioDescription = '';
    
    switch (type) {
      case 'consumption':
        // Augmentation de la consommation
        newMonthlyConsumption = currentMonthlyConsumption * value;
        scenarioDescription = 'Consommation: ${currentMonthlyConsumption.toStringAsFixed(0)} → ${newMonthlyConsumption.toStringAsFixed(0)} kWh/mois';
        // Recalculer l'autonomie (diminue car consommation augmente)
        final pvSurface = (recommendations?.recommendedPvSurface ?? 0);
        if (pvSurface > 0 && establishment.irradiationClass != null) {
          // Utiliser une approximation simple : autonomie inversement proportionnelle à la consommation
          newAutonomy = (currentAutonomy * currentMonthlyConsumption / newMonthlyConsumption).clamp(0.0, 100.0);
        }
        break;
        
      case 'surface':
        // Ajout de surface PV
        final currentPvSurface = (recommendations?.recommendedPvSurface ?? 0);
        final newPvSurface = currentPvSurface + value;
        newPvPower = newPvSurface / 5.0; // 1 kWc = 5 m²
        scenarioDescription = 'Surface PV: ${currentPvSurface.toStringAsFixed(0)} → ${newPvSurface.toStringAsFixed(0)} m²';
        // Recalculer l'autonomie (augmente car plus de PV)
        if (newPvSurface > 0 && establishment.irradiationClass != null) {
          // Approximation : autonomie proportionnelle à la surface
          newAutonomy = (currentAutonomy * newPvSurface / currentPvSurface).clamp(0.0, 100.0);
        }
        break;
        
      case 'battery':
        // Doublement de la capacité batterie
        newBatteryCapacity = currentBatteryCapacity * value;
        scenarioDescription = 'Capacité batterie: ${currentBatteryCapacity.toStringAsFixed(0)} → ${newBatteryCapacity.toStringAsFixed(0)} kWh';
        // La batterie n'affecte pas directement l'autonomie énergétique (c'est le PV qui produit)
        // Mais elle améliore la résilience et peut légèrement améliorer l'utilisation du PV
        newAutonomy = currentAutonomy * 1.05; // Légère amélioration (5%)
        break;
        
      case 'price':
        // Hausse du prix de l'électricité
        newElectricityPrice = currentElectricityPrice * value;
        scenarioDescription = 'Prix électricité: ${currentElectricityPrice.toStringAsFixed(2)} → ${newElectricityPrice.toStringAsFixed(2)} DH/kWh';
        // L'autonomie ne change pas, mais les économies augmentent
        newAutonomy = currentAutonomy;
        break;
    }
    
    // Recalculer les factures et économies
    final gridConsumption = newMonthlyConsumption * (1 - newAutonomy / 100.0);
    newMonthlyBill = gridConsumption * newElectricityPrice;
    newAnnualBill = newMonthlyBill * 12;
    
    // Recalculer les économies annuelles
    final pvProduction = newMonthlyConsumption * (newAutonomy / 100.0);
    newAnnualSavings = pvProduction * 12 * newElectricityPrice;
    
    // Recalculer le ROI (approximation)
    double installationCost = (financial?['installationCost'] ?? 0).toDouble();
    if (type == 'surface') {
      // Coût supplémentaire pour la surface ajoutée (environ 8000 DH/kWc)
      final additionalCost = (newPvPower - currentPvPower) * 8000;
      installationCost = installationCost + additionalCost;
    } else if (type == 'battery') {
      // Coût supplémentaire pour la batterie (environ 4500 DH/kWh)
      final additionalCost = (newBatteryCapacity - currentBatteryCapacity) * 4500;
      installationCost = installationCost + additionalCost;
    }
    
    if (newAnnualSavings > 0) {
      newRoi = installationCost / newAnnualSavings;
    }
    
    return {
      'scenarioDescription': scenarioDescription,
      'current': {
        'autonomy': currentAutonomy,
        'annualSavings': currentAnnualSavings,
        'roi': currentRoi,
        'monthlyBill': currentMonthlyBill,
        'annualBill': currentAnnualBill,
        'pvPower': currentPvPower,
        'batteryCapacity': currentBatteryCapacity,
        'monthlyConsumption': currentMonthlyConsumption,
      },
      'scenario': {
        'autonomy': newAutonomy,
        'annualSavings': newAnnualSavings,
        'roi': newRoi,
        'monthlyBill': newMonthlyBill,
        'annualBill': newAnnualBill,
        'pvPower': newPvPower,
        'batteryCapacity': newBatteryCapacity,
        'monthlyConsumption': newMonthlyConsumption,
      },
      'changes': {
        'autonomy': newAutonomy - currentAutonomy,
        'annualSavings': newAnnualSavings - currentAnnualSavings,
        'roi': newRoi - currentRoi,
        'monthlyBill': newMonthlyBill - currentMonthlyBill,
        'annualBill': newAnnualBill - currentAnnualBill,
      },
    };
  }

  void _showScenarioResultsDialog(String type, double value, Map<String, dynamic> results) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = results['current'] as Map<String, dynamic>;
    final scenario = results['scenario'] as Map<String, dynamic>;
    final changes = results['changes'] as Map<String, dynamic>;
    final scenarioDescription = results['scenarioDescription'] as String;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          decoration: BoxDecoration(
            color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MedicalSolarColors.medicalBlue.withOpacity(0.2),
                      MedicalSolarColors.solarGreen.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MedicalSolarColors.medicalBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.insights_rounded, color: MedicalSolarColors.medicalBlue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résultats du Scénario',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scenarioDescription,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: isDark ? Colors.white70 : MedicalSolarColors.softGrey,
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildScenarioComparisonRow(
                        'Autonomie énergétique',
                        '${current['autonomy'].toStringAsFixed(1)}%',
                        '${scenario['autonomy'].toStringAsFixed(1)}%',
                        changes['autonomy'],
                        Icons.battery_charging_full_rounded,
                        MedicalSolarColors.solarGreen,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildScenarioComparisonRow(
                        'Économies annuelles',
                        '${current['annualSavings'].toStringAsFixed(0)} DH',
                        '${scenario['annualSavings'].toStringAsFixed(0)} DH',
                        changes['annualSavings'],
                        Icons.savings_rounded,
                        MedicalSolarColors.medicalBlue,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildScenarioComparisonRow(
                        'ROI',
                        '${current['roi'].toStringAsFixed(1)} ans',
                        '${scenario['roi'].toStringAsFixed(1)} ans',
                        changes['roi'],
                        Icons.trending_up_rounded,
                        MedicalSolarColors.solarYellow,
                        isDark,
                        isRoi: true, // Pour ROI, moins c'est mieux
                      ),
                      const SizedBox(height: 16),
                      _buildScenarioComparisonRow(
                        'Facture mensuelle',
                        '${current['monthlyBill'].toStringAsFixed(0)} DH',
                        '${scenario['monthlyBill'].toStringAsFixed(0)} DH',
                        changes['monthlyBill'],
                        Icons.receipt_long_rounded,
                        Colors.orange.shade400,
                        isDark,
                        isBill: true, // Pour facture, moins c'est mieux
                      ),
                      const SizedBox(height: 16),
                      _buildScenarioComparisonRow(
                        'Facture annuelle',
                        '${current['annualBill'].toStringAsFixed(0)} DH',
                        '${scenario['annualBill'].toStringAsFixed(0)} DH',
                        changes['annualBill'],
                        Icons.calendar_month_rounded,
                        Colors.red.shade400,
                        isDark,
                        isBill: true,
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Fermer',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: MedicalSolarColors.medicalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioComparisonRow(
    String label,
    String currentValue,
    String scenarioValue,
    double change,
    IconData icon,
    Color color,
    bool isDark, {
    bool isRoi = false,
    bool isBill = false,
  }) {
    // Pour ROI et facture, un changement négatif est positif
    final isPositive = isRoi || isBill ? change < 0 : change > 0;
    final changeColor = isPositive ? MedicalSolarColors.solarGreen : Colors.red.shade400;
    final changeIcon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final changeText = isPositive 
        ? '+${change.abs().toStringAsFixed(isRoi ? 1 : 0)}${isRoi ? ' ans' : (isBill ? ' DH' : '%')}'
        : '${change.toStringAsFixed(isRoi ? 1 : 0)}${isRoi ? ' ans' : (isBill ? ' DH' : '%')}';
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface.withOpacity(0.5) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actuel',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : MedicalSolarColors.softGrey.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentValue,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Scénario',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : MedicalSolarColors.softGrey.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scenarioValue,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(changeIcon, size: 16, color: changeColor),
                const SizedBox(width: 6),
                Text(
                  changeText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ONGLET 6: ALERTES
  Widget _buildAlertsTab(bool isDark, bool isMobile) {
    if (_recommendations == null) {
      return const Center(child: Text('Alertes non disponibles'));
    }

    final autonomy = _recommendations!.energyAutonomy;
    final roi = _comprehensiveResults!['financial']?['roi'] ?? 0;
    
    final alerts = <Map<String, dynamic>>[];
    
    if (autonomy < 30) {
      alerts.add({
        'type': 'warning',
        'icon': Icons.warning_rounded,
        'title': 'Autonomie faible',
        'message': 'L\'autonomie est inférieure à 30%. Recommandation: augmenter la surface PV.',
        'color': Colors.orange.shade400,
      });
    }
    
    if (roi > 15) {
      alerts.add({
        'type': 'info',
        'icon': Icons.info_rounded,
        'title': 'ROI élevé',
        'message': 'Le retour sur investissement est supérieur à 15 ans. Optimisation recommandée.',
        'color': MedicalSolarColors.medicalBlue,
      });
    }

    if (alerts.isEmpty) {
      alerts.add({
        'type': 'success',
        'icon': Icons.check_circle_rounded,
        'title': 'Aucune alerte',
        'message': 'Votre configuration est optimale.',
        'color': MedicalSolarColors.solarGreen,
      });
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          ...alerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAlertCard(alert, isDark),
          )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, bool isDark) {
    final alertColor = alert['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            alertColor.withOpacity(isDark ? 0.2 : 0.1),
            alertColor.withOpacity(isDark ? 0.1 : 0.05),
          ],
        ),
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: alertColor.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alertColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(alert['icon'] as IconData, color: alertColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert['message'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ONGLET 7: PRÉDICTIONS IA
  Widget _buildAIPredictionsTab(bool isDark, bool isMobile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Pour les établissements NEW, les prédictions/anomalies nécessitent des données historiques
          if (!_isNewEstablishment) ...[
            if (_forecast != null) ...[
              Text(
                'Prévisions Long Terme',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                ),
              ),
              const SizedBox(height: 16),
              _buildForecastChart(_forecast!, isDark, isMobile),
              const SizedBox(height: 24),
            ],
            if (_mlRecommendations != null) ...[
              Text(
                'Recommandations ML',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                ),
              ),
              const SizedBox(height: 16),
              ..._mlRecommendations!.recommendations.map((rec) => _buildMLRecommendationCard(rec, isDark)),
              const SizedBox(height: 24),
            ],
            if (_anomalies != null) ...[
              Text(
                'Détection d\'Anomalies',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                ),
              ),
              const SizedBox(height: 16),
              _buildAnomaliesInfo(_anomalies!, isDark),
            ],
          ],
          if (_isNewEstablishment || (_forecast == null && _mlRecommendations == null && _anomalies == null))
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      _isNewEstablishment ? Icons.construction_rounded : Icons.info_outline_rounded,
                      size: 48,
                      color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isNewEstablishment
                          ? 'Les prédictions IA et la détection d\'anomalies nécessitent des données historiques de consommation.\nElles seront disponibles une fois l\'établissement construit et opérationnel.'
                          : 'Les données de prédiction IA nécessitent un historique suffisant.\nElles seront disponibles après quelques jours d\'utilisation.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildForecastChart(LongTermForecastResponse forecast, bool isDark, bool isMobile) {
    final spots = forecast.predictions.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.predictedConsumption);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: SizedBox(
        height: isMobile ? 250 : 300,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [MedicalSolarColors.medicalBlue, MedicalSolarColors.solarGreen],
                ),
                barWidth: 3,
              ),
            ],
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMLRecommendationCard(Recommendation rec, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MedicalSolarColors.medicalBlue.withOpacity(isDark ? 0.15 : 0.08),
            MedicalSolarColors.medicalBlue.withOpacity(isDark ? 0.08 : 0.04),
          ],
        ),
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MedicalSolarColors.medicalBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MedicalSolarColors.medicalBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rec.type.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: MedicalSolarColors.medicalBlue,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_rounded, color: MedicalSolarColors.solarYellow, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.message,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (rec.suggestion != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MedicalSolarColors.solarGreen.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: MedicalSolarColors.solarGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_rounded, color: MedicalSolarColors.solarGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suggestion: ${rec.suggestion}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomaliesInfo(AnomalyGraphResponse anomalies, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques des Anomalies',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Total d\'anomalies', '${anomalies.statistics.totalAnomalies}', isDark),
          _buildInfoRow('Anomalies consommation élevée', '${anomalies.statistics.highConsumptionAnomalies}', isDark),
          _buildInfoRow('Anomalies consommation faible', '${anomalies.statistics.lowConsumptionAnomalies}', isDark),
          _buildInfoRow('Anomalies PV', '${anomalies.statistics.pvMalfunctionAnomalies}', isDark),
          _buildInfoRow('Batterie faible', '${anomalies.statistics.batteryLowAnomalies}', isDark),
          _buildInfoRow('Score moyen', anomalies.statistics.averageAnomalyScore.toStringAsFixed(2), isDark),
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
              color: isDark ? Colors.white70 : MedicalSolarColors.softGrey.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
            ),
          ),
        ],
      ),
    );
  }
}
