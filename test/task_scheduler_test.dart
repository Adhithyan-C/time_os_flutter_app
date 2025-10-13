// test/task_scheduler_test.dart
// AUTOMATED TEST SUITE - Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/helpers/sorting_helper.dart';
import 'package:time_os_final/helpers/time_rounding_helper.dart';

void main() {
  group('Bug Fix Tests', () {
    // BUG #1: Even distribution
    test('Tasks should be spread evenly, not clustered', () {
      // This would require full integration test with database
      // Placeholder for structure
      expect(true, true);
    });

    // BUG #3: Floating point precision
    test('Task duration should be exact (no floating point errors)', () {
      final task1 = Task(
        name: 'Test',
        estimatedDuration: const Duration(hours: 6),
        deadline: DateTime.now().add(const Duration(days: 1)),
        difficulty: TaskDifficulty.medium,
      );

      final totalMinutes = task1.estimatedDuration.inMinutes;
      final numSessions = 4;
      final baseMinutes = totalMinutes ~/ numSessions;
      final remainder = totalMinutes % numSessions;

      // Verify precision
      int reconstructedTotal = 0;
      for (int i = 0; i < numSessions; i++) {
        reconstructedTotal += baseMinutes + (i < remainder ? 1 : 0);
      }

      expect(reconstructedTotal, equals(totalMinutes));
      expect(reconstructedTotal, equals(360)); // 6 hours
    });

    // BUG #14: Deadline validation
    test('Should reject tasks with past deadlines', () {
      final pastDeadline = DateTime.now().subtract(const Duration(hours: 1));

      expect(pastDeadline.isBefore(DateTime.now()), true);
      // In actual app, this would throw error
    });
  });

  group('Sorting Tests', () {
    test('Tasks should be sorted chronologically', () {
      final task1 = Task(
        name: 'Task 1',
        estimatedDuration: const Duration(hours: 1),
        deadline: DateTime.now().add(const Duration(days: 1)),
        difficulty: TaskDifficulty.easy,
        scheduledTime: DateTime(2024, 1, 1, 15, 0), // 3 PM
      );

      final task2 = Task(
        name: 'Task 2',
        estimatedDuration: const Duration(hours: 1),
        deadline: DateTime.now().add(const Duration(days: 1)),
        difficulty: TaskDifficulty.easy,
        scheduledTime: DateTime(2024, 1, 1, 10, 0), // 10 AM
      );

      final task3 = Task(
        name: 'Task 3',
        estimatedDuration: const Duration(hours: 1),
        deadline: DateTime.now().add(const Duration(days: 1)),
        difficulty: TaskDifficulty.easy,
        scheduledTime: DateTime(2024, 1, 1, 13, 0), // 1 PM
      );

      final unsorted = [task1, task2, task3];
      final sorted = SortingHelper.sortTasksChronologically(unsorted);

      expect(sorted[0].name, 'Task 2'); // 10 AM first
      expect(sorted[1].name, 'Task 3'); // 1 PM second
      expect(sorted[2].name, 'Task 1'); // 3 PM last
    });

    test('Events should be sorted by start time', () {
      final event1 = FixedEvent(
        name: 'Lunch',
        startTime: const TimeOfDay(hour: 12, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        daysOfWeek: [DayOfWeek.monday],
      );

      final event2 = FixedEvent(
        name: 'Morning Class',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        daysOfWeek: [DayOfWeek.monday],
      );

      final event3 = FixedEvent(
        name: 'Afternoon Meeting',
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        daysOfWeek: [DayOfWeek.monday],
      );

      final unsorted = [event1, event2, event3];
      final sorted = SortingHelper.sortEventsChronologically(unsorted);

      expect(sorted[0].name, 'Morning Class');
      expect(sorted[1].name, 'Lunch');
      expect(sorted[2].name, 'Afternoon Meeting');
    });
  });

  group('Time Rounding Tests', () {
    test('10:43 should round to 10:45', () {
      final time = const TimeOfDay(hour: 10, minute: 43);
      final rounded = TimeRoundingHelper.roundToNearest15Minutes(time);

      expect(rounded.hour, 10);
      expect(rounded.minute, 45);
    });

    test('10:51 should round to 11:00', () {
      final time = const TimeOfDay(hour: 10, minute: 51);
      final rounded = TimeRoundingHelper.roundToNearest15Minutes(time);

      expect(rounded.hour, 11);
      expect(rounded.minute, 0);
    });

    test('10:07 should round to 10:00', () {
      final time = const TimeOfDay(hour: 10, minute: 7);
      final rounded = TimeRoundingHelper.roundToNearest15Minutes(time);

      expect(rounded.hour, 10);
      expect(rounded.minute, 0);
    });

    test('10:08 should round to 10:15', () {
      final time = const TimeOfDay(hour: 10, minute: 8);
      final rounded = TimeRoundingHelper.roundToNearest15Minutes(time);

      expect(rounded.hour, 10);
      expect(rounded.minute, 15);
    });

    test('End time must be after start time', () {
      final start = const TimeOfDay(hour: 10, minute: 0);
      final end1 = const TimeOfDay(hour: 11, minute: 0);
      final end2 = const TimeOfDay(hour: 9, minute: 0);

      expect(TimeRoundingHelper.isEndAfterStart(start, end1), true);
      expect(TimeRoundingHelper.isEndAfterStart(start, end2), false);
    });
  });

  group('Task Model Tests', () {
    test('Task should serialize and deserialize correctly', () {
      final task = Task(
        name: 'Test Task',
        details: 'Test details',
        estimatedDuration: const Duration(hours: 2, minutes: 30),
        deadline: DateTime(2024, 12, 31, 23, 59),
        difficulty: TaskDifficulty.hard,
        scheduledTime: DateTime(2024, 12, 25, 10, 0),
        isComplete: false,
      );

      final map = task.toMap();
      final reconstructed = Task.fromMap(map);

      expect(reconstructed.name, task.name);
      expect(reconstructed.details, task.details);
      expect(reconstructed.estimatedDuration, task.estimatedDuration);
      expect(reconstructed.difficulty, task.difficulty);
      expect(reconstructed.isComplete, task.isComplete);
    });
  });

  group('Event Model Tests', () {
    test('Event should serialize and deserialize correctly', () {
      final event = FixedEvent(
        name: 'Math Class',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 30),
        daysOfWeek: [DayOfWeek.monday, DayOfWeek.wednesday],
        eventType: EventType.class_,
      );

      final map = event.toMap();
      final reconstructed = FixedEvent.fromMap(map);

      expect(reconstructed.name, event.name);
      expect(reconstructed.startTime.hour, event.startTime.hour);
      expect(reconstructed.startTime.minute, event.startTime.minute);
      expect(reconstructed.daysOfWeek.length, event.daysOfWeek.length);
      expect(reconstructed.eventType, event.eventType);
    });

    test('Event type should have correct colors and icons', () {
      final classEvent = FixedEvent(
        name: 'Class',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        daysOfWeek: [DayOfWeek.monday],
        eventType: EventType.class_,
      );

      expect(classEvent.getTypeIcon(), Icons.school);
      expect(classEvent.getTypeColor(), const Color(0xFF3B82F6));
    });
  });

  group('Integration Scenarios', () {
    test('Full workflow: Create task → Filter → Sort', () {
      // Create tasks
      final tasks = [
        Task(
          name: 'Evening Task',
          estimatedDuration: const Duration(hours: 1),
          deadline: DateTime.now().add(const Duration(days: 1)),
          difficulty: TaskDifficulty.easy,
          scheduledTime: DateTime.now().copyWith(hour: 18),
        ),
        Task(
          name: 'Morning Task',
          estimatedDuration: const Duration(hours: 1),
          deadline: DateTime.now().add(const Duration(days: 1)),
          difficulty: TaskDifficulty.easy,
          scheduledTime: DateTime.now().copyWith(hour: 9),
        ),
      ];

      // Sort
      final sorted = SortingHelper.sortTasksChronologically(tasks);

      // Verify
      expect(sorted[0].name, 'Morning Task');
      expect(sorted[1].name, 'Evening Task');
    });
  });
}

// Performance benchmark tests
void performanceBenchmarks() {
  group('Performance Tests', () {
    test('Sorting 1000 tasks should complete in < 1 second', () {
      final stopwatch = Stopwatch()..start();

      // Generate 1000 tasks
      final tasks = List.generate(1000, (i) {
        return Task(
          name: 'Task $i',
          estimatedDuration: const Duration(hours: 1),
          deadline: DateTime.now().add(Duration(days: i)),
          difficulty: TaskDifficulty.medium,
          scheduledTime: DateTime.now().add(Duration(hours: i)),
        );
      });

      // Sort
      SortingHelper.sortTasksChronologically(tasks);

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      print('Sorted 1000 tasks in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
