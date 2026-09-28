import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/widgets.dart';
import '../models/food_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'nutri_app.db';
  static const int _dbVersion = 1;

  // Singleton
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_entries(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        food_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        fiber REAL NOT NULL DEFAULT 0,
        sugar REAL NOT NULL DEFAULT 0,
        sodium REAL NOT NULL DEFAULT 0,
        vitamin_a REAL,
        vitamin_c REAL,
        vitamin_d REAL,
        calcium REAL,
        iron REAL,
        potassium REAL,
        logged_at TEXT NOT NULL,
        meal_type TEXT NOT NULL
      )
    ''');

    // Índices para consultas rápidas
    await db.execute(
      'CREATE INDEX idx_user_date ON food_entries(user_id, logged_at)',
    );
    await db.execute(
      'CREATE INDEX idx_food_name ON food_entries(food_name)',
    );
  }

  // Insertar entrada
  Future<void> insertEntry(FoodEntry entry) async {
    final db = await database;
    await db.insert(
      'food_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener entradas del día
  Future<List<FoodEntry>> getEntriesForDay(String userId, DateTime day) async {
    final db = await database;
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'food_entries',
      where: 'user_id = ? AND logged_at >= ? AND logged_at < ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'logged_at DESC',
    );

    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }

  // Obtener entradas de un rango (para gráficos)
  Future<List<FoodEntry>> getEntriesInRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'food_entries',
      where: 'user_id = ? AND logged_at >= ? AND logged_at < ?',
      whereArgs: [
        userId,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'logged_at ASC',
    );

    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }

  // Eliminar entrada
  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('food_entries', where: 'id = ?', whereArgs: [id]);
  }

  // Búsqueda local de alimentos creados por el usuario
  Future<List<FoodEntry>> searchLocalFoods(String userId, String query) async {
    final db = await database;
    final maps = await db.query(
      'food_entries',
      where: 'user_id = ? AND food_name LIKE ?',
      whereArgs: [userId, '%$query%'],
      limit: 20,
    );

    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }
}