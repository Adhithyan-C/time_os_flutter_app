// lib/helpers/task_splitter.dart

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

  TaskSplit({
    required this.sessionName,
    required this.duration,
    this.scheduledTime,
    required this.sessionNumber,
    required this.totalSessions,
  });
}

class TaskSplitter {
  /// Determines if a task should be split based on work block preference
  static bool shouldSplitTask(Duration taskDuration, int workBlockMinutes) {
    // Don't split if user has no preference
    if (workBlockMinutes == 0) return false;

    // Split if task is longer than preferred work block
    return taskDuration.inMinutes > workBlockMinutes;
  }

  /// Calculates optimal number of sessions for a task
  static int calculateOptimalSessions(
    Duration taskDuration,
    int workBlockMinutes,
  ) {
    if (workBlockMinutes == 0) return 1;

    final totalMinutes = taskDuration.inMinutes;

    // Calculate number of sessions needed
    final sessions = (totalMinutes / workBlockMinutes).ceil();

    // Ensure at least 1 session
    return sessions < 1 ? 1 : sessions;
  }

  /// Splits a task into multiple sessions
  static List<TaskSplit> splitTask(Task task, int workBlockMinutes) {
    if (workBlockMinutes == 0 ||
        !shouldSplitTask(task.estimatedDuration, workBlockMinutes)) {
      // Don't split - return as single session
      return [
        TaskSplit(
          sessionName: task.name,
          duration: task.estimatedDuration,
          sessionNumber: 1,
          totalSessions: 1,
        ),
      ];
    }

    final totalMinutes = task.estimatedDuration.inMinutes;
    final numSessions = calculateOptimalSessions(
      task.estimatedDuration,
      workBlockMinutes,
    );

    // Calculate duration per session (distributed evenly)
    final baseMinutesPerSession = totalMinutes ~/ numSessions;
    final remainderMinutes = totalMinutes % numSessions;

    List<TaskSplit> splits = [];

    for (int i = 0; i < numSessions; i++) {
      // Distribute remainder minutes across first sessions
      final sessionMinutes =
          baseMinutesPerSession + (i < remainderMinutes ? 1 : 0);

      splits.add(
        TaskSplit(
          sessionName: '${task.name} (Part ${i + 1}/${numSessions})',
          duration: Duration(minutes: sessionMinutes),
          sessionNumber: i + 1,
          totalSessions: numSessions,
        ),
      );
    }

    return splits;
  }

  /// Schedules all task sessions, respecting constraints
  static Future<List<TaskSplit>> scheduleTaskSessions({
    required Task task,
    required List<FixedEvent> fixedEvents,
    required List<Task> existingTasks,
  }) async {
    // Load user preferences
    final workBlockMinutes =
        await PreferencesHelper.getPreferredWorkBlockMinutes();
    final sleepStart = await PreferencesHelper.getSleepStartTime();
    final sleepEnd = await PreferencesHelper.getSleepEndTime();
    final dayStart = await PreferencesHelper.getDayStartTime();
    final dayEnd = await PreferencesHelper.getDayEndTime();
    final breakMinutes = await PreferencesHelper.getAutoBreakDuration();

    // Split the task
    final splits = splitTask(task, workBlockMinutes);

    // If task doesn't need splitting, return it
    if (splits.length == 1) {
      return splits;
    }

    // Schedule each session
    List<TaskSplit> scheduledSplits = [];
    DateTime searchStart = DateTime.now();

    for (var split in splits) {
      // Find next available slot for this session
      final slot = await _findSlotForSession(
        split: split,
        searchStart: searchStart,
        deadline: task.deadline,
        fixedEvents: fixedEvents,
        existingTasks: existingTasks,
        scheduledSplits: scheduledSplits,
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        dayStart: dayStart,
        dayEnd: dayEnd,
        breakMinutes: breakMinutes,
      );

      if (slot == null) {
        // Couldn't schedule all sessions before deadline
        return []; // Return empty to indicate failure
      }

      scheduledSplits.add(
        TaskSplit(
          sessionName: split.sessionName,
          duration: split.duration,
          scheduledTime: slot,
          sessionNumber: split.sessionNumber,
          totalSessions: split.totalSessions,
        ),
      );

      // Next session should start after this one (including break)
      searchStart = slot
          .add(split.duration)
          .add(Duration(minutes: breakMinutes));
    }

    return scheduledSplits;
  }

