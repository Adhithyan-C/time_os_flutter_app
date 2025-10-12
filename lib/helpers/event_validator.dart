// lib/helpers/event_validator.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/models/event_model.dart';

class EventConflict {
  final FixedEvent event1;
  final FixedEvent event2;
  final DayOfWeek conflictDay;
  final String message;

  EventConflict({
    required this.event1,
    required this.event2,
    required this.conflictDay,
    required this.message,
  });
}

class EventValidator {
  /// Validates a single event's basic properties
  static String? validateEvent(FixedEvent event) {
    // Check if name is empty
    if (event.name.trim().isEmpty) {
      return 'Event name cannot be empty';
    }

    // Check if at least one day is selected
    if (event.daysOfWeek.isEmpty) {
      return 'Please select at least one day';
    }

    // Check if end time is after start time
    final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
    final endMinutes = event.endTime.hour * 60 + event.endTime.minute;

    if (endMinutes <= startMinutes) {
      return 'End time must be after start time';
    }

    // Check if duration is reasonable (not too short or too long)
    final durationMinutes = endMinutes - startMinutes;
    if (durationMinutes < 15) {
      return 'Event must be at least 15 minutes long';
    }
    if (durationMinutes > 12 * 60) {
      return 'Event cannot exceed 12 hours';
    }

    return null; // No errors
  }

  /// Checks if two events overlap on a specific day
  static bool eventsOverlapOnDay(
    FixedEvent event1,
    FixedEvent event2,
    DayOfWeek day,
  ) {
    // Check if both events occur on this day
    if (!event1.daysOfWeek.contains(day) || !event2.daysOfWeek.contains(day)) {
      return false;
    }

    final start1 = event1.startTime.hour * 60 + event1.startTime.minute;
    final end1 = event1.endTime.hour * 60 + event1.endTime.minute;
    final start2 = event2.startTime.hour * 60 + event2.startTime.minute;
    final end2 = event2.endTime.hour * 60 + event2.endTime.minute;

    // Check for overlap: start1 < end2 AND start2 < end1
    return start1 < end2 && start2 < end1;
  }

  /// Finds all conflicts between a new event and existing events
  static List<EventConflict> findConflicts(
    FixedEvent newEvent,
    List<FixedEvent> existingEvents,
  ) {
    List<EventConflict> conflicts = [];

    for (var existingEvent in existingEvents) {
      // Skip if comparing with itself (when editing)
      if (newEvent.id != null && newEvent.id == existingEvent.id) {
        continue;
      }

      // Check each day for conflicts
      for (var day in newEvent.daysOfWeek) {
        if (eventsOverlapOnDay(newEvent, existingEvent, day)) {
          final dayName = _getDayName(day);
          conflicts.add(
            EventConflict(
              event1: newEvent,
              event2: existingEvent,
              conflictDay: day,
              message: 'Conflicts with "${existingEvent.name}" on $dayName',
            ),
          );
        }
      }
    }

    return conflicts;
  }

