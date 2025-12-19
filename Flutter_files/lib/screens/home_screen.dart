import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onAnalyticsTap;
  final VoidCallback onRecordsTap;

  const HomeScreen({
    super.key,
    required this.onScanTap,
    required this.onAnalyticsTap,
    required this.onRecordsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1F6),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final averageConfidence = provider.records.isEmpty
                ? null
                : provider.records
                        .map((r) => r.confidence > 1 ? r.confidence / 100 : r.confidence)
                        .fold<double>(0, (sum, value) => sum + value) /
                    provider.records.length;

            return Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -80,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE891B0).withOpacity(0.25),
                          const Color(0xFFD4A5FF).withOpacity(0.18),
                        ],
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildHeroCard(onScanTap, provider.totalScans),
                        const SizedBox(height: 18),
                        _buildStatusRow(provider),
                        const SizedBox(height: 18),
                        _buildStatsRow(
                          total: provider.totalScans,
                          types: provider.containerCounts.length,
                        ),
                        const SizedBox(height: 18),
                        _buildRecentScanCard(provider, onScanTap),
                        const SizedBox(height: 24),
                        const Text(
                          'What We Identify',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D2D3A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildContainerTypesGrid(),
                        const SizedBox(height: 24),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D2D3A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.insights_rounded,
                                title: 'Analytics',
                                subtitle: 'View insights',
                                color: const Color(0xFFFFB5BA),
                                onTap: onAnalyticsTap,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildActionCard(
                                icon: Icons.history_rounded,
                                title: 'Records',
                                subtitle: 'Scan history',
                                color: const Color(0xFF7DD3C0),
                                onTap: onRecordsTap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
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
              colors: [Color(0xFFE891B0), Color(0xFFD4A5FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE891B0).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_drink_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Container',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D2D3A),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Beverages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE891B0),
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF9CA3AF),
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(VoidCallback onScanTap, int totalScans) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE891B0), Color(0xFFD4A5FF)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE891B0).withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'AI-Powered',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$totalScans scans logged',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Identify Beverage\nContainers Instantly',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Point your camera at any container and let AI identify it for you.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFE891B0),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Start Scanning',
                    style: TextStyle(
                      color: Color(0xFF2D2D3A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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

  Widget _buildStatusRow(AppProvider provider) {
    final hasScans = provider.records.isNotEmpty;
    final latest = hasScans ? provider.records.first : null;

    final chips = [
      _StatusChip(
        icon: Icons.bolt_rounded,
        label: 'AI ready',
        color: const Color(0xFFE891B0),
      ),
      _StatusChip(
        icon: Icons.cloud_done_rounded,
        label: 'Cloud synced',
        color: const Color(0xFF7DD3C0),
      ),
      _StatusChip(
        icon: Icons.verified_rounded,
        label: hasScans ? 'Last: ${latest!.containerType}' : 'No scans yet',
        color: const Color(0xFFD4A5FF),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (chip) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: chip,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatsRow({
    required int total,
    required int types,
  }) {
    final cards = [
      _buildStatCard(
        icon: Icons.qr_code_scanner_rounded,
        value: total.toString(),
        label: 'Total Scans',
        color: const Color(0xFF7DD3C0),
        subtitle: 'Across all sessions',
      ),
      _buildStatCard(
        icon: Icons.category_rounded,
        value: types.toString(),
        label: 'Types Found',
        color: const Color(0xFFD4A5FF),
        subtitle: 'Unique containers',
      ),
    ];

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _buildRecentScanCard(AppProvider provider, VoidCallback onScanTap) {
    final latest = provider.records.isNotEmpty ? provider.records.first : null;
    final formatter = DateFormat('MMM d, h:mm a');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: latest == null
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE891B0).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFE891B0)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'No scans yet. Start scanning to see recent activity.',
                    style: TextStyle(
                      color: Color(0xFF2D2D3A),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE891B0), Color(0xFFD4A5FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latest scan',
                            style: TextStyle(
                              color: const Color(0xFF2D2D3A).withOpacity(0.55),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latest.containerType,
                            style: const TextStyle(
                              color: Color(0xFF2D2D3A),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(latest.scanDate),
                            style: TextStyle(
                              color: const Color(0xFF2D2D3A).withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onScanTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE891B0).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.camera_enhance_rounded,
                          color: Color(0xFFE891B0),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      label:
                          'Confidence ${(latest.confidence * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      color: const Color(0xFFE891B0),
                    ),
                    _buildChip(
                      label: 'Tap to rescan',
                      color: const Color(0xFF7DD3C0),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2D2D3A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF2D2D3A).withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerTypesGrid() {
    final containers = [
      {'icon': Icons.local_drink, 'name': 'Aluminum Can', 'color': const Color(0xFF64B5F6)},
      {'icon': Icons.eco, 'name': 'Coconut Shell', 'color': const Color(0xFF8D6E63)},
      {'icon': Icons.wine_bar, 'name': 'Glass Bottle', 'color': const Color(0xFF81C784)},
      {'icon': Icons.coffee, 'name': 'Mug', 'color': const Color(0xFFFFB74D)},
      {'icon': Icons.coffee_outlined, 'name': 'Paper Cup', 'color': const Color(0xFFE57373)},
      {'icon': Icons.water_drop, 'name': 'Plastic Bottle', 'color': const Color(0xFF9575CD)},
      {'icon': Icons.thermostat, 'name': 'Thermos Flask', 'color': const Color(0xFF4DD0E1)},
      {'icon': Icons.local_cafe, 'name': 'Tumbler', 'color': const Color(0xFFF06292)},
      {'icon': Icons.water, 'name': 'Water Jug', 'color': const Color(0xFF4FC3F7)},
      {'icon': Icons.wine_bar_outlined, 'name': 'Wine Glass', 'color': const Color(0xFFBA68C8)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.3,
        ),
        itemCount: containers.length,
        itemBuilder: (context, index) {
          final item = containers[index];
          final color = item['color'] as Color;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withOpacity(0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2D2D3A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: const Color(0xFF2D2D3A).withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

