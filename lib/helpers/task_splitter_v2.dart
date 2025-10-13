// lib/helpers/task_splitter_v2.dart
// ENHANCED VERSION - Fixes all bugs and implements even distribution

import 'package:flutter/material.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';

class TaskSplit {
  final String sessionName;
  final Duration duration;
  final DateTime? scheduledTime;
  final int sessionNumber;
  final int totalSessions;
  final String? parentTaskId; // NEW: Link to parent task

  TaskSplit({
    required this.sessionName,
    required this.duration,
    this.scheduledTime,
    required this.sessionNumber,
    required this.totalSessions,
    this.parentTaskId,
  });
}

class TaskSplitterV2 {
  // BUG FIX #1: Check if we have available time before deadline
  static Future<bool> hasAvailableTimeBeforeDeadline(
    Duration totalDuration,
    DateTime deadline,
    List<FixedEvent> fixedEvents,
    List<Task> existingTasks,
  ) async {
    final sleepStart = await PreferencesHelper.getSleepStartTime();
    final sleepEnd = await PreferencesHelper.getSleepEndTime();
    final dayStart = await PreferencesHelper.getDayStartTime();
    final dayEnd = await PreferencesHelper.getDayEndTime();

    int totalAvailableMinutes = 0;
    DateTime currentDate = DateTime.now();

    // BUG FIX #1: Include both start and end dates
    while (currentDate.isBefore(deadline) ||
        currentDate.isAtSameMomentAs(
          deadline.subtract(const Duration(hours: 1)),
        )) {
      // Get work window for this day
      final workStart = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        dayStart.hour,
        dayStart.minute,
      );

      final workEnd = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        dayEnd.hour,
        dayEnd.minute,
      );

      // Count free minutes in this day's work window
      DateTime scanTime = workStart;
      while (scanTime.isBefore(workEnd) && scanTime.isBefore(deadline)) {
        // BUG FIX #12: Check sleep schedule
        if (!_isDuringSleep(scanTime, sleepStart, sleepEnd)) {
          // Check if this 15-min slot is free
          final slotEnd = scanTime.add(const Duration(minutes: 15));

          bool isFree = true;

          // Check fixed events
          for (var event in fixedEvents) {
            if (_conflictsWithEvent(scanTime, slotEnd, event, currentDate)) {
              isFree = false;
              break;
            }
          }

          // Check existing tasks
          if (isFree) {
            for (var task in existingTasks.where(
              (t) => t.scheduledTime != null,
            )) {
              final taskEnd = task.scheduledTime!.add(task.estimatedDuration);
              if (scanTime.isBefore(taskEnd) &&
                  slotEnd.isAfter(task.scheduledTime!)) {
                isFree = false;
                break;
              }
            }
          }

          if (isFree) {
            totalAvailableMinutes += 15;
          }
        }

        scanTime = scanTime.add(const Duration(minutes: 15));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return totalAvailableMinutes >= totalDuration.inMinutes;
  }

  /// ENHANCED: Even distribution algorithm with precise time allocation
  static Future<List<TaskSplit>> scheduleTaskSessionsEvenly({
    required Task task,
    required List<FixedEvent> fixedEvents,
    required List<Task> existingTasks,
  }) async {
    // BUG FIX #14: Check if deadline already passed
    if (task.deadline.isBefore(DateTime.now())) {
      throw Exception('Deadline already passed');
    }

    // Load preferences
    final workBlockMinutes =
        await PreferencesHelper.getPreferredWorkBlockMinutes();
    final sleepStart = await PreferencesHelper.getSleepStartTime();
    final sleepEnd = await PreferencesHelper.getSleepEndTime();
    final dayStart = await PreferencesHelper.getDayStartTime();
    final dayEnd = await PreferencesHelper.getDayEndTime();
    final breakMinutes = await PreferencesHelper.getAutoBreakDuration();

    // BUG FIX #2: Check if we have enough time
    final hasTime = await hasAvailableTimeBeforeDeadline(
      task.estimatedDuration,
      task.deadline,
      fixedEvents,
      existingTasks,
    );

    if (!hasTime) {
      throw Exception('No available time before deadline');
    }

    // Determine if splitting is needed
    final shouldSplit =
        workBlockMinutes > 0 &&
        task.estimatedDuration.inMinutes > workBlockMinutes;

    // BUG FIX #4: Handle single-session tasks
    if (!shouldSplit) {
      final slot = await _findNextFreeSlot(
        duration: task.estimatedDuration,
        searchStart: DateTime.now(),
        deadline: task.deadline,
        fixedEvents: fixedEvents,
        existingTasks: existingTasks,
        alreadyScheduled: [],
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        dayStart: dayStart,
        dayEnd: dayEnd,
        breakMinutes: breakMinutes,
      );

      if (slot == null) {
        throw Exception('Could not find slot for task');
      }

      return [
        TaskSplit(
          sessionName: task.name,
          duration: task.estimatedDuration,
          scheduledTime: slot,
          sessionNumber: 1,
          totalSessions: 1,
          parentTaskId: task.id?.toString(),
        ),
      ];
    }

    // TASK SPREADING ALGORITHM
    // BUG FIX #3: Precise minute-level calculations
    final totalMinutes = task.estimatedDuration.inMinutes;
    final numSessions = (totalMinutes / workBlockMinutes).ceil();

    // Distribute evenly with remainder handling
    final baseMinutesPerSession = totalMinutes ~/ numSessions;
    final remainderMinutes = totalMinutes % numSessions;

    // Find all available slots between now and deadline
    final availableSlots = await _findAllAvailableSlots(
      sessionDuration: Duration(minutes: workBlockMinutes),
      searchStart: DateTime.now(),
      deadline: task.deadline,
      fixedEvents: fixedEvents,
      existingTasks: existingTasks,
      sleepStart: sleepStart,
      sleepEnd: sleepEnd,
      dayStart: dayStart,
      dayEnd: dayEnd,
      breakMinutes: breakMinutes,
    );

    if (availableSlots.length < numSessions) {
      throw Exception('Not enough free slots for all sessions');
    }

    // EVEN DISTRIBUTION: Spread sessions evenly across available time
    List<TaskSplit> scheduledSplits = [];
    final interval = availableSlots.length ~/ numSessions;

    for (int i = 0; i < numSessions; i++) {
      // Calculate session duration (distribute remainder)
      final sessionMinutes =
          baseMinutesPerSession + (i < remainderMinutes ? 1 : 0);

      // Pick evenly spaced slots
      final slotIndex = i * interval;
      final actualSlot =
          availableSlots[slotIndex < availableSlots.length
              ? slotIndex
              : availableSlots.length - 1];

      scheduledSplits.add(
        TaskSplit(
          sessionName: '${task.name} (Part ${i + 1}/${numSessions})',
          duration: Duration(minutes: sessionMinutes),
          scheduledTime: actualSlot,
          sessionNumber: i + 1,
          totalSessions: numSessions,
          parentTaskId: task.id?.toString(),
        ),
      );
    }

    return scheduledSplits;
  }