  /// Finds a free slot for a single task session
  static Future<DateTime?> _findSlotForSession({
    required TaskSplit split,
    required DateTime searchStart,
    required DateTime deadline,
    required List<FixedEvent> fixedEvents,
    required List<Task> existingTasks,
    required List<TaskSplit> scheduledSplits,
    required TimeOfDay sleepStart,
    required TimeOfDay sleepEnd,
    required TimeOfDay dayStart,
    required TimeOfDay dayEnd,
    required int breakMinutes,
  }) async {
    var searchTime = searchStart;

    while (searchTime.isBefore(deadline)) {
      var potentialEndTime = searchTime.add(split.duration);

      // Check if slot extends past deadline
      if (potentialEndTime.isAfter(deadline)) {
        return null; // Can't fit before deadline
      }

      // Skip if during sleep hours
      if (_isDuringSleep(searchTime, sleepStart, sleepEnd)) {
        searchTime = _getNextWakeTime(searchTime, sleepEnd);
        continue;
      }

      // Skip if outside work window
      if (!_isWithinWorkWindow(searchTime, dayStart, dayEnd)) {
        searchTime = _getNextDayStart(searchTime, dayStart);
        continue;
      }

      // Check conflicts with fixed events
      bool conflictsWithEvent = false;
      for (var event in fixedEvents) {
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

      // Check conflicts with existing tasks
      bool conflictsWithTask = false;
      for (var task in existingTasks.where((t) => t.scheduledTime != null)) {
        final taskEnd = task.scheduledTime!.add(task.estimatedDuration);
        if (searchTime.isBefore(taskEnd) &&
            potentialEndTime.isAfter(task.scheduledTime!)) {
          conflictsWithTask = true;
          searchTime = taskEnd.add(Duration(minutes: breakMinutes));
          break;
        }
      }
      if (conflictsWithTask) continue;

      // Check conflicts with already scheduled splits
      bool conflictsWithSplit = false;
      for (var scheduledSplit in scheduledSplits) {
        if (scheduledSplit.scheduledTime != null) {
          final splitEnd = scheduledSplit.scheduledTime!.add(
            scheduledSplit.duration,
          );
          if (searchTime.isBefore(splitEnd) &&
              potentialEndTime.isAfter(scheduledSplit.scheduledTime!)) {
            conflictsWithSplit = true;
            searchTime = splitEnd.add(Duration(minutes: breakMinutes));
            break;
          }
        }
      }
      if (conflictsWithSplit) continue;

      // Slot is free!
      return searchTime;
    }

    return null; // No slot found
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

  /// Creates actual Task objects from TaskSplits (for database storage)
  static List<Task> convertSplitsToTasks(
    Task originalTask,
    List<TaskSplit> scheduledSplits,
  ) {
    return scheduledSplits.map((split) {
      return Task(
        name: split.sessionName,
        details:
            '${originalTask.details}\n\n[Part ${split.sessionNumber}/${split.totalSessions} of: ${originalTask.name}]',
        estimatedDuration: split.duration,
        deadline: originalTask.deadline,
        difficulty: originalTask.difficulty,
        scheduledTime: split.scheduledTime,
        isComplete: false,
      );
    }).toList();
  }

  /// Preview how a task would be split (for UI display before confirming)
  static String getTaskSplitPreview(Task task, int workBlockMinutes) {
    if (!shouldSplitTask(task.estimatedDuration, workBlockMinutes)) {
      return 'This task will be scheduled as a single ${_formatDuration(task.estimatedDuration)} session.';
    }

    final splits = splitTask(task, workBlockMinutes);
    final buffer = StringBuffer();
    buffer.writeln('This task will be split into ${splits.length} sessions:');

    for (var split in splits) {
      buffer.writeln(
        '• Session ${split.sessionNumber}: ${_formatDuration(split.duration)}',
      );
    }

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
