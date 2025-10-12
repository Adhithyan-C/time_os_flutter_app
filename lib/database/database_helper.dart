// lib/database/database_helper.dart

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static const _databaseName = "app_database.db";
  static const _databaseVersion = 1;
  static const tableTasks = 'tasks';
  static const tableFixedEvents = 'fixed_events';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // ✅ UPDATED _onCreate() — added eventType column in fixed_events table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        details TEXT,
        estimatedDuration INTEGER NOT NULL,
        deadline TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        isComplete INTEGER NOT NULL,
        scheduledTime TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFixedEvents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER NOT NULL,
        daysOfWeek TEXT NOT NULL,
        eventType INTEGER DEFAULT 5
      )
    ''');
  }

  // ==================== TASK METHODS ====================

  Future<int> addTask(Task task) async {
    Database db = await instance.database;
    return await db.insert(tableTasks, task.toMap());
  }

  Future<List<Task>> getAllTasks() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableTasks);
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  Future<int> updateTask(Task task) async {
    Database db = await instance.database;
    return await db.update(
      tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    Database db = await instance.database;
    return await db.delete(tableTasks, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== FIXED EVENT METHODS ====================

  Future<int> addFixedEvent(FixedEvent event) async {
    Database db = await instance.database;
    return await db.insert(tableFixedEvents, event.toMap());
  }

  Future<List<FixedEvent>> getAllFixedEvents() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableFixedEvents);
    return List.generate(maps.length, (i) {
      return FixedEvent.fromMap(maps[i]);
    });
  }

  Future<int> updateFixedEvent(FixedEvent event) async {
    Database db = await instance.database;
    return await db.update(
      tableFixedEvents,
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteFixedEvent(int id) async {
    Database db = await instance.database;
    return await db.delete(tableFixedEvents, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllData() async {
    Database db = await instance.database;
    await db.delete(tableTasks);
    await db.delete(tableFixedEvents);
  }

  // ==================== ENHANCED SMART SCHEDULING ====================

  Future<DateTime?> findNextAvailableSlot(
    Duration duration,
    DateTime deadline, {
    TaskDifficulty? taskDifficulty,
  }) async {
    final sleepStart = await PreferencesHelper.getSleepStartTime();
    final sleepEnd = await PreferencesHelper.getSleepEndTime();
    final dayStart = await PreferencesHelper.getDayStartTime();
    final dayEnd = await PreferencesHelper.getDayEndTime();
    final peakWindow = await PreferencesHelper.getPeakProductivityWindow();
    final breakDuration = await PreferencesHelper.getAutoBreakDuration();

    final allEvents = await getAllFixedEvents();
    final allTasks = await getAllTasks();

    var searchTime = DateTime.now();

    Duration effectiveDuration = duration;
    if (breakDuration > 0) {
      effectiveDuration = duration + Duration(minutes: breakDuration);
    }

    while (searchTime.isBefore(deadline)) {
      var potentialEndTime = searchTime.add(effectiveDuration);

      if (_isDuringSleep(searchTime, sleepStart, sleepEnd)) {
        searchTime = _getNextWakeTime(searchTime, sleepEnd);
        continue;
      }

      if (!_isWithinWorkWindow(searchTime, dayStart, dayEnd)) {
        searchTime = _getNextDayStart(searchTime, dayStart);
        continue;
      }

      bool conflictsWithEvent = false;
      for (var event in allEvents) {
        if (event.daysOfWeek.contains(
          DayOfWeek.values[searchTime.weekday % 7],
        )) {
          final eventStart = DateTime(
            searchTime.year,
            searchTime.month,
            searchTime.day,
            event.startTime.hour,
            event.startTime.minute,
          );
          final eventEnd = DateTime(
            searchTime.year,
            searchTime.month,
            searchTime.day,
            event.endTime.hour,
            event.endTime.minute,
          );
          if (searchTime.isBefore(eventEnd) &&
              potentialEndTime.isAfter(eventStart)) {
            conflictsWithEvent = true;
            searchTime = eventEnd;
            break;
          }
        }
      }
      if (conflictsWithEvent) continue;

      bool conflictsWithTask = false;
      for (var task in allTasks.where((t) => t.scheduledTime != null)) {
        final taskEnd = task.scheduledTime!.add(task.estimatedDuration);
        if (searchTime.isBefore(taskEnd) &&
            potentialEndTime.isAfter(task.scheduledTime!)) {
          conflictsWithTask = true;
          searchTime = taskEnd;
          break;
        }
      }
      if (conflictsWithTask) continue;

      if (taskDifficulty == TaskDifficulty.hard) {
        final hardTasksToday = await _countHardTasksOnDate(searchTime);
        final maxHardTasks = await PreferencesHelper.getMaxHardTasksPerDay();

        if (hardTasksToday >= maxHardTasks) {
          searchTime = _getNextDayStart(
            searchTime.add(const Duration(days: 1)),
            dayStart,
          );
          continue;
        }
      }

      if (taskDifficulty == TaskDifficulty.hard &&
          peakWindow != PeakProductivityWindow.none) {
        if (_isDuringPeakWindow(searchTime, peakWindow)) {
          return searchTime;
        }

        if (deadline.difference(searchTime).inHours > 24) {
          searchTime = searchTime.add(const Duration(minutes: 15));
          continue;
        }

        return searchTime;
      }

      return searchTime;
    }

    return null;
  }

  bool _isDuringSleep(DateTime time, TimeOfDay sleepStart, TimeOfDay sleepEnd) {
    return PreferencesHelper.isDuringSleepTime(time, sleepStart, sleepEnd);
  }

  bool _isWithinWorkWindow(
    DateTime time,
    TimeOfDay dayStart,
    TimeOfDay dayEnd,
  ) {
    return PreferencesHelper.isWithinWorkWindow(time, dayStart, dayEnd);
  }

  bool _isDuringPeakWindow(DateTime time, PeakProductivityWindow window) {
    return PreferencesHelper.isDuringPeakWindow(time, window);
  }

  DateTime _getNextWakeTime(DateTime current, TimeOfDay wakeTime) {
    return PreferencesHelper.getNextWakeTime(current, wakeTime);
  }

  DateTime _getNextDayStart(DateTime current, TimeOfDay dayStart) {
    return PreferencesHelper.getNextDayStart(current, dayStart);
  }

  Future<int> _countHardTasksOnDate(DateTime date) async {
    final allTasks = await getAllTasks();
    return allTasks.where((task) {
      if (task.scheduledTime == null) return false;
      if (task.difficulty != TaskDifficulty.hard) return false;
      return task.scheduledTime!.year == date.year &&
          task.scheduledTime!.month == date.month &&
          task.scheduledTime!.day == date.day;
    }).length;
  }

  // ==================== EXISTING METHODS ====================

  Future<List<Task>> findSuggestedTasks(
    Duration availableDuration,
    TaskDifficulty focusLevel,
  ) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTasks,
      where: 'isComplete = ? AND difficulty = ? AND estimatedDuration <= ?',
      whereArgs: [0, focusLevel.index, availableDuration.inMinutes],
      orderBy: 'deadline ASC',
    );
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  Future<List<Task>> getIncompleteTasks() async {
    Database db = await instance.database;
    final now = DateTime.now();

    final List<Map<String, dynamic>> maps = await db.query(
      tableTasks,
      where: 'isComplete = 0 AND deadline < ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'deadline ASC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }
}
