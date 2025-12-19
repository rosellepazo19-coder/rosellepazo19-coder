import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/scan_record.dart';

class DatabaseHelper {
  // NOTE: This helper is no longer used on web (Firestore is used).
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('database is not available on web');
    }
    if (_database != null) return _database!;
    _database = await _initDB('beverages.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        containerType TEXT NOT NULL,
        confidence REAL NOT NULL,
        scanDate TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
  }

  // The legacy methods below are retained for non-web platforms if ever needed.

  Future<int> insertRecord(ScanRecord record) async {
    final db = await database;
    return await db.insert('scan_records', record.toMap());
  }

  Future<List<ScanRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(
      'scan_records',
      orderBy: 'scanDate DESC',
    );
    return maps.map((map) => ScanRecord.fromMap(map)).toList();
  }

  Future<List<ScanRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'scan_records',
      where: 'scanDate BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'scanDate DESC',
    );
    return maps.map((map) => ScanRecord.fromMap(map)).toList();
  }

  Future<Map<String, int>> getContainerTypeCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT containerType, COUNT(*) as count
      FROM scan_records
      GROUP BY containerType
      ORDER BY count DESC
    ''');

    return {
      for (var row in result)
        row['containerType'] as String: row['count'] as int
    };
  }

  Future<int> getTotalScans() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM scan_records');
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getDailyScans(int days) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    final result = await db.rawQuery('''
      SELECT DATE(scanDate) as date, COUNT(*) as count
      FROM scan_records
      WHERE scanDate >= ?
      GROUP BY DATE(scanDate)
      ORDER BY date ASC
    ''', [startDate.toIso8601String()]);

    return result;
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'scan_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllRecords() async {
    final db = await database;
    return await db.delete('scan_records');
  }
}

