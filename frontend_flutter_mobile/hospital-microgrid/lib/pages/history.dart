import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospital_microgrid/widgets/metric_card.dart';

import 'package:hospital_microgrid/theme/medical_solar_colors.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const List<Map<String, dynamic>> monthlyData = [
    {'month': 'Jan', 'consumption': 2400.0, 'generation': 1200.0, 'savings': 400.0},
    {'month': 'Feb', 'consumption': 2210.0, 'generation': 1290.0, 'savings': 450.0},
    {'month': 'Mar', 'consumption': 2290.0, 'generation': 1500.0, 'savings': 520.0},
    {'month': 'Apr', 'consumption': 2000.0, 'generation': 1800.0, 'savings': 580.0},
    {'month': 'May', 'consumption': 2181.0, 'generation': 2100.0, 'savings': 650.0},
    {'month': 'Jun', 'consumption': 2500.0, 'generation': 2300.0, 'savings': 720.0},
  ];

  static const List<Map<String, dynamic>> dailyData = [
    {'date': '1', 'load': 2400.0, 'solar': 1200.0},
    {'date': '5', 'load': 2210.0, 'solar': 1290.0},
    {'date': '10', 'load': 2290.0, 'solar': 1500.0},
    {'date': '15', 'load': 2000.0, 'solar': 1800.0},
    {'date': '20', 'load': 2181.0, 'solar': 2100.0},
    {'date': '25', 'load': 2500.0, 'solar': 2300.0},
    {'date': '30', 'load': 2400.0, 'solar': 2200.0},
  ];

  Future<void> _onRefresh() async {
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
              'Long-term consumption and generation trends',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : MedicalSolarColors.softGrey.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            // History Metrics
            if (isMobile)
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: const [
                    MetricCard(
                      icon: Icons.calendar_today,
                      label: 'Total Consumption',
                      value: '14.58 MWh',
                      change: 'this month',
                      gradientColors: [
                        MedicalSolarColors.medicalBlue,
                        MedicalSolarColors.solarGreen,
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.trending_up,
                      label: 'Total Generation',
                      value: '10.29 MWh',
                      change: '+15.2%',
                      gradientColors: [
                        MedicalSolarColors.solarGreen,
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.trending_down,
                      label: 'Total Savings',
                      value: '3.29 MWh',
                      change: '+22.5%',
                      gradientColors: [
                        Color(0xFF8B5CF6),
                        MedicalSolarColors.medicalBlue,
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.bolt,
                      label: 'Avg Efficiency',
                      value: '70.6%',
                      change: '+5.8%',
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
                        icon: Icons.calendar_today,
                        label: 'Total Consumption',
                        value: '14.58 MWh',
                        change: 'this month',
                        gradientColors: [
                          MedicalSolarColors.medicalBlue,
                          MedicalSolarColors.solarGreen,
                        ],
                      ),
                      MetricCard(
                        icon: Icons.trending_up,
                        label: 'Total Generation',
                        value: '10.29 MWh',
                        change: '+15.2%',
                        gradientColors: [
                          MedicalSolarColors.solarGreen,
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      MetricCard(
                        icon: Icons.trending_down,
                        label: 'Total Savings',
                        value: '3.29 MWh',
                        change: '+22.5%',
                        gradientColors: [
                          Color(0xFF8B5CF6),
                          MedicalSolarColors.medicalBlue,
                        ],
                      ),
                      MetricCard(
                        icon: Icons.bolt,
                        label: 'Avg Efficiency',
                        value: '70.6%',
                        change: '+5.8%',
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
            // Monthly Trends
            if (isMobile)
              Column(
                children: [
                  _buildMonthlyConsumptionChart(),
                  const SizedBox(height: 16),
                  _buildSavingsTrendChart(),
                ],
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 1000) {
                    return Column(
                      children: [
                        _buildMonthlyConsumptionChart(),
                        const SizedBox(height: 24),
                        _buildSavingsTrendChart(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMonthlyConsumptionChart(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildSavingsTrendChart(),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            // Daily Breakdown
            _buildDailyChart(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyConsumptionChart() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Consumption vs Generation',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : MedicalSolarColors.softGrey,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 280 : 320,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
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
                        if (value.toInt() < monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyData[value.toInt()]['month'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
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
                            color: Colors.white.withOpacity(0.5),
                            fontSize: isMobile ? 10 : 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (monthlyData.length - 1).toDouble(),
                minY: 0,
                maxY: 3000,
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value['consumption'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    ),
                    barWidth: 3,
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
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value['generation'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF006064)],
                    ),
                    barWidth: 3,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsTrendChart() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Savings Trend',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : MedicalSolarColors.softGrey,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 280 : 320,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
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
                        if (value.toInt() < monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyData[value.toInt()]['month'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
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
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: isMobile ? 10 : 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (monthlyData.length - 1).toDouble(),
                minY: 0,
                maxY: 800,
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value['savings'] as double,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Load vs Solar Generation',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : MedicalSolarColors.softGrey,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 280 : 320,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
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
                        if (value.toInt() < dailyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dailyData[value.toInt()]['date'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
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
                            color: Colors.white.withOpacity(0.5),
                            fontSize: isMobile ? 10 : 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (dailyData.length - 1).toDouble(),
                minY: 0,
                maxY: 3000,
                lineBarsData: [
                  LineChartBarData(
                    spots: dailyData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value['load'] as double,
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: dailyData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value['solar'] as double,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}