// db_operations.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'time_entry_model.dart';
import 'settings_model.dart';

class DatabaseOperations {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'time_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE time_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            description TEXT NOT NULL,
            rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 10),
            created_at TEXT NOT NULL
          )
        ''');
        // Create settings table
        await db.execute('''
        CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        default_timer_duration INTEGER NOT NULL,
        is_alarm_enabled INTEGER NOT NULL,
        are_notifications_enabled INTEGER NOT NULL,
        updated_at TEXT NOT NULL
        )
        ''');

        // Insert default settings
        await db.insert('settings', {
          'default_timer_duration': 30,
          'is_alarm_enabled': 1,
          'are_notifications_enabled': 1,
          'updated_at': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  // Add a new time entry
  Future<int> addTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.insert(
      'time_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Settings> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('settings');

    if (maps.isEmpty) {
      // If no settings exist (shouldn't happen due to default insertion), create default
      final Settings defaultSettings = Settings(
        defaultTimerDuration: 25,
        isAlarmEnabled: true,
        areNotificationsEnabled: true,
        updatedAt: DateTime.now(),
      );

      await updateSettings(defaultSettings);
      return defaultSettings;
    }

    return Settings.fromMap(maps.first); // Added missing return statement
  }

  Future<void> updateSettings(Settings settings) async {
    final db = await database;

    // Update existing settings or insert if none exist
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> existing = await txn.query('settings');

      if (existing.isEmpty) {
        await txn.insert('settings', settings.toMap());
      } else {
        await txn.update(
          'settings',
          settings.toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }
    });
  }

  // Modified getTimeEntries to include error handling and retries
  Future<List<TimeEntry>> getTimeEntries({
    int page = 1,
    int pageSize = 20,
    String? sortBy = 'timestamp',
    bool descending = true,
  }) async {
    final db = await database;
    final offset = (page - 1) * pageSize;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'time_entries',
        limit: pageSize,
        offset: offset,
        orderBy: '$sortBy ${descending ? 'DESC' : 'ASC'}',
      );

      return List.generate(maps.length, (i) {
        return TimeEntry.fromMap(maps[i]);
      });
    } catch (e) {
      // If query fails, try to repair the database
      await db.execute('VACUUM');

      // Retry the query
      final List<Map<String, dynamic>> maps = await db.query(
        'time_entries',
        limit: pageSize,
        offset: offset,
        orderBy: '$sortBy ${descending ? 'DESC' : 'ASC'}',
      );

      return List.generate(maps.length, (i) {
        return TimeEntry.fromMap(maps[i]);
      });
    }
  }

  // Get total count of entries (for pagination)
  Future<int> getTotalEntries() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM time_entries');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get entries for a specific date range
  Future<List<TimeEntry>> getEntriesInRange(
    DateTime startDate,
    DateTime endDate, {
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'time_entries',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      limit: limit,
      offset: offset,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return TimeEntry.fromMap(maps[i]);
    });
  }

  // Update a time entry
  Future<int> updateTimeEntry(TimeEntry entry) async {
    final db = await database;
    return await db.update(
      'time_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Delete a time entry
  Future<int> deleteTimeEntry(int id) async {
    final db = await database;
    return await db.delete(
      'time_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
