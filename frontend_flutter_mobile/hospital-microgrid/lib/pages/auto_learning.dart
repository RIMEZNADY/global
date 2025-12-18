import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospital_microgrid/widgets/metric_card.dart';

class AutoLearningPage extends StatefulWidget {
  const AutoLearningPage({super.key});

  @override
  State<AutoLearningPage> createState() => _AutoLearningPageState();
}

class _AutoLearningPageState extends State<AutoLearningPage> {
  static const learningData = [
    {'day': 'Mon', 'accuracy': 88, 'efficiency': 82},
    {'day': 'Tue', 'accuracy': 90, 'efficiency': 84},
    {'day': 'Wed', 'accuracy': 92, 'efficiency': 86},
    {'day': 'Thu', 'accuracy': 94, 'efficiency': 88},
    {'day': 'Fri', 'accuracy': 95, 'efficiency': 90},
    {'day': 'Sat', 'accuracy': 96, 'efficiency': 91},
    {'day': 'Sun', 'accuracy': 96, 'efficiency': 92},
  ];

  static const patternData = [
    {'pattern': 'Morning Peak', 'frequency': 95, 'impact': 'High'},
    {'pattern': 'Afternoon Dip', 'frequency': 87, 'impact': 'Medium'},
    {'pattern': 'Evening Surge', 'frequency': 92, 'impact': 'High'},
    {'pattern': 'Night Low', 'frequency': 100, 'impact': 'Low'},
  ];

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF6366F1),
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
              'Self-learning system continuously improving',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.7) : const Color(0xFF0F172A).withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            // Learning Metrics
            if (isMobile)
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: const [
                    MetricCard(
                      icon: Icons.flag,
                      label: 'Learning Progress',
                      value: '96%',
                      change: '+8% this week',
                      gradientColors: [
                        Color(0xFF6366F1),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.trending_up,
                      label: 'Accuracy Improvement',
                      value: '+8.2%',
                      change: 'vs baseline',
                      gradientColors: [
                        Color(0xFF06B6D4),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.show_chart,
                      label: 'Patterns Learned',
                      value: '24',
                      change: '+3 new patterns',
                      gradientColors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF6366F1),
                      ],
                    ),
                    SizedBox(width: 12),
                    MetricCard(
                      icon: Icons.bolt,
                      label: 'Energy Saved',
                      value: '12.4%',
                      change: 'this month',
                      gradientColors: [
                        Color(0xFF6366F1),
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
                        icon: Icons.flag,
                        label: 'Learning Progress',
                        value: '96%',
                        change: '+8% this week',
                        gradientColors: [
                          Color(0xFF6366F1),
                          Color(0xFF06B6D4),
                        ],
                      ),
                      MetricCard(
                        icon: Icons.trending_up,
                        label: 'Accuracy Improvement',
                        value: '+8.2%',
                        change: 'vs baseline',
                        gradientColors: [
                          Color(0xFF06B6D4),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                      MetricCard(
                        icon: Icons.show_chart,
                        label: 'Patterns Learned',
                        value: '24',
                        change: '+3 new patterns',
                        gradientColors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF6366F1),
                        ],
                      ),
                      MetricCard(
                        icon: Icons.bolt,
                        label: 'Energy Saved',
                        value: '12.4%',
                        change: 'this month',
                        gradientColors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            // Learning Progress Charts
            if (isMobile)
              Column(
                children: [
                  _buildLearningProgressChart(),
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
                        _buildLearningProgressChart(),
                        const SizedBox(height: 24),
                        _buildEfficiencyChart(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLearningProgressChart(),
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
            // Learned Patterns
            _buildPatternsCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningProgressChart() {
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
            'Weekly Learning Progress',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          SizedBox(
            height: isMobile ? 280 : 320,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
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
                        if (value.toInt() < learningData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              learningData[value.toInt()]['day'] as String,
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
                          '${value.toInt()}%',
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
                barGroups: learningData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['accuracy'] as int).toDouble(),
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

  Widget _buildEfficiencyChart() {
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
            'Efficiency Improvement',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
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
                  horizontalInterval: 20,
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
                        if (value.toInt() < learningData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              learningData[value.toInt()]['day'] as String,
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
                          '${value.toInt()}%',
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
                maxX: (learningData.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: learningData.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        (e.value['efficiency'] as int).toDouble(),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsCard() {
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
            'Discovered Energy Patterns',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...patternData.map((pattern) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pattern['pattern'] as String,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Frequency: ${pattern['frequency']}% | Impact: ${pattern['impact']}',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : const Color(0xFF0F172A).withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 128,
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (pattern['frequency'] as int) / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF06B6D4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
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