  /// Checks if event name is duplicate (on same days)
  static bool isDuplicateName(
    FixedEvent newEvent,
    List<FixedEvent> existingEvents,
  ) {
    for (var existing in existingEvents) {
      // Skip if editing the same event
      if (newEvent.id != null && newEvent.id == existing.id) {
        continue;
      }

      // Check if names match (case-insensitive)
      if (newEvent.name.trim().toLowerCase() ==
          existing.name.trim().toLowerCase()) {
        // Check if they share any days
        final sharedDays = newEvent.daysOfWeek
            .where((day) => existing.daysOfWeek.contains(day))
            .toList();

        if (sharedDays.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  /// Suggests a fix for overlapping events
  static FixedEvent? suggestFix(EventConflict conflict) {
    // Calculate the overlap duration
    final start1 =
        conflict.event1.startTime.hour * 60 + conflict.event1.startTime.minute;
    final end1 =
        conflict.event1.endTime.hour * 60 + conflict.event1.endTime.minute;
    final start2 =
        conflict.event2.startTime.hour * 60 + conflict.event2.startTime.minute;
    final end2 =
        conflict.event2.endTime.hour * 60 + conflict.event2.endTime.minute;

    // If event1 starts before event2, end it when event2 starts
    if (start1 < start2) {
      return FixedEvent(
        id: conflict.event1.id,
        name: conflict.event1.name,
        startTime: conflict.event1.startTime,
        endTime: TimeOfDay(hour: start2 ~/ 60, minute: start2 % 60),
        daysOfWeek: conflict.event1.daysOfWeek,
        eventType: conflict.event1.eventType,
      );
    }

    // If event1 starts after event2, start it when event2 ends
    if (start1 >= start2 && start1 < end2) {
      return FixedEvent(
        id: conflict.event1.id,
        name: conflict.event1.name,
        startTime: TimeOfDay(hour: end2 ~/ 60, minute: end2 % 60),
        endTime: conflict.event1.endTime,
        daysOfWeek: conflict.event1.daysOfWeek,
        eventType: conflict.event1.eventType,
      );
    }

    return null; // Cannot suggest automatic fix
  }

  /// Generates a detailed conflict report
  /// Generates a detailed conflict report
  static String generateConflictReport(List<EventConflict> conflicts) {
    if (conflicts.isEmpty) return 'No conflicts found';

    final buffer = StringBuffer();
    buffer.writeln('Found ${conflicts.length} conflict(s):');

    for (var i = 0; i < conflicts.length; i++) {
      final conflict = conflicts[i];
      buffer.writeln('${i + 1}. ${conflict.message}');

      // Use custom time formatting instead of format()
      final start1 = _formatTime(conflict.event1.startTime);
      final end1 = _formatTime(conflict.event1.endTime);
      final start2 = _formatTime(conflict.event2.startTime);
      final end2 = _formatTime(conflict.event2.endTime);

      buffer.writeln('   "${conflict.event1.name}": $start1 - $end1');
      buffer.writeln('   "${conflict.event2.name}": $start2 - $end2');
    }

    return buffer.toString();
  }

  // Helper method for formatting time without context
  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Validates all events in the list for internal consistency
  static Map<String, List<String>> validateEventList(List<FixedEvent> events) {
    Map<String, List<String>> issues = {};

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      List<String> eventIssues = [];

      // Check basic validation
      final basicError = validateEvent(event);
      if (basicError != null) {
        eventIssues.add(basicError);
      }

      // Check for conflicts with other events
      for (var j = i + 1; j < events.length; j++) {
        final otherEvent = events[j];
        for (var day in event.daysOfWeek) {
          if (eventsOverlapOnDay(event, otherEvent, day)) {
            eventIssues.add(
              'Overlaps with "${otherEvent.name}" on ${_getDayName(day)}',
            );
          }
        }
      }

      if (eventIssues.isNotEmpty) {
        issues[event.name] = eventIssues;
      }
    }

    return issues;
  }

  /// Helper: Get readable day name
  static String _getDayName(DayOfWeek day) {
    return day.name[0].toUpperCase() + day.name.substring(1);
  }

  /// Helper: Format time range for display
  static String formatTimeRange(TimeOfDay start, TimeOfDay end) {
    return '${_formatTime(start)} - ${_formatTime(end)}';
  }

  /// Advanced: Check if adding this event would create scheduling issues
  static bool wouldCauseSchedulingIssues(
    FixedEvent newEvent,
    List<FixedEvent> existingEvents,
  ) {
    // Calculate total blocked time per day
    Map<DayOfWeek, int> blockedMinutesPerDay = {};

    for (var day in DayOfWeek.values) {
      int totalMinutes = 0;

      // Add existing events
      for (var event in existingEvents) {
        if (event.daysOfWeek.contains(day)) {
          final duration =
              (event.endTime.hour * 60 + event.endTime.minute) -
              (event.startTime.hour * 60 + event.startTime.minute);
          totalMinutes += duration;
        }
      }

      // Add new event
      if (newEvent.daysOfWeek.contains(day)) {
        final duration =
            (newEvent.endTime.hour * 60 + newEvent.endTime.minute) -
            (newEvent.startTime.hour * 60 + newEvent.startTime.minute);
        totalMinutes += duration;
      }

      blockedMinutesPerDay[day] = totalMinutes;
    }

    // Warn if any day has more than 16 hours blocked
    return blockedMinutesPerDay.values.any((minutes) => minutes > 16 * 60);
  }
}