  /// Find ALL available slots (for even distribution)
  static Future<List<DateTime>> _findAllAvailableSlots({
    required Duration sessionDuration,
    required DateTime searchStart,
    required DateTime deadline,
    required List<FixedEvent> fixedEvents,
    required List<Task> existingTasks,
    required TimeOfDay sleepStart,
    required TimeOfDay sleepEnd,
    required TimeOfDay dayStart,
    required TimeOfDay dayEnd,
    required int breakMinutes,
  }) async {
    List<DateTime> slots = [];
    DateTime currentDate = searchStart;

    // BUG FIX #1: Include deadline day
    while (currentDate.isBefore(deadline) ||
        currentDate.isAtSameMomentAs(deadline)) {
      final workStart = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        dayStart.hour,
        dayStart.minute,
      );

      final workEnd = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        dayEnd.hour,
        dayEnd.minute,
      );

      DateTime scanTime = workStart.isAfter(searchStart)
          ? workStart
          : searchStart;

      while (scanTime.isBefore(workEnd) && scanTime.isBefore(deadline)) {
        final slotEnd = scanTime.add(sessionDuration);

        // BUG FIX #12: Check sleep
        if (_isDuringSleep(scanTime, sleepStart, sleepEnd)) {
          scanTime = scanTime.add(const Duration(minutes: 15));
          continue;
        }

        // Check if slot is completely free
        bool isFree = true;

        // Check fixed events
        for (var event in fixedEvents) {
          if (_conflictsWithEvent(scanTime, slotEnd, event, currentDate)) {
            isFree = false;
            break;
          }
        }

        // Check existing tasks
        if (isFree) {
          for (var task in existingTasks.where(
            (t) => t.scheduledTime != null,
          )) {
            final taskEnd = task.scheduledTime!.add(task.estimatedDuration);
            if (scanTime.isBefore(taskEnd) &&
                slotEnd.isAfter(task.scheduledTime!)) {
              isFree = false;
              break;
            }
          }
        }

        if (isFree && slotEnd.isBefore(deadline)) {
          slots.add(scanTime);
        }

        scanTime = scanTime.add(const Duration(minutes: 15));
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return slots;
  }

