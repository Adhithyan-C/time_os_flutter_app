// lib/screens/tasks_screen.dart (WITH SORTING & REFRESH)

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/screens/edit_task_screen.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/widgets/task_card.dart';
import 'package:time_os_final/helpers/sorting_helper.dart'; // NEW

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedDayIndex = DateTime.now().weekday % 7;
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];

  @override
  void initState() {
    super.initState();
    _loadAllTasks();
  }

  // BUG FIX #8: Proper refresh
  Future<void> _loadAllTasks() async {
    final tasks = await DatabaseHelper.instance.getAllTasks();
    if (mounted) {
      setState(() {
        _allTasks = tasks;
        _filterTasksForSelectedDay();
      });
    }
  }

  // BUG FIX: Chronological sorting after filtering
  void _filterTasksForSelectedDay() {
    // Use SortingHelper for chronological sorting
    _filteredTasks = SortingHelper.getTasksForDaySorted(
      _allTasks,
      _selectedDayIndex,
    );
  }

  // BUG FIX #8: Force refresh after toggle
  Future<void> _toggleTaskCompletion(Task task, bool? isCompleted) async {
    if (isCompleted == null) return;

    final updatedTask = Task(
      id: task.id,
      name: task.name,
      details: task.details,
      estimatedDuration: task.estimatedDuration,
      deadline: task.deadline,
      difficulty: task.difficulty,
      scheduledTime: task.scheduledTime,
      isComplete: isCompleted,
    );

    await DatabaseHelper.instance.updateTask(updatedTask);
    _loadAllTasks(); // Refresh immediately
  }

  void _navigateToEditScreen(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
    );

    // BUG FIX #8: Refresh on return
    if (result == true || result == null) {
      _loadAllTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: Column(
        children: [
          // Day selector
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isSelected = index == _selectedDayIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                      _filterTasksForSelectedDay();
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        days[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Task count indicator
          if (_filteredTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_filteredTasks.length} task${_filteredTasks.length != 1 ? 's' : ''} (sorted by time)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Task list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 64,
                            color: AppColors.secondaryText.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No tasks for ${_getDayName(_selectedDayIndex)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tasks are sorted chronologically',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TaskCard(
                            task: task,
                            onTap: () => _navigateToEditScreen(task),
                            onCompleted: (isCompleted) =>
                                _toggleTaskCompletion(task, isCompleted),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int index) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[index];
  }
}
