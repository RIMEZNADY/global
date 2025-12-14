import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospital_microgrid/widgets/metric_card.dart';
import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const energyData = [
    {'time': '00:00', 'solar': 0.0, 'grid': 2400.0, 'battery': 1200.0, 'load': 2800.0},
    {'time': '04:00', 'solar': 100.0, 'grid': 2210.0, 'battery': 1290.0, 'load': 2000.0},
    {'time': '08:00', 'solar': 2290.0, 'grid': 1200.0, 'battery': 800.0, 'load': 2181.0},
    {'time': '12:00', 'solar': 3490.0, 'grid': 400.0, 'battery': 0.0, 'load': 2500.0},
    {'time': '16:00', 'solar': 2100.0, 'grid': 1398.0, 'battery': 500.0, 'load': 2100.0},
    {'time': '20:00', 'solar': 200.0, 'grid': 2800.0, 'battery': 1200.0, 'load': 2800.0},
    {'time': '24:00', 'solar': 0.0, 'grid': 2400.0, 'battery': 1200.0, 'load': 2800.0},
  ];

  static const efficiencyData = [
    {'hour': '00', 'efficiency': 78},
    {'hour': '04', 'efficiency': 82},
    {'hour': '08', 'efficiency': 88},
    {'hour': '12', 'efficiency': 95},
    {'hour': '16', 'efficiency': 92},
    {'hour': '20', 'efficiency': 85},
    {'hour': '24', 'efficiency': 80},
  ];

  Future<void> _onRefresh() async {
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
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
            const SizedBox(height: 8),
            Text(
              'Real-time monitoring and analytics',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : MedicalSolarColors.softGrey.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            // Metric Cards - Horizontal scrollable on mobile, grid on desktop
            if (isMobile)
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: const [
                    MetricCard(
                      icon: Icons.bolt,
                      label: 'Current Load',
                      value: '2.8 MW',
                      change: '+2.4%',
                      gradientColors: [
                        MedicalSolarColors.medicalBlue,
                        MedicalSolarColors.solarGreen,
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.trending_up,
                      label: 'Solar Generation',
                      value: '1.2 MW',
                      change: '+12.5%',
                      gradientColors: [
                        MedicalSolarColors.solarGreen,
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.show_chart,
                      label: 'System Efficiency',
                      value: '92%',
                      change: '+5.2%',
                      gradientColors: [
                        Color(0xFF8B5CF6),
                        MedicalSolarColors.medicalBlue,
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.warning_amber,
                      label: 'Battery Status',
                      value: '78%',
                      change: '-1.8%',
                      gradientColors: [
                        MedicalSolarColors.medicalBlue,
                        Color(0xFF8B5CF6),
                      ],
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
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
                    children: const [
                      MetricCard(
                        icon: Icons.bolt,
                        label: 'Current Load',
                        value: '2.8 MW',
                        change: '+2.4%',
                        gradientColors: [
                          MedicalSolarColors.medicalBlue,
                          MedicalSolarColors.solarGreen,
                        ],
                      ),
                      MetricCard(
                        icon: Icons.trending_up,
                        label: 'Solar Generation',
                        value: '1.2 MW',
                        change: '+12.5%',
                        gradientColors: [
                          MedicalSolarColors.solarGreen,
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      MetricCard(
                        icon: Icons.show_chart,
                        label: 'System Efficiency',
                        value: '92%',
                        change: '+5.2%',
                        gradientColors: [
                          Color(0xFF8B5CF6),
                          MedicalSolarColors.medicalBlue,
                        ],
                      ),
                      MetricCard(
                        icon: Icons.warning_amber,
                        label: 'Battery Status',
                        value: '78%',
                        change: '-1.8%',
                        gradientColors: [
                          MedicalSolarColors.medicalBlue,
                          Color(0xFF8B5CF6),
                        ],
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            // Charts Row - Stack on mobile
            if (isMobile)
              Column(
                children: [
                  _buildEnergyFlowChart(),
                  const SizedBox(height: 16),
                  _buildEfficiencyChart(),
                ],
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 1000) {
                    return Column(
                      children: [
                        _buildEnergyFlowChart(),
                        const SizedBox(height: 24),
                        _buildEfficiencyChart(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildEnergyFlowChart(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildEfficiencyChart(),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            // Load Distribution Chart
            _buildLoadDistributionChart(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyFlowChart() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
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
            'Energy Flow (24h)',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : MedicalSolarColors.softGrey,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 280 : 320,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.15)
                          : MedicalSolarColors.softGrey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < energyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              energyData[value.toInt()]['time'] as String,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : MedicalSolarColors.softGrey.withOpacity(0.7),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.w500,
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
                            color: Theme.of(context).brightness == Brightness.dark
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
                maxX: (energyData.length - 1).toDouble(),
                minY: 0,
                maxY: 4000,
                lineBarsData: [
                  LineChartBarData(
                    spots: energyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['solar'] as double);
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF006064)],
                    ),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00E5FF).withOpacity(0.3),
                          const Color(0xFF00E5FF).withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: energyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['grid'] as double);
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    ),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7C3AED).withOpacity(0.3),
                          const Color(0xFF7C3AED).withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyChart() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
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
            'System Efficiency',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : MedicalSolarColors.softGrey,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 280 : 320,
            width: double.infinity,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.15)
                          : MedicalSolarColors.softGrey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < efficiencyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              efficiencyData[value.toInt()]['hour'] as String,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : MedicalSolarColors.softGrey.withOpacity(0.7),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.w500,
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
                            color: Theme.of(context).brightness == Brightness.dark
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
                barGroups: efficiencyData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['efficiency'] as int).toDouble(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF006064)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: isMobile ? 16 : 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadDistributionChart() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
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
            'Load Distribution',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : MedicalSolarColors.softGrey,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 280 : 320,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.15)
                          : MedicalSolarColors.softGrey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < energyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              energyData[value.toInt()]['time'] as String,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.7)
                                    : MedicalSolarColors.softGrey.withOpacity(0.7),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.w500,
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
                            color: Theme.of(context).brightness == Brightness.dark
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
                maxX: (energyData.length - 1).toDouble(),
                minY: 0,
                maxY: 4000,
                lineBarsData: [
                  LineChartBarData(
                    spots: energyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['load'] as double);
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF006064)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: energyData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value['battery'] as double);
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF40E0D0), Color(0xFF0080FF)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
