import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Color _getContainerColor(String type) {
    switch (type.toLowerCase()) {
      case 'aluminum can':
        return const Color(0xFF64B5F6);
      case 'coconut shell':
        return const Color(0xFF8D6E63);
      case 'glass bottle':
        return const Color(0xFF81C784);
      case 'mug':
        return const Color(0xFFFFB74D);
      case 'paper cup':
        return const Color(0xFFE57373);
      case 'plastic bottle':
        return const Color(0xFF9575CD);
      case 'thermos flask':
        return const Color(0xFF4DD0E1);
      case 'tumbler':
        return const Color(0xFFF06292);
      case 'water jug':
        return const Color(0xFF4FC3F7);
      case 'wine glass':
        return const Color(0xFFBA68C8);
      default:
        return const Color(0xFFE891B0);
    }
  }

  IconData _getContainerIcon(String type) {
    switch (type.toLowerCase()) {
      case 'aluminum can':
        return Icons.local_drink;
      case 'coconut shell':
        return Icons.eco;
      case 'glass bottle':
        return Icons.wine_bar;
      case 'mug':
        return Icons.coffee;
      case 'paper cup':
        return Icons.coffee_outlined;
      case 'plastic bottle':
        return Icons.water_drop;
      case 'thermos flask':
        return Icons.thermostat;
      case 'tumbler':
        return Icons.local_cafe;
      case 'water jug':
        return Icons.water;
      case 'wine glass':
        return Icons.wine_bar_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final containerCounts = provider.containerCounts;
            final totalScans = provider.totalScans;

            return RefreshIndicator(
              onRefresh: () async {
                await provider.refreshData();
              },
              color: const Color(0xFFE891B0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Scans',
                              totalScans.toString(),
                              Icons.qr_code_scanner_rounded,
                              const Color(0xFFE891B0),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              'Types Found',
                              containerCounts.length.toString(),
                              Icons.category_rounded,
                              const Color(0xFF7DD3C0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Line Chart
                      _buildLineChartCard(containerCounts),
                      const SizedBox(height: 24),

                      // Container Breakdown
                      _buildContainerBreakdown(containerCounts, totalScans),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB5BA), Color(0xFFE891B0)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE891B0).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: Color(0xFF2D2D3A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Container statistics',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF2D2D3A).withOpacity(0.5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(Map<String, int> containerCounts) {
    // Sort by count descending
    final sortedEntries = containerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final spots = <FlSpot>[];
    final labels = <String>[];
    double maxY = 5;

    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value.toDouble()));
      labels.add(sortedEntries[i].key);
      if (sortedEntries[i].value > maxY) {
        maxY = sortedEntries[i].value.toDouble();
      }
    }

    maxY = maxY + 2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: const Color(0xFFD4A5FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFFD4A5FF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Scan Count by Container',
                style: TextStyle(
                  color: Color(0xFF2D2D3A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (containerCounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 48,
                      color: const Color(0xFF2D2D3A).withOpacity(0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data yet',
                      style: TextStyle(
                        color: const Color(0xFF2D2D3A).withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFF0F0F0),
                        strokeWidth: 1,
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
                        reservedSize: 50,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            // Shorten long names
                            String label = labels[index];
                            if (label.length > 8) {
                              label = '${label.substring(0, 7)}..';
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: _getContainerColor(labels[index]),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                        interval: maxY / 4,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble().clamp(0, double.infinity),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE891B0), Color(0xFFD4A5FF)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final color = index < labels.length
                              ? _getContainerColor(labels[index])
                              : const Color(0xFFE891B0);
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: color,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFE891B0).withOpacity(0.25),
                            const Color(0xFFE891B0).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: const Color(0xFF2D2D3A),
                      tooltipRoundedRadius: 12,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final name = index < labels.length ? labels[index] : '';
                          return LineTooltipItem(
                            '$name\n${spot.y.toInt()} scans',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContainerBreakdown(Map<String, int> containerCounts, int totalScans) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: const Color(0xFF7DD3C0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: Color(0xFF7DD3C0),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Container Breakdown',
                style: TextStyle(
                  color: Color(0xFF2D2D3A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (containerCounts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: const Color(0xFF2D2D3A).withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data yet',
                      style: TextStyle(
                        color: const Color(0xFF2D2D3A).withOpacity(0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start scanning to see analytics',
                      style: TextStyle(
                        color: const Color(0xFF2D2D3A).withOpacity(0.3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...containerCounts.entries.map((entry) {
              final percentage = totalScans > 0
                  ? (entry.value / totalScans * 100)
                  : 0.0;
              return _buildContainerItem(
                entry.key,
                entry.value,
                percentage,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildContainerItem(String name, int count, double percentage) {
    final color = _getContainerColor(name);
    final icon = _getContainerIcon(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF2D2D3A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: const Color(0xFF2D2D3A).withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
