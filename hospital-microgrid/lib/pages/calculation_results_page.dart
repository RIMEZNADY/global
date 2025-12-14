import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospital_microgrid/services/establishment_service.dart';
import 'package:hospital_microgrid/services/ai_service.dart';
import 'package:hospital_microgrid/main.dart';
import 'package:hospital_microgrid/providers/theme_provider.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class CalculationResultsPage extends StatefulWidget {
  final int establishmentId;
  final ThemeProvider themeProvider;

  const CalculationResultsPage({
    super.key,
    required this.establishmentId,
    required this.themeProvider,
  });

  @override
  State<CalculationResultsPage> createState() => _CalculationResultsPageState();
}

class _CalculationResultsPageState extends State<CalculationResultsPage> {
  bool _isLoading = true;
  String? _error;
  
  SimulationResponse? _simulation;
  RecommendationsResponse? _recommendations;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger recommandations d'abord pour obtenir la capacité batterie recommandée
      final recommendations = await EstablishmentService.getRecommendations(widget.establishmentId);
      
      // Charger simulation avec la capacité batterie recommandée
      final simulation = await AiService.simulate(
        widget.establishmentId,
        startDate: DateTime.now().toIso8601String(),
        days: 7,
        batteryCapacityKwh: recommendations.recommendedBatteryCapacity,
        initialSocKwh: recommendations.recommendedBatteryCapacity * 0.5, // 50% initial SOC
      );

