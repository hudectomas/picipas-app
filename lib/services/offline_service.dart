import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

// Conditional imports - sqflite only on non-web platforms
import 'package:sqflite/sqflite.dart' if (dart.library.html) 'sqflite_web_stub.dart';
import 'package:path/path.dart' as path if (dart.library.html) 'path_web_stub.dart';

class OfflineService {
  static Database? _database;
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  bool get isWeb => kIsWeb;

  Future<Database?> get database async {
    if (isWeb) return null; // SQLite nefunguje na web
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database?> _initDatabase() async {
    if (isWeb) return null; // SQLite nefunguje na web
    
    try {
      final dbPath = await getDatabasesPath();
      final dbFilePath = path.join(dbPath, 'picipas_offline.db');

      return await openDatabase(
        dbFilePath,
        version: 1,
        onCreate: (db, version) async {
          // Tabuľka pre offline body (pre obsluhu)
          await db.execute('''
            CREATE TABLE offline_points (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              drink_id INTEGER,
              quantity INTEGER,
              points_earned INTEGER,
              notes TEXT,
              created_at TEXT,
              synced INTEGER DEFAULT 0
            )
          ''');

          // Tabuľka pre offline históriu (pre zákazníkov)
          await db.execute('''
            CREATE TABLE offline_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              drink_id INTEGER,
              quantity INTEGER,
              points_earned INTEGER,
              consumed_at TEXT,
              synced INTEGER DEFAULT 0
            )
          ''');

          // Tabuľka pre cache používateľov
          await db.execute('''
            CREATE TABLE cached_users (
              id INTEGER PRIMARY KEY,
              name TEXT,
              surname TEXT,
              email TEXT,
              qr_code TEXT,
              total_points INTEGER,
              role TEXT,
              updated_at TEXT
            )
          ''');

          // Tabuľka pre cache nápojov
          await db.execute('''
            CREATE TABLE cached_drinks (
              id INTEGER PRIMARY KEY,
              name TEXT,
              alcohol_percentage REAL,
              points_per_unit INTEGER,
              unit TEXT,
              active INTEGER,
              updated_at TEXT
            )
          ''');
        },
      );
    } catch (e) {
      // Chyba pri inicializácii databázy
      return null;
    }
  }

  // Kontrola online/offline stavu
  Future<bool> isOnline() async {
    // Na web, connectivity_plus môže vracať nesprávne výsledky
    // Skúsime skutočný HTTP request
    if (isWeb) {
      try {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/drinks'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 3));
        return response.statusCode < 500; // Ak dostaneme odpoveď (aj 401/403), sme online
      } catch (e) {
        return false;
      }
    }
    
    // Na mobile/desktop používame connectivity_plus
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      // Ak connectivity_plus zlyhá, skúsime HTTP request
      try {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/drinks'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 3));
        return response.statusCode < 500;
      } catch (e) {
        return false;
      }
    }
  }

  // Stream pre sledovanie zmeny connectivity
  Stream<bool> get connectivityStream async* {
    yield await isOnline();
    await for (final result in Connectivity().onConnectivityChanged) {
      yield !result.contains(ConnectivityResult.none);
    }
  }

