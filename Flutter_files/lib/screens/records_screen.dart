import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/scan_record.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _filterType = 'All';

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final datePart = DateFormat('MMMM dd, yyyy').format(local);
    final timePart = DateFormat('hh:mm:ss a').format(local);
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(1, '0');
    final minutes =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final tz = 'UTC$sign$hours${minutes != '00' ? ':$minutes' : ''}';
    return '$datePart at $timePart $tz';
  }

  List<String> _getContainerTypes(List<ScanRecord> records) {
    final types = records.map((r) => r.containerType).toSet().toList();
    types.sort();
    return ['All', ...types];
  }

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
            final allRecords = provider.records;
            final filteredRecords = _filterType == 'All'
                ? allRecords
                : allRecords.where((r) => r.containerType == _filterType).toList();

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7DD3C0), Color(0xFF4DB6AC)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7DD3C0).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Records',
                              style: TextStyle(
                                color: Color(0xFF2D2D3A),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${filteredRecords.length} scans recorded',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (allRecords.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showClearAllDialog(context, provider),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.delete_sweep_rounded,
                              color: Colors.red.withOpacity(0.6),
                              size: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Filter chips
                SizedBox(
                  height: 44,
                  child: Builder(
                    builder: (context) {
                      final containerTypes = _getContainerTypes(allRecords);
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: containerTypes.length,
                        itemBuilder: (context, index) {
                          final type = containerTypes[index];
                      final isSelected = _filterType == type;
                      final color = type == 'All'
                          ? const Color(0xFFE891B0)
                          : _getContainerColor(type);

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterType = type;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [color, color.withOpacity(0.8)],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? color.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: isSelected ? 12 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2D2D3A).withOpacity(0.6),
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Records list
                Expanded(
                  child: filteredRecords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.inbox_rounded,
                                  size: 56,
                                  color: const Color(0xFF2D2D3A).withOpacity(0.15),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No records found',
                                style: TextStyle(
                                  color: const Color(0xFF2D2D3A).withOpacity(0.6),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filterType == 'All'
                                    ? 'Start scanning to create records'
                                    : 'No $_filterType scans yet',
                                style: TextStyle(
                                  color: const Color(0xFF2D2D3A).withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            return _buildRecordCard(context, record, provider);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    ScanRecord record,
    AppProvider provider,
  ) {
    final color = _getContainerColor(record.containerType);
    final icon = _getContainerIcon(record.containerType);
    final dateFormat = DateFormat('MMMM dd, yyyy at hh:mm:ss a');

    return Dismissible(
      key: Key('record_${record.id ?? record.scanDate.microsecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.red,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Delete Record?',
              style: TextStyle(
                color: Color(0xFF2D2D3A),
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: const Color(0xFF2D2D3A).withOpacity(0.6),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: const Color(0xFF2D2D3A).withOpacity(0.5),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (record.id != null) {
          provider.deleteRecord(record.id!);
        }
      },
      child: GestureDetector(
        onTap: () => _showRecordDetails(context, record),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image or Icon
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: record.imagePath != null && File(record.imagePath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(record.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 32,
                      ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.containerType,
                        style: const TextStyle(
                          color: Color(0xFF2D2D3A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(record.confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(record.scanDate),
                        style: TextStyle(
                          color: const Color(0xFF2D2D3A).withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF2D2D3A).withOpacity(0.3),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(BuildContext context, ScanRecord record) {
    final color = _getContainerColor(record.containerType);
    final icon = _getContainerIcon(record.containerType);
    final dateFormat = DateFormat('MMMM dd, yyyy at hh:mm:ss a');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            if (record.imagePath != null && File(record.imagePath!).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  File(record.imagePath!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 64,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.containerType,
                        style: const TextStyle(
                          color: Color(0xFF2D2D3A),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(record.scanDate),
                        style: TextStyle(
                          color: const Color(0xFF2D2D3A).withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confidence Score',
                    style: TextStyle(
                      color: const Color(0xFF2D2D3A).withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(record.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Clear All Records?',
          style: TextStyle(
            color: Color(0xFF2D2D3A),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete all scan records. This action cannot be undone.',
          style: TextStyle(
            color: const Color(0xFF2D2D3A).withOpacity(0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF2D2D3A).withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              provider.clearAllRecords();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All records cleared'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF2D2D3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