      setState(() {
        _simulation = simulation;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.7)),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
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
        title: const Text('Résultats - Calcul Mathématique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: _goToDashboard,
            tooltip: 'Aller au Dashboard',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? MedicalSolarColors.softGrey : MedicalSolarColors.offWhite,
        ),
        child: RefreshIndicator(
          onRefresh: _loadData,
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
                  'Analyse Basée sur vos données (Calcul mathématique)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : MedicalSolarColors.softGrey.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                // Graphiques (A3 style)
                if (_simulation != null) ...[
                  _buildConsumptionChart(_simulation!, isDark, isMobile),
                  const SizedBox(height: 24),
                  _buildSolarProductionChart(_simulation!, isDark, isMobile),
                  const SizedBox(height: 24),
                  _buildBatterySOCChart(_simulation!, isDark, isMobile),
                  const SizedBox(height: 24),
                  _buildWeatherImpactChart(_simulation!, isDark, isMobile),
                  const SizedBox(height: 32),
                ],
                // Recommandations (A4 style)
                if (_recommendations != null) ...[
                  Text(
                    'Recommandations du Système',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Basées sur votre consommation et votre surface disponible',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : MedicalSolarColors.softGrey.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRecommendationCard(
                    context: context,
                    isDark: isDark,
                    isMobile: isMobile,
                    icon: Icons.savings,
                    title: 'Économie possible',
                    value: _recommendations!.annualSavings.toStringAsFixed(0),
                    unit: 'DH/an',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRecommendationCard(
                    context: context,
                    isDark: isDark,
                    isMobile: isMobile,
                    icon: Icons.battery_charging_full,
                    title: 'Pourcentage d\'autonomie possible',
                    value: _recommendations!.energyAutonomy.toStringAsFixed(1),
                    unit: '%',
                    gradient: const LinearGradient(
                      colors: [MedicalSolarColors.solarGreen, Color(0xFF0891B2)],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRecommendationCard(
                    context: context,
                    isDark: isDark,
                    isMobile: isMobile,
                    icon: Icons.solar_power,
                    title: 'Puissance PV recommandée',
                    value: _recommendations!.recommendedPvPower.toStringAsFixed(2),
                    unit: 'kW',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRecommendationCard(
                    context: context,
                    isDark: isDark,
                    isMobile: isMobile,
                    icon: Icons.battery_std,
                    title: 'Capacité batterie recommandée',
                    value: _recommendations!.recommendedBatteryCapacity.toStringAsFixed(2),
                    unit: 'kWh',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), MedicalSolarColors.medicalBlue],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Graphiques (similaires à A3)
  Widget _buildConsumptionChart(SimulationResponse sim, bool isDark, bool isMobile) {
    final steps = sim.steps.take(24).toList(); // Premier jour
    final spots = steps.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.predictedConsumption);
    }).toList();

    final maxConsumption = spots.isEmpty ? 1000.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return _buildChartCard(
      context: context,
      isDark: isDark,
      isMobile: isMobile,
      title: 'Consommation réelle',
      chart: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: isMobile ? 250 : 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                drawHorizontalLine: true,
                horizontalInterval: maxConsumption > 0 ? (maxConsumption / 5) : 200,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return const FlLine(
                    color: Colors.transparent,
                    strokeWidth: 0,
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
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
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
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
                          fontSize: 12,
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
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(colors: [MedicalSolarColors.medicalBlue, MedicalSolarColors.solarGreen]),
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      return LineTooltipItem(
                        '${touchedSpot.y.toInt()} kWh',
                        TextStyle(
                          color: isDark ? Colors.white : MedicalSolarColors.softGrey,
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
      ),
    );
  }

  Widget _buildSolarProductionChart(SimulationResponse sim, bool isDark, bool isMobile) {
    final steps = sim.steps.take(24).toList();
    final spots = steps.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.pvProduction);
    }).toList();

    final maxProduction = spots.isEmpty ? 500.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return _buildChartCard(
      context: context,
      isDark: isDark,
      isMobile: isMobile,
      title: 'Production solaire potentielle',
      chart: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: isMobile ? 250 : 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                drawHorizontalLine: true,
                horizontalInterval: maxProduction > 0 ? (maxProduction / 5) : 100,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return const FlLine(
                    color: Colors.transparent,
                    strokeWidth: 0,
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
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
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
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
                          fontSize: 12,
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
              maxY: maxProduction > 0 ? maxProduction * 1.2 : 500,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      return LineTooltipItem(
                        '${touchedSpot.y.toInt()} kWh',
                        TextStyle(
                          color: isDark ? Colors.white : MedicalSolarColors.softGrey,
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
      ),
    );
  }

  Widget _buildBatterySOCChart(SimulationResponse sim, bool isDark, bool isMobile) {
    final steps = sim.steps.take(24).toList();
    final spots = steps.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.socBattery);
    }).toList();

    return _buildChartCard(
      context: context,
      isDark: isDark,
      isMobile: isMobile,
      title: 'SOC batterie simulé',
      chart: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: isMobile ? 250 : 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                drawHorizontalLine: true,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return const FlLine(
                    color: Colors.transparent,
                    strokeWidth: 0,
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
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
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
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
                          fontSize: 12,
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
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(colors: [MedicalSolarColors.solarGreen, Color(0xFF8B5CF6)]),
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      return LineTooltipItem(
                        '${touchedSpot.y.toInt()}%',
                        TextStyle(
                          color: isDark ? Colors.white : MedicalSolarColors.softGrey,
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
      ),
    );
  }

  Widget _buildWeatherImpactChart(SimulationResponse sim, bool isDark, bool isMobile) {
    final steps = sim.steps.take(24).toList();
    final bars = steps.asMap().entries.map((e) {
      // Simulation approximative de l'irradiance basée sur la production PV
      final maxPv = steps.map((s) => s.pvProduction).reduce((a, b) => a > b ? a : b);
      final irradiance = maxPv > 0 ? (e.value.pvProduction / maxPv * 100.0) : 0.0;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: irradiance.clamp(0, 100),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: isMobile ? 12 : 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return _buildChartCard(
      context: context,
      isDark: isDark,
      isMobile: isMobile,
      title: 'Impact météo (ensoleillement, irradiation)',
      chart: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: isMobile ? 250 : 300,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                drawHorizontalLine: true,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return const FlLine(
                    color: Colors.transparent,
                    strokeWidth: 0,
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
                              color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
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
                        '${value.toInt()}%',
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 100,
              barGroups: bars,
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
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : MedicalSolarColors.softGrey,
            ),
          ),
          const SizedBox(height: 24),
          chart,
        ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? MedicalSolarColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white.withOpacity(0.7) : MedicalSolarColors.softGrey.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : MedicalSolarColors.softGrey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        unit,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white.withOpacity(0.6) : MedicalSolarColors.softGrey.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
