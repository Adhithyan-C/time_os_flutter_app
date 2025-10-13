// lib/helpers/dynamic_rescheduler.dart
// IMPLEMENTS: EDF (Earliest Deadline First) + Task Spreading Hybrid
// BUG FIX #7: Handles event changes and orphaned tasks

import 'package:flutter/material.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';
import 'package:time_os_final/helpers/task_splitter_v2.dart';

class TaskPriority {
  final Task task;
  final double priority;
  final double laxity; // Deadline - Current Time - Remaining Work

  TaskPriority({
    required this.task,
    required this.priority,
    required this.laxity,
  });
}

class DynamicRescheduler {
  /// Main rescheduling function - called when schedule changes
  /// Uses EDF (Earliest Deadline First) + Weighted Priority
  static Future<List<Task>> rescheduleAllTasks({
    required List<Task> incompleteTasks,
    required List<FixedEvent> fixedEvents,
    required List<Task> completedTasks,
  }) async {
    // Step 1: Calculate priorities for all incomplete tasks
    final prioritizedTasks = await _calculatePriorities(incompleteTasks);

    // Step 2: Sort by priority (EDF + Laxity)
    prioritizedTasks.sort((a, b) => b.priority.compareTo(a.priority));

    // Step 3: Reschedule tasks in priority order
    List<Task> rescheduledTasks = [];
    List<Task> alreadyRescheduled = List.from(completedTasks);

    for (var taskPriority in prioritizedTasks) {
      final task = taskPriority.task;

      try {
        // BUG FIX #14: Skip if deadline passed
        if (task.deadline.isBefore(DateTime.now())) {
          // Mark as needs manual adjustment
          final updatedTask = Task(
            id: task.id,
            name: '⚠️ ${task.name}',
            details:
                '${task.details}\n\n[ATTENTION: Deadline passed - needs manual review]',
            estimatedDuration: task.estimatedDuration,
            deadline: task.deadline,
            difficulty: task.difficulty,
            scheduledTime: null,
            isComplete: false,
          );
          rescheduledTasks.add(updatedTask);
          continue;
        }

        // Use V2 splitter for rescheduling
        final scheduledSplits = await TaskSplitterV2.scheduleTaskSessionsEvenly(
          task: task,
          fixedEvents: fixedEvents,
          existingTasks: alreadyRescheduled,
        );

        if (scheduledSplits.isEmpty) {
          // Could not reschedule - mark for manual attention
          final updatedTask = Task(
            id: task.id,
            name: '❗ ${task.name}',
            details:
                '${task.details}\n\n[ATTENTION: Could not auto-reschedule - needs manual adjustment]',
            estimatedDuration: task.estimatedDuration,
            deadline: task.deadline,
            difficulty: task.difficulty,
            scheduledTime: null,
            isComplete: false,
          );
          rescheduledTasks.add(updatedTask);
          continue;
        }

        // Convert splits to tasks
        final newTasks = TaskSplitterV2.convertSplitsToTasks(
          task,
          scheduledSplits,
        );
        rescheduledTasks.addAll(newTasks);
        alreadyRescheduled.addAll(newTasks);
      } catch (e) {
        // BUG FIX #6: Handle rescheduling errors
        final updatedTask = Task(
          id: task.id,
          name: '⚠️ ${task.name}',
          details: '${task.details}\n\n[ERROR: ${e.toString()}]',
          estimatedDuration: task.estimatedDuration,
          deadline: task.deadline,
          difficulty: task.difficulty,
          scheduledTime: null,
          isComplete: false,
        );
        rescheduledTasks.add(updatedTask);
      }
    }

    return rescheduledTasks;
  }

  /// Calculate priority using weighted formula
  /// Priority = (Urgency * DeadlineWeight) / Workload
  static Future<List<TaskPriority>> _calculatePriorities(
    List<Task> tasks,
  ) async {
    List<TaskPriority> priorities = [];
    final now = DateTime.now();

    for (var task in tasks) {
      // Calculate laxity (slack time)
      final timeUntilDeadline = task.deadline.difference(now);
      final remainingWork = task.estimatedDuration;
      final laxity = timeUntilDeadline.inMinutes - remainingWork.inMinutes;

      // Calculate urgency (inverse of time until deadline)
      final hoursUntilDeadline = timeUntilDeadline.inHours.toDouble();
      final urgency = hoursUntilDeadline > 0
          ? 100.0 / hoursUntilDeadline
          : 1000.0;

      // Calculate workload factor
      final workloadHours = remainingWork.inHours.toDouble();
      final workload = workloadHours > 0 ? workloadHours : 0.5;

      // Difficulty weight
      final difficultyWeight = task.difficulty == TaskDifficulty.hard
          ? 1.5
          : task.difficulty == TaskDifficulty.medium
          ? 1.2
          : 1.0;

      // Combined priority
      // Higher priority = more urgent, less time, higher difficulty
      final priority = (urgency * difficultyWeight) / workload;

      priorities.add(
        TaskPriority(task: task, priority: priority, laxity: laxity.toDouble()),
      );
    }

    return priorities;
  }

