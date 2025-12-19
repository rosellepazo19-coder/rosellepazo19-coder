import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';

class FirestoreService {
  static const String _collection = 'scan_records';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  String _formatDisplay(DateTime dateTime) {
    final local = dateTime.toLocal();
    final datePart = DateFormat('MMMM dd, yyyy').format(local);
    final timePart = DateFormat('hh:mm:ss a').format(local);
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString();
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final tz = 'UTC$sign$hours${minutes != '00' ? ':$minutes' : ''}';
    return '$datePart at $timePart $tz';
  }

  Future<String> insertRecord(ScanRecord record) async {
    final normalizedConfidence = record.confidence > 1
        ? record.confidence / 100
        : record.confidence;
    final data = <String, dynamic>{
      'containerType': record.containerType,
      'confidence': normalizedConfidence * 100, // store as percentage for clarity
      'DateTime': FieldValue.serverTimestamp(), // sortable
      'imagePath': record.imagePath,
    };
    final doc = await _col.add(data);
    return doc.id;
  }

  Future<List<ScanRecord>> getAllRecords() async {
    final snapshot = await _col.orderBy('DateTime', descending: true).get();
    return snapshot.docs
        .map((d) => ScanRecord.fromMap(d.data(), docId: d.id))
        .toList();
  }

  Future<List<ScanRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _col
        .where('DateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('DateTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('DateTime', descending: true)
        .get();
    return snapshot.docs
        .map((d) => ScanRecord.fromMap(d.data(), docId: d.id))
        .toList();
  }

  Future<Map<String, int>> getContainerTypeCounts() async {
    final snapshot = await _col.get();
    final Map<String, int> counts = {};
    for (final d in snapshot.docs) {
      final data = d.data();
      final type = data['containerType'] as String? ?? '';
      if (type.isEmpty) continue;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  Future<int> getTotalScans() async {
    final snapshot = await _col.get();
    return snapshot.docs.length;
  }

  Future<List<Map<String, dynamic>>> getDailyScans(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _col
        .where('DateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .get();
    final Map<String, int> counts = {};
    for (final d in snapshot.docs) {
      final data = d.data();
      DateTime? dt;
      final raw = data['DateTime'];
      if (raw is Timestamp) dt = raw.toDate();
      if (dt == null && raw is String) dt = DateTime.tryParse(raw);
      if (dt == null) continue;
      final key =
          DateTime(dt.year, dt.month, dt.day).toIso8601String().substring(0, 10);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final e in entries) {'date': e.key, 'count': e.value}
    ];
  }

  Future<void> deleteRecord(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> deleteAllRecords() async {
    final snapshot = await _col.get();
    final batch = _db.batch();
    for (final d in snapshot.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}

