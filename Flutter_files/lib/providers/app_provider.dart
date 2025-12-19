import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/firestore_service.dart';
import '../services/classifier_service.dart';

class AppProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final ClassifierService _classifier = ClassifierService();

  List<ScanRecord> _records = [];
  Map<String, int> _containerCounts = {};
  int _totalScans = 0;
  bool _isLoading = false;
  String? _error;

  List<ScanRecord> get records => _records;
  Map<String, int> get containerCounts => _containerCounts;
  int get totalScans => _totalScans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ClassifierService get classifier => _classifier;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _classifier.initialize();
      await refreshData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    _records = await _firestore.getAllRecords();
    _containerCounts = await _firestore.getContainerTypeCounts();
    _totalScans = await _firestore.getTotalScans();
    notifyListeners();
  }

  Future<void> addRecord(ScanRecord record) async {
    final nowUtc = DateTime.now().toUtc();
    final normalizedConfidence =
        record.confidence > 1 ? record.confidence / 100 : record.confidence;
    final preparedRecord = record.copyWith(
      confidence: normalizedConfidence,
      scanDate: nowUtc,
    );

    final id = await _firestore.insertRecord(preparedRecord);
    _records.insert(0, preparedRecord.copyWith(id: id, scanDate: nowUtc.toLocal()));
    _totalScans += 1;
    _containerCounts[record.containerType] =
        (_containerCounts[record.containerType] ?? 0) + 1;
    await refreshData();
  }

  Future<void> deleteRecord(String id) async {
    await _firestore.deleteRecord(id);
    await refreshData();
  }

  Future<void> clearAllRecords() async {
    await _firestore.deleteAllRecords();
    await refreshData();
  }

  Future<List<Map<String, dynamic>>> getDailyScans(int days) async {
    return await _firestore.getDailyScans(days);
  }

  @override
  void dispose() {
    _classifier.dispose();
    super.dispose();
  }
}

