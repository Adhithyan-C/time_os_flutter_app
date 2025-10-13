// lib/helpers/sorting_helper.dart
// BUG FIX: Chronological sorting for all lists

import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/models/event_model.dart';

class SortingHelper {
  /// Sort tasks by scheduled time (or deadline if not scheduled)
  static List<Task> sortTasksChronologically(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) {
      // Use scheduled time if available, otherwise use deadline
      final aTime = a.scheduledTime ?? a.deadline;
      final bTime = b.scheduledTime ?? b.deadline;
      return aTime.compareTo(bTime);
    });
    return sortedTasks;
  }

  /// Sort tasks for a specific day by scheduled time
  static List<Task> sortTasksForDay(List<Task> tasks, DateTime day) {
    final dayTasks = tasks.where((task) {
      if (task.scheduledTime == null) return false;
      return task.scheduledTime!.year == day.year &&
          task.scheduledTime!.month == day.month &&
          task.scheduledTime!.day == day.day;
    }).toList();

    dayTasks.sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));
    return dayTasks;
  }

  /// Sort events by start time
  static List<FixedEvent> sortEventsChronologically(List<FixedEvent> events) {
    final sortedEvents = List<FixedEvent>.from(events);
    sortedEvents.sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return sortedEvents;
  }

  /// Filter and sort tasks for today
  static List<Task> getTodayTasksSorted(List<Task> allTasks) {
    final today = DateTime.now();
    final todayTasks = sortTasksForDay(allTasks, today);
    return todayTasks;
  }

  /// Filter and sort tasks by day of week
  static List<Task> getTasksForDaySorted(List<Task> allTasks, int dayIndex) {
    final filtered = allTasks.where((task) {
      final effectiveDate = task.scheduledTime ?? task.deadline;
      return effectiveDate.weekday % 7 == dayIndex;
    }).toList();

    filtered.sort((a, b) {
      final aTime = a.scheduledTime ?? a.deadline;
      final bTime = b.scheduledTime ?? b.deadline;
      return aTime.compareTo(bTime);
    });

    return filtered;
  }

  /// Get incomplete tasks sorted by deadline (for backlog)
  static List<Task> getIncompleteTasksSorted(List<Task> tasks) {
    final incomplete = tasks.where((task) => !task.isComplete).toList();
    incomplete.sort((a, b) => a.deadline.compareTo(b.deadline));
    return incomplete;
  }
}
