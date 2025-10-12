// lib/helpers/preferences_helper.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum PeakProductivityWindow { morning, afternoon, evening, none }

class PreferencesHelper {
  static const String _userName = 'userName';
  static const String _hasOnboarded = 'hasOnboarded';

  // Sleep Schedule
  static const String _sleepStartTime = 'sleepStartTime';
  static const String _sleepEndTime = 'sleepEndTime';

  // Daily Work Window
  static const String _dayStartTime = 'dayStartTime';
  static const String _dayEndTime = 'dayEndTime';

  // Productivity Preferences
  static const String _peakProductivityWindow = 'peakProductivityWindow';
  static const String _preferredWorkBlockMinutes = 'preferredWorkBlockMinutes';
  static const String _autoBreakDuration = 'autoBreakDuration';
  static const String _maxHardTasksPerDay = 'maxHardTasksPerDay';

  // Notifications
  static const String _notificationEnabled = 'notificationEnabled';
  static const String _notificationAdvanceMinutes =
      'notificationAdvanceMinutes';

  // ==================== GETTERS ====================

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userName) ?? 'User';
  }

  static Future<bool> hasOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasOnboarded) ?? false;
  }

  static Future<TimeOfDay> getSleepStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseTimeOfDay(prefs.getString(_sleepStartTime) ?? '23:00');
  }

  static Future<TimeOfDay> getSleepEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseTimeOfDay(prefs.getString(_sleepEndTime) ?? '07:00');
  }

  static Future<TimeOfDay> getDayStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseTimeOfDay(prefs.getString(_dayStartTime) ?? '09:00');
  }

  static Future<TimeOfDay> getDayEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseTimeOfDay(prefs.getString(_dayEndTime) ?? '22:00');
  }

  static Future<PeakProductivityWindow> getPeakProductivityWindow() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_peakProductivityWindow) ?? 'none';
    return PeakProductivityWindow.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PeakProductivityWindow.none,
    );
  }

  static Future<int> getPreferredWorkBlockMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_preferredWorkBlockMinutes) ?? 0;
  }

  static Future<int> getAutoBreakDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoBreakDuration) ?? 0;
  }

  static Future<int> getMaxHardTasksPerDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxHardTasksPerDay) ?? 3;
  }

  static Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabled) ?? false;
  }

  static Future<int> getNotificationAdvanceMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_notificationAdvanceMinutes) ?? 15;
  }

  // ==================== SETTERS ====================

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userName, name);
  }

  static Future<void> setHasOnboarded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasOnboarded, value);
  }

  static Future<void> setSleepSchedule(TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sleepStartTime, _formatTimeOfDay(start));
    await prefs.setString(_sleepEndTime, _formatTimeOfDay(end));
  }

  static Future<void> setDayWindow(TimeOfDay start, TimeOfDay end) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dayStartTime, _formatTimeOfDay(start));
    await prefs.setString(_dayEndTime, _formatTimeOfDay(end));
  }

  static Future<void> setPeakProductivityWindow(
    PeakProductivityWindow window,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_peakProductivityWindow, window.name);
  }

  static Future<void> setPreferredWorkBlockMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_preferredWorkBlockMinutes, minutes);
  }

  static Future<void> setAutoBreakDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoBreakDuration, minutes);
  }

  static Future<void> setMaxHardTasksPerDay(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maxHardTasksPerDay, count);
  }

  static Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabled, enabled);
  }

  static Future<void> setNotificationAdvanceMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_notificationAdvanceMinutes, minutes);
  }

  // ==================== UTILITY METHODS ====================

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Calculate sleep duration in hours
  static Duration calculateSleepDuration(TimeOfDay start, TimeOfDay end) {
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;

    // Handle overnight sleep (e.g., 11 PM to 7 AM)
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60; // Add 24 hours
    }

    return Duration(minutes: endMinutes - startMinutes);
  }

  // Check if a DateTime falls within sleep hours
  static bool isDuringSleepTime(
    DateTime time,
    TimeOfDay sleepStart,
    TimeOfDay sleepEnd,
  ) {
    final currentMinutes = time.hour * 60 + time.minute;
    final sleepStartMinutes = sleepStart.hour * 60 + sleepStart.minute;
    final sleepEndMinutes = sleepEnd.hour * 60 + sleepEnd.minute;

    if (sleepEndMinutes <= sleepStartMinutes) {
      // Overnight sleep
      return currentMinutes >= sleepStartMinutes ||
          currentMinutes < sleepEndMinutes;
    } else {
      // Same-day sleep (unusual but supported)
      return currentMinutes >= sleepStartMinutes &&
          currentMinutes < sleepEndMinutes;
    }
  }

  // Check if time is within work window
  static bool isWithinWorkWindow(
    DateTime time,
    TimeOfDay dayStart,
    TimeOfDay dayEnd,
  ) {
    final currentMinutes = time.hour * 60 + time.minute;
    final dayStartMinutes = dayStart.hour * 60 + dayStart.minute;
    final dayEndMinutes = dayEnd.hour * 60 + dayEnd.minute;

    return currentMinutes >= dayStartMinutes && currentMinutes < dayEndMinutes;
  }

  // Check if time is during peak productivity window
  static bool isDuringPeakWindow(DateTime time, PeakProductivityWindow window) {
    final hour = time.hour;

    switch (window) {
      case PeakProductivityWindow.morning:
        return hour >= 6 && hour < 12;
      case PeakProductivityWindow.afternoon:
        return hour >= 12 && hour < 18;
      case PeakProductivityWindow.evening:
        return hour >= 18 && hour < 24;
      case PeakProductivityWindow.none:
        return true; // No preference
    }
  }

  // Get next wake time from current time
  static DateTime getNextWakeTime(DateTime current, TimeOfDay wakeTime) {
    DateTime nextWake = DateTime(
      current.year,
      current.month,
      current.day,
      wakeTime.hour,
      wakeTime.minute,
    );

    if (nextWake.isBefore(current)) {
      nextWake = nextWake.add(const Duration(days: 1));
    }

    return nextWake;
  }

  // Get next day start time
  static DateTime getNextDayStart(DateTime current, TimeOfDay dayStart) {
    DateTime nextStart = DateTime(
      current.year,
      current.month,
      current.day,
      dayStart.hour,
      dayStart.minute,
    );

    if (nextStart.isBefore(current)) {
      nextStart = nextStart.add(const Duration(days: 1));
    }

    return nextStart;
  }
}
