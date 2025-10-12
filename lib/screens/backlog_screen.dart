// lib/screens/backlog_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/theme.dart';

class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  late Future<List<Task>> _incompleteTasks;

  @override
  void initState() {
    super.initState();
    _loadIncompleteTasks();
  }

  void _loadIncompleteTasks() {
    setState(() {
      _incompleteTasks = DatabaseHelper.instance.getIncompleteTasks();
    });
  }

  // --- THIS IS THE CORRECTED FUNCTION ---
  Future<void> _rescheduleTask(Task task) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Finding a new slot...')));

    // For an overdue task, we create a new, future deadline to search within.
    final newSearchDeadline = DateTime.now().add(const Duration(days: 7));

    final scheduledTime = await DatabaseHelper.instance.findNextAvailableSlot(
      task.estimatedDuration,
      newSearchDeadline, // We use the new, future deadline for the search
    );

    if (!mounted) return;

    if (scheduledTime != null) {
      final updatedTask = Task(
        id: task.id,
        name: task.name,
        details: task.details,
        estimatedDuration: task.estimatedDuration,
        deadline: task.deadline,
        difficulty: task.difficulty,
        isComplete: false,
        scheduledTime: scheduledTime,
      );
      await DatabaseHelper.instance.updateTask(updatedTask);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Rescheduled Successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not find a free slot for this task in the next 7 days.',
          ),
        ),
      );
    }

    // Refresh the list of incomplete tasks
    _loadIncompleteTasks();
  }

  Future<void> _deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task Deleted.')));
    _loadIncompleteTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incomplete Tasks'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: FutureBuilder<List<Task>>(
        future: _incompleteTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No incomplete tasks. Good job!'));
          }
          final tasks = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deadline was: ${task.deadline.toLocal().toString().substring(0, 10)}',
                        style: const TextStyle(color: AppColors.danger),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _deleteTask(task.id!),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _rescheduleTask(task),
                            child: const Text('Reschedule'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