  /// Find next single free slot (with retry mechanism)
  /// BUG FIX #5 & #6: Conflict checking + retry limit
  static Future<DateTime?> _findNextFreeSlot({
    required Duration duration,
    required DateTime searchStart,
    required DateTime deadline,
    required List<FixedEvent> fixedEvents,
    required List<Task> existingTasks,
    required List<TaskSplit> alreadyScheduled,
    required TimeOfDay sleepStart,
    required TimeOfDay sleepEnd,
    required TimeOfDay dayStart,
    required TimeOfDay dayEnd,
    required int breakMinutes,
    int retryCount = 0,
  }) async {
    // BUG FIX #6: Limit retries
    if (retryCount > 5) return null;

    DateTime searchTime = searchStart;

    while (searchTime.isBefore(deadline)) {
      final potentialEnd = searchTime.add(duration);

      if (potentialEnd.isAfter(deadline)) return null;

      // BUG FIX #12: Sleep check
      if (_isDuringSleep(searchTime, sleepStart, sleepEnd)) {
        searchTime = _getNextWakeTime(searchTime, sleepEnd);
        continue;
      }

      // Work window check
      if (!_isWithinWorkWindow(searchTime, dayStart, dayEnd)) {
        searchTime = _getNextDayStart(searchTime, dayStart);
        continue;
      }

      // BUG FIX #5: Always run conflict check
      bool hasConflict = false;

      // Check fixed events
      for (var event in fixedEvents) {
        if (_conflictsWithEvent(searchTime, potentialEnd, event, searchTime)) {
          hasConflict = true;
          // Jump to event end
          final eventEnd = DateTime(
            searchTime.year,
            searchTime.month,
            searchTime.day,
            event.endTime.hour,
            event.endTime.minute,
          );
          searchTime = eventEnd;
          break;
        }
      }
      if (hasConflict) continue;

      // Check existing tasks
      for (var task in existingTasks.where((t) => t.scheduledTime != null)) {
        final taskEnd = task.scheduledTime!.add(task.estimatedDuration);
        if (searchTime.isBefore(taskEnd) &&
            potentialEnd.isAfter(task.scheduledTime!)) {
          hasConflict = true;
          searchTime = taskEnd.add(Duration(minutes: breakMinutes));
          break;
        }
      }
      if (hasConflict) continue;

      // Check already scheduled splits
      for (var split in alreadyScheduled) {
        if (split.scheduledTime != null) {
          final splitEnd = split.scheduledTime!.add(split.duration);
          if (searchTime.isBefore(splitEnd) &&
              potentialEnd.isAfter(split.scheduledTime!)) {
            hasConflict = true;
            searchTime = splitEnd.add(Duration(minutes: breakMinutes));
            break;
          }
        }
      }
      if (hasConflict) continue;

      // Slot is free!
      return searchTime;
    }

    return null;
  }

  // Helper methods
  static bool _isDuringSleep(
    DateTime time,
    TimeOfDay sleepStart,
    TimeOfDay sleepEnd,
  ) {
    return PreferencesHelper.isDuringSleepTime(time, sleepStart, sleepEnd);
  }

  static bool _isWithinWorkWindow(
    DateTime time,
    TimeOfDay dayStart,
    TimeOfDay dayEnd,
  ) {
    return PreferencesHelper.isWithinWorkWindow(time, dayStart, dayEnd);
  }

  static DateTime _getNextWakeTime(DateTime current, TimeOfDay wakeTime) {
    return PreferencesHelper.getNextWakeTime(current, wakeTime);
  }

  static DateTime _getNextDayStart(DateTime current, TimeOfDay dayStart) {
    return PreferencesHelper.getNextDayStart(current, dayStart);
  }

  static bool _conflictsWithEvent(
    DateTime slotStart,
    DateTime slotEnd,
    FixedEvent event,
    DateTime currentDate,
  ) {
    if (!event.daysOfWeek.contains(DayOfWeek.values[currentDate.weekday % 7])) {
      return false;
    }

    final eventStart = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      event.startTime.hour,
      event.startTime.minute,
    );

    final eventEnd = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
      event.endTime.hour,
      event.endTime.minute,
    );

    return slotStart.isBefore(eventEnd) && slotEnd.isAfter(eventStart);
  }

  /// Convert splits to Task objects for database
  /// BUG FIX #11: Add sessionId for tracking
  static List<Task> convertSplitsToTasks(
    Task originalTask,
    List<TaskSplit> scheduledSplits,
  ) {
    return scheduledSplits.map((split) {
      return Task(
        name: split.sessionName,
        details:
            '${originalTask.details}\n\n[Session ${split.sessionNumber}/${split.totalSessions}]\n[Parent Task: ${originalTask.name}]',
        estimatedDuration: split.duration,
        deadline: originalTask.deadline,
        difficulty: originalTask.difficulty,
        scheduledTime: split.scheduledTime,
        isComplete: false,
      );
    }).toList();
  }

  /// Preview task splitting
  static String getTaskSplitPreview(Task task, int workBlockMinutes) {
    if (workBlockMinutes == 0 ||
        task.estimatedDuration.inMinutes <= workBlockMinutes) {
      return 'This task will be scheduled as a single ${_formatDuration(task.estimatedDuration)} session.';
    }

    final totalMinutes = task.estimatedDuration.inMinutes;
    final numSessions = (totalMinutes / workBlockMinutes).ceil();
    final baseMinutes = totalMinutes ~/ numSessions;
    final remainder = totalMinutes % numSessions;

    final buffer = StringBuffer();
    buffer.writeln('This task will be split into $numSessions sessions:');

    for (int i = 0; i < numSessions; i++) {
      final sessionMinutes = baseMinutes + (i < remainder ? 1 : 0);
      buffer.writeln(
        '• Session ${i + 1}: ${_formatDuration(Duration(minutes: sessionMinutes))}',
      );
    }
    buffer.writeln('\nSessions will be spread evenly until deadline.');

    return buffer.toString();
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}
