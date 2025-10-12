// lib/screens/find_task_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/widgets/task_card.dart';

class FindTaskScreen extends StatefulWidget {
  const FindTaskScreen({super.key});

  @override
  State<FindTaskScreen> createState() => _FindTaskScreenState();
}

class _FindTaskScreenState extends State<FindTaskScreen> {
  final _durationController = TextEditingController();
  TaskDifficulty? _selectedFocusLevel;

  // This new function handles accepting a task
  Future<void> _acceptTask(Task task) async {
    final scheduledTime = await DatabaseHelper.instance.findNextAvailableSlot(
      task.estimatedDuration,
      task.deadline,
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

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task has been scheduled!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find a free slot for this task.'),
        ),
      );
    }
  }

  Future<void> _findTasks() async {
    if (_selectedFocusLevel == null || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a duration and select a focus level.'),
        ),
      );
      return;
    }

    Duration? availableDuration;
    final parts = _durationController.text.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      if (hours != null && minutes != null) {
        availableDuration = Duration(hours: hours, minutes: minutes);
      }
    }

    if (availableDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter duration in HH:MM format.')),
      );
      return;
    }

    final suggestedTasks = await DatabaseHelper.instance.findSuggestedTasks(
      availableDuration,
      _selectedFocusLevel!,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggested Tasks'),
        content: SizedBox(
          width: double.maxFinite,
          child: suggestedTasks.isEmpty
              ? const Text('No suitable tasks found.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestedTasks.length,
                  itemBuilder: (context, index) {
                    final task = suggestedTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      // This TaskCard is now tappable
                      child: TaskCard(
                        task: task,
                        onTap: () => _acceptTask(task),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Tasks'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the duration available:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                hintText: 'HH:MM (e.g., 00:45)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 24),
            const Text(
              'Environment / Focus level',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _FocusLevelButton(
              label: 'Quiet & Focused',
              color: AppColors.danger,
              isSelected: _selectedFocusLevel == TaskDifficulty.hard,
              onTap: () =>
                  setState(() => _selectedFocusLevel = TaskDifficulty.hard),
            ),
            const SizedBox(height: 8),
            _FocusLevelButton(
              label: 'Okayish',
              color: AppColors.warning,
              isSelected: _selectedFocusLevel == TaskDifficulty.medium,
              onTap: () =>
                  setState(() => _selectedFocusLevel = TaskDifficulty.medium),
            ),
            const SizedBox(height: 8),
            _FocusLevelButton(
              label: 'Distracted / On the move',
              color: AppColors.success,
              isSelected: _selectedFocusLevel == TaskDifficulty.easy,
              onTap: () =>
                  setState(() => _selectedFocusLevel = TaskDifficulty.easy),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _findTasks,
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text('Search for available tasks'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Helper widget for the focus level buttons
class _FocusLevelButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FocusLevelButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(51) : null,
          border: Border.all(color: isSelected ? color : Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, color: color, size: 12),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.primaryText)),
          ],
        ),
      ),
    );
  }
}
