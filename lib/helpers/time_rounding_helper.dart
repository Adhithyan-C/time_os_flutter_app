// lib/helpers/time_rounding_helper.dart

import 'package:flutter/material.dart';

class TimeRoundingHelper {
  /// Rounds a TimeOfDay to the nearest 15-minute interval
  /// Examples:
  /// - 10:43 → 10:45
  /// - 10:51 → 11:00
  /// - 10:07 → 10:00
  /// - 10:08 → 10:15
  static TimeOfDay roundToNearest15Minutes(TimeOfDay time) {
    final totalMinutes = time.hour * 60 + time.minute;

    // Round to nearest 15-minute interval
    final remainder = totalMinutes % 15;
    final roundedMinutes = remainder < 8
        ? totalMinutes -
              remainder // Round down
        : totalMinutes + (15 - remainder); // Round up

    // Calculate new hour and minute
    final newHour = (roundedMinutes ~/ 60) % 24;
    final newMinute = roundedMinutes % 60;

    return TimeOfDay(hour: newHour, minute: newMinute);
  }

  /// Check if end time is after start time
  static bool isEndAfterStart(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes > startMinutes;
  }

  /// Get duration between two times in minutes
  static int getDurationInMinutes(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes - startMinutes;
  }

  /// Format time for display
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
