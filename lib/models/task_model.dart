// lib/models/task_model.dart

// An enumeration to represent the three levels of difficulty.
// Using an enum is safer and cleaner than using simple strings.
enum TaskDifficulty { easy, medium, hard }

class Task {
  final int? id; // Nullable for new tasks that don't have an ID yet.
  final String name;
  final String details;
  final Duration estimatedDuration;
  final DateTime deadline;
  final TaskDifficulty difficulty;
  final bool isComplete;
  DateTime? scheduledTime; // Nullable for our auto-scheduling feature.

  Task({
    this.id,
    required this.name,
    this.details = '', // Default to empty string if no details are provided
    required this.estimatedDuration,
    required this.deadline,
    required this.difficulty,
    this.isComplete = false, // Defaults to not complete
    this.scheduledTime,
  });

  // Helper function to convert our Task object into a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'estimatedDuration':
          estimatedDuration.inMinutes, // Store duration as minutes
      'deadline': deadline.toIso8601String(), // Store dates as text
      'difficulty': difficulty.index, // Store enum as an integer
      'isComplete': isComplete ? 1 : 0, // Store bool as 0 or 1
      'scheduledTime': scheduledTime
          ?.toIso8601String(), // Store nullable date as text
    };
  }

  // Helper function to create a Task object from a Map from the database.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      details: map['details'],
      estimatedDuration: Duration(minutes: map['estimatedDuration']),
      deadline: DateTime.parse(map['deadline']),
      difficulty: TaskDifficulty.values[map['difficulty']],
      isComplete: map['isComplete'] == 1,
      scheduledTime: map['scheduledTime'] != null
          ? DateTime.parse(map['scheduledTime'])
          : null,
    );
  }
}