  /// BUG FIX #7: Validate all tasks after event change
  static Future<List<Task>> validateAllTasksAfterEventChange({
    required List<Task> allTasks,
    required List<FixedEvent> fixedEvents,
  }) async {
    final sleepStart = await PreferencesHelper.getSleepStartTime();
    final sleepEnd = await PreferencesHelper.getSleepEndTime();

    List<Task> tasksNeedingReschedule = [];
    List<Task> validTasks = [];

    for (var task in allTasks) {
      if (task.scheduledTime == null || task.isComplete) {
        validTasks.add(task);
        continue;
      }

      // Check if task conflicts with new schedule
      bool hasConflict = false;

      // Check sleep schedule
      if (PreferencesHelper.isDuringSleepTime(
        task.scheduledTime!,
        sleepStart,
        sleepEnd,
      )) {
        hasConflict = true;
      }

      // Check fixed events
      if (!hasConflict) {
        for (var event in fixedEvents) {
          if (_taskConflictsWithEvent(task, event)) {
            hasConflict = true;
            break;
          }
        }
      }

      if (hasConflict) {
        tasksNeedingReschedule.add(task);
      } else {
        validTasks.add(task);
      }
    }

    // Reschedule conflicting tasks
    if (tasksNeedingReschedule.isNotEmpty) {
      final rescheduled = await rescheduleAllTasks(
        incompleteTasks: tasksNeedingReschedule,
        fixedEvents: fixedEvents,
        completedTasks: validTasks,
      );
      validTasks.addAll(rescheduled);
    }

    return validTasks;
  }

  /// Check if task conflicts with a fixed event
  static bool _taskConflictsWithEvent(Task task, FixedEvent event) {
    if (task.scheduledTime == null) return false;

    final taskDay = DayOfWeek.values[task.scheduledTime!.weekday % 7];
    if (!event.daysOfWeek.contains(taskDay)) return false;

    final eventStart = DateTime(
      task.scheduledTime!.year,
      task.scheduledTime!.month,
      task.scheduledTime!.day,
      event.startTime.hour,
      event.startTime.minute,
    );

    final eventEnd = DateTime(
      task.scheduledTime!.year,
      task.scheduledTime!.month,
      task.scheduledTime!.day,
      event.endTime.hour,
      event.endTime.minute,
    );

    final taskEnd = task.scheduledTime!.add(task.estimatedDuration);

    return task.scheduledTime!.isBefore(eventEnd) &&
        taskEnd.isAfter(eventStart);
  }

  /// Quick reschedule for freed-up time (e.g., canceled class)
  static Future<List<Task>> reschedulePriorityTasksInFreedTime({
    required DateTime freedStart,
    required DateTime freedEnd,
    required List<Task> unscheduledTasks,
    required List<FixedEvent> fixedEvents,
    required List<Task> existingTasks,
  }) async {
    // Calculate available duration
    final availableDuration = freedEnd.difference(freedStart);

    // Find tasks that fit in this slot
    final fittingTasks = unscheduledTasks
        .where((task) => task.estimatedDuration <= availableDuration)
        .toList();

    if (fittingTasks.isEmpty) return [];

    // Prioritize tasks
    final prioritized = await _calculatePriorities(fittingTasks);
    prioritized.sort((a, b) => b.priority.compareTo(a.priority));

    // Schedule top priority task in freed slot
    List<Task> scheduled = [];
    DateTime currentSlotStart = freedStart;

    for (var taskPriority in prioritized) {
      final task = taskPriority.task;
      final taskEnd = currentSlotStart.add(task.estimatedDuration);

      if (taskEnd.isAfter(freedEnd)) break;

      // Create scheduled task
      final scheduledTask = Task(
        id: task.id,
        name: task.name,
        details: task.details,
        estimatedDuration: task.estimatedDuration,
        deadline: task.deadline,
        difficulty: task.difficulty,
        scheduledTime: currentSlotStart,
        isComplete: false,
      );

      scheduled.add(scheduledTask);
      currentSlotStart = taskEnd.add(const Duration(minutes: 10)); // Break

      if (currentSlotStart.isAfter(freedEnd)) break;
    }

    return scheduled;
  }

  /// Get rescheduling statistics
  static Map<String, dynamic> getReschedulingStats(
    List<TaskPriority> priorities,
  ) {
    final urgent = priorities.where((p) => p.laxity < 0).length;
    final comfortable = priorities
        .where((p) => p.laxity >= 0 && p.laxity < 24 * 60)
        .length;
    final flexible = priorities.where((p) => p.laxity >= 24 * 60).length;

    return {
      'urgent': urgent,
      'comfortable': comfortable,
      'flexible': flexible,
      'total': priorities.length,
    };
  }
}