  // Uložiť body offline (pre obsluhu)
  Future<int> saveOfflinePoints({
    required int userId,
    required int drinkId,
    required int quantity,
    required int pointsEarned,
    String? notes,
  }) async {
    if (isWeb) {
      return await _saveOfflinePointsWeb(userId, drinkId, quantity, pointsEarned, notes);
    }
    
    final db = await database;
    if (db == null) return 0;
    
    return await db.insert('offline_points', {
      'user_id': userId,
      'drink_id': drinkId,
      'quantity': quantity,
      'points_earned': pointsEarned,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  // Web implementácia pre offline body
  Future<int> _saveOfflinePointsWeb(int userId, int drinkId, int quantity, int pointsEarned, String? notes) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_points';
    final existing = prefs.getStringList(key) ?? [];
    final point = {
      'id': existing.length + 1,
      'user_id': userId,
      'drink_id': drinkId,
      'quantity': quantity,
      'points_earned': pointsEarned,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    existing.add(jsonEncode(point));
    await prefs.setStringList(key, existing);
    return existing.length;
  }

  // Získať všetky nesynchronizované body
  Future<List<Map<String, dynamic>>> getUnsyncedPoints() async {
    if (isWeb) {
      return await _getUnsyncedPointsWeb();
    }
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query(
      'offline_points',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  // Web implementácia pre získanie nesynchronizovaných bodov
  Future<List<Map<String, dynamic>>> _getUnsyncedPointsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_points';
    final points = prefs.getStringList(key) ?? [];
    return points
        .map((p) => jsonDecode(p) as Map<String, dynamic>)
        .where((p) => p['synced'] == 0)
        .toList();
  }

  // Označiť body ako synchronizované
  Future<void> markPointsAsSynced(int id) async {
    if (isWeb) {
      await _markPointsAsSyncedWeb(id);
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    await db.update(
      'offline_points',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Web implementácia pre označenie bodov ako synchronizovaných
  Future<void> _markPointsAsSyncedWeb(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_points';
    final points = prefs.getStringList(key) ?? [];
    final updated = points.map((p) {
      final point = jsonDecode(p) as Map<String, dynamic>;
      if (point['id'] == id) {
        point['synced'] = 1;
      }
      return jsonEncode(point);
    }).toList();
    await prefs.setStringList(key, updated);
  }

  // Vymazať synchronizované body
  Future<void> deleteSyncedPoints() async {
    if (isWeb) {
      await _deleteSyncedPointsWeb();
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    await db.delete(
      'offline_points',
      where: 'synced = ?',
      whereArgs: [1],
    );
  }

  // Web implementácia pre vymazanie synchronizovaných bodov
  Future<void> _deleteSyncedPointsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_points';
    final points = prefs.getStringList(key) ?? [];
    final filtered = points
        .map((p) => jsonDecode(p) as Map<String, dynamic>)
        .where((p) => p['synced'] != 1)
        .map((p) => jsonEncode(p))
        .toList();
    await prefs.setStringList(key, filtered);
  }

  // Cache používateľov
  Future<void> cacheUsers(List<Map<String, dynamic>> users) async {
    if (isWeb) {
      await _cacheUsersWeb(users);
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    final batch = db.batch();
    
    for (final user in users) {
      batch.insert(
        'cached_users',
        {
          'id': user['id'],
          'name': user['name'],
          'surname': user['surname'],
          'email': user['email'],
          'qr_code': user['qr_code'],
          'total_points': user['total_points'],
          'role': user['role'],
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Web implementácia pre cache používateľov
  Future<void> _cacheUsersWeb(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_users', jsonEncode(users));
  }

  // Získať cacheovaných používateľov
  Future<List<Map<String, dynamic>>> getCachedUsers() async {
    if (isWeb) {
      return await _getCachedUsersWeb();
    }
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query('cached_users');
  }

  // Web implementácia pre získanie cacheovaných používateľov
  Future<List<Map<String, dynamic>>> _getCachedUsersWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_users');
    if (cached == null) return [];
    try {
      final decoded = jsonDecode(cached) as List;
      return decoded
          .map((user) => user as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Vyhľadať používateľa v cache
  Future<List<Map<String, dynamic>>> searchCachedUsers(String query) async {
    if (isWeb) {
      return await _searchCachedUsersWeb(query);
    }
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query(
      'cached_users',
      where: 'name LIKE ? OR surname LIKE ? OR email LIKE ? OR id = ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', int.tryParse(query) ?? -1],
    );
  }

  // Web implementácia pre vyhľadávanie používateľov
  Future<List<Map<String, dynamic>>> _searchCachedUsersWeb(String query) async {
    final users = await _getCachedUsersWeb();
    final lowerQuery = query.toLowerCase();
    return users.where((user) {
      return user['name']?.toString().toLowerCase().contains(lowerQuery) == true ||
          user['surname']?.toString().toLowerCase().contains(lowerQuery) == true ||
          user['email']?.toString().toLowerCase().contains(lowerQuery) == true ||
          user['id']?.toString() == query;
    }).toList();
  }

  // Cache nápojov
  Future<void> cacheDrinks(List<Map<String, dynamic>> drinks) async {
    if (isWeb) {
      await _cacheDrinksWeb(drinks);
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    final batch = db.batch();
    
    for (final drink in drinks) {
      batch.insert(
        'cached_drinks',
        {
          'id': drink['id'],
          'name': drink['name'],
          'alcohol_percentage': drink['alcohol_percentage'],
          'points_per_unit': drink['points_per_unit'],
          'unit': drink['unit'],
          'active': drink['active'] ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Web implementácia pre cache nápojov
  Future<void> _cacheDrinksWeb(List<Map<String, dynamic>> drinks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_drinks', jsonEncode(drinks));
  }

  // Získať cacheované nápoje
  Future<List<Map<String, dynamic>>> getCachedDrinks() async {
    if (isWeb) {
      return await _getCachedDrinksWeb();
    }
    
    final db = await database;
    if (db == null) return [];
    
    final results = await db.query('cached_drinks', where: 'active = ?', whereArgs: [1]);
    return results.map((row) => {
      ...row,
      'active': row['active'] == 1,
    }).toList();
  }

  // Web implementácia pre získanie cacheovaných nápojov
  Future<List<Map<String, dynamic>>> _getCachedDrinksWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_drinks');
    if (cached == null) return [];
    final drinks = List<Map<String, dynamic>>.from(jsonDecode(cached) as List);
    return drinks.where((d) => d['active'] == true).toList();
  }

  // Uložiť históriu offline (pre zákazníkov)
  Future<int> saveOfflineHistory({
    required int userId,
    required int drinkId,
    required int quantity,
    required int pointsEarned,
  }) async {
    if (isWeb) {
      return await _saveOfflineHistoryWeb(userId, drinkId, quantity, pointsEarned);
    }
    
    final db = await database;
    if (db == null) return 0;
    
    return await db.insert('offline_history', {
      'user_id': userId,
      'drink_id': drinkId,
      'quantity': quantity,
      'points_earned': pointsEarned,
      'consumed_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  // Web implementácia pre offline históriu
  Future<int> _saveOfflineHistoryWeb(int userId, int drinkId, int quantity, int pointsEarned) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_history';
    final existing = prefs.getStringList(key) ?? [];
    final history = {
      'id': existing.length + 1,
      'user_id': userId,
      'drink_id': drinkId,
      'quantity': quantity,
      'points_earned': pointsEarned,
      'consumed_at': DateTime.now().toIso8601String(),
      'synced': 0,
    };
    existing.add(jsonEncode(history));
    await prefs.setStringList(key, existing);
    return existing.length;
  }

  // Získať nesynchronizovanú históriu
  Future<List<Map<String, dynamic>>> getUnsyncedHistory() async {
    if (isWeb) {
      return await _getUnsyncedHistoryWeb();
    }
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query(
      'offline_history',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  // Web implementácia pre získanie nesynchronizovanej histórie
  Future<List<Map<String, dynamic>>> _getUnsyncedHistoryWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_history';
    final history = prefs.getStringList(key) ?? [];
    return history
        .map((h) => jsonDecode(h) as Map<String, dynamic>)
        .where((h) => h['synced'] == 0)
        .toList();
  }

  // Označiť históriu ako synchronizovanú
  Future<void> markHistoryAsSynced(int id) async {
    if (isWeb) {
      await _markHistoryAsSyncedWeb(id);
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    await db.update(
      'offline_history',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Web implementácia pre označenie histórie ako synchronizovanej
  Future<void> _markHistoryAsSyncedWeb(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'offline_history';
    final history = prefs.getStringList(key) ?? [];
    final updated = history.map((h) {
      final item = jsonDecode(h) as Map<String, dynamic>;
      if (item['id'] == id) {
        item['synced'] = 1;
      }
      return jsonEncode(item);
    }).toList();
    await prefs.setStringList(key, updated);
  }
}
