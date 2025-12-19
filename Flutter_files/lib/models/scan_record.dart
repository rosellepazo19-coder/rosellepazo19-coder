import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class ScanRecord {
  final String? id; // Firestore document ID
  final String containerType;
  final double confidence;
  final DateTime scanDate;
  final String? imagePath;

  ScanRecord({
    this.id,
    required this.containerType,
    required this.confidence,
    required this.scanDate,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    final normalizedConfidence = confidence > 1 ? confidence / 100 : confidence;
    return {
      'containerType': containerType,
      'confidence': normalizedConfidence,
      // Store ISO for consistent parsing/order.
      'scanDate': scanDate.toUtc().toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawConfidence = (map['confidence'] as num?)?.toDouble() ?? 0.0;
    final normalizedConfidence = rawConfidence > 1 ? rawConfidence / 100 : rawConfidence;

    DateTime _parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) {
        try {
          return DateTime.parse(raw);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    final dynamic rawDate = map['DateTime'] ?? map['scanDate'] ?? map['timestamp'];
    final parsedDate = _parseDate(rawDate);

    return ScanRecord(
      id: docId ?? map['id']?.toString(),
      containerType: map['containerType'] as String,
      confidence: normalizedConfidence,
      scanDate: parsedDate.toLocal(),
      imagePath: map['imagePath'] as String?,
    );
  }

  ScanRecord copyWith({
    String? id,
    String? containerType,
    double? confidence,
    DateTime? scanDate,
    String? imagePath,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      containerType: containerType ?? this.containerType,
      confidence: confidence ?? this.confidence,
      scanDate: scanDate ?? this.scanDate,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

