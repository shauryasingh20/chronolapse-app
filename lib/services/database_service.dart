import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/memory.dart';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      debugPrint('Initializing database...');
      _database = await _initDatabase();
      debugPrint('Database initialized successfully');
      return _database!;
    } catch (e, stackTrace) {
      debugPrint('Error initializing database: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'chronolapse.db');
      debugPrint('Database path: $path');
      return await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          debugPrint('Creating database tables...');
          await db.execute('''
            CREATE TABLE memories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              imagePath TEXT NOT NULL,
              note TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL
            )
          ''');
          debugPrint('Database tables created successfully');
        },
        onOpen: (db) {
          debugPrint('Database opened successfully');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error in _initDatabase: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> insertMemory(Memory memory) async {
    final db = await database;
    return await db.insert('memories', memory.toMap());
  }

  Future<List<Memory>> getMemories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => Memory.fromMap(maps[i]));
  }

  Future<Memory?> getMemory(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'memories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Memory.fromMap(maps.first);
  }

  Future<List<Memory>> getNearbyMemories(double lat, double lon, double radiusKm) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('memories');
    
    return List.generate(maps.length, (i) {
      final memory = Memory.fromMap(maps[i]);
      final distance = _calculateDistance(lat, lon, memory.latitude, memory.longitude);
      if (distance <= radiusKm) {
        return memory;
      }
      return null;
    }).whereType<Memory>().toList();
  }

  Future<int> deleteMemory(int id) async {
    try {
      debugPrint('deleteMemory called for id: \\${id}');
      final db = await database;
      // First get the memory to delete its image file
      final memory = await getMemory(id);
      if (memory != null) {
        final file = File(memory.imagePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted image file: \\${memory.imagePath}');
        } else {
          debugPrint('Image file does not exist: \\${memory.imagePath}');
        }
      } else {
        debugPrint('Memory not found for id: \\${id}');
      }
      final result = await db.delete(
        'memories',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Rows deleted: \\${result}');
      return result;
    } catch (e) {
      debugPrint('Error deleting memory: \\${e.toString()}');
      rethrow;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple Haversine formula for distance calculation
    const R = 6371.0; // Earth's radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  Future<int> updateMemoryNote(int id, String newNote) async {
    try {
      final db = await database;
      return await db.update(
        'memories',
        {'note': newNote},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating memory note: $e');
      rethrow;
    }
  }
} 