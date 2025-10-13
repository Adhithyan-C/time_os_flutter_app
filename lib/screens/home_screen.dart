// lib/screens/home_screen.dart (WITH CHRONOLOGICAL SORTING)

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/screens/backlog_screen.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/screens/add_task_screen.dart';
import 'package:time_os_final/screens/find_task_screen.dart';
import 'package:time_os_final/widgets/task_card.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';
import 'package:time_os_final/helpers/sorting_helper.dart'; // NEW

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Task>> _taskList;
  String _userName = 'User';
  String _greeting = 'Good Morning';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadUserName();
    _updateGreeting();
  }

  Future<void> _loadUserName() async {
    final name = await PreferencesHelper.getUserName();
    setState(() {
      _userName = name;
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = 'Good Morning';
      } else if (hour < 17) {
        _greeting = 'Good Afternoon';
      } else {
        _greeting = 'Good Evening';
      }
    });
  }

  // BUG FIX #8: Refresh after add/edit
  void _loadTasks() {
    setState(() {
      _taskList = DatabaseHelper.instance.getAllTasks();
    });
  }

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
    _loadTasks(); // Refresh
  }

  void _navigateToAddScreen() async {
    // BUG FIX #8: Wait for result and refresh
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );

    if (result == true) {
      _loadTasks(); // Force refresh
    }
  }

  void _navigateToFindScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindTaskScreen()),
    );
  }

  void _navigateToBacklogScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BacklogScreen()),
    );
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_greeting,',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16,
              ),
            ),
            Text(
              _userName,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: AppColors.primaryText,
              size: 28,
            ),
            onPressed: _navigateToFindScreen,
            tooltip: 'Find Task',
          ),
          IconButton(
            icon: const Icon(
              Icons.inbox_outlined,
              color: AppColors.primaryText,
              size: 28,
            ),
            tooltip: 'Incomplete Tasks',
            onPressed: _navigateToBacklogScreen,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryText, size: 28),
            onPressed: _navigateToAddScreen,
            tooltip: 'Add Task',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Schedule",
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Task>>(
                future: _taskList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading tasks.'));
                  }

                  final allTasks = snapshot.data ?? [];

                  // BUG FIX: Chronological sorting
                  final todayTasks = SortingHelper.getTodayTasksSorted(
                    allTasks,
                  );

                  if (todayTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: AppColors.secondaryText.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tasks scheduled for today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to add a new task',
                            style: TextStyle(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: todayTasks.length,
                    itemBuilder: (context, index) {
                      final task = todayTasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TaskCard(
                          task: task,
                          onCompleted: (isCompleted) =>
                              _toggleTaskCompletion(task, isCompleted),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
