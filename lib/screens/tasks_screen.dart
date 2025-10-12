// lib/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/screens/edit_task_screen.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/widgets/task_card.dart';

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

  Future<void> _loadAllTasks() async {
    final tasks = await DatabaseHelper.instance.getAllTasks();
    if (mounted) {
      setState(() {
        _allTasks = tasks;
        _filterTasksForSelectedDay();
      });
    }
  }

  void _filterTasksForSelectedDay() {
    _filteredTasks = _allTasks.where((task) {
      final effectiveDate = task.scheduledTime ?? task.deadline;
      return effectiveDate.weekday % 7 == _selectedDayIndex;
    }).toList();
  }

  // --- NEW FUNCTION: Toggle task completion ---
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
    _loadAllTasks();
  }

  void _navigateToEditScreen(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
    );
    _loadAllTasks();
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

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _filteredTasks.isEmpty
                  ? Center(
                      child: Text(
                        "No tasks scheduled for this day.",
                        style: TextStyle(color: AppColors.secondaryText),
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
                            // --- FIX: Added the onCompleted callback ---
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
}
