// lib/screens/add_task_screen.dart (WITH TASK SPLITTING)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/helpers/task_splitter.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';
import 'package:time_os_final/theme.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _detailsController = TextEditingController();
  final _dateController = TextEditingController();

  TaskDifficulty? _selectedDifficulty;
  DateTime? _selectedDeadline;
  Duration? _selectedDuration;
  String _splitPreview = '';

  @override
  void initState() {
    super.initState();
    _durationController.addListener(_updateSplitPreview);
  }

  Future<void> _updateSplitPreview() async {
    if (_durationController.text.isEmpty) {
      setState(() => _splitPreview = '');
      return;
    }

    final parts = _durationController.text.split(':');
    if (parts.length == 2) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      if (hours != null && minutes != null) {
        final duration = Duration(hours: hours, minutes: minutes);
        final workBlock =
            await PreferencesHelper.getPreferredWorkBlockMinutes();

        final tempTask = Task(
          name: 'Preview',
          estimatedDuration: duration,
          deadline: DateTime.now().add(const Duration(days: 7)),
          difficulty: TaskDifficulty.medium,
        );

        setState(() {
          _splitPreview = TaskSplitter.getTaskSplitPreview(tempTask, workBlock);
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDeadline ?? DateTime.now(),
        ),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateController.text = DateFormat(
            'MMM d, yyyy - hh:mm a',
          ).format(_selectedDeadline!);
        });
      }
    }
  }

  Future<void> _addTask() async {
    if (!mounted) return;
    if (_formKey.currentState!.validate()) {
      if (_selectedDeadline == null || _durationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a deadline and duration.'),
          ),
        );
        return;
      }

      Duration? parsedDuration;
      final parts = _durationController.text.split(':');
      if (parts.length == 2) {
        final hours = int.tryParse(parts[0]);
        final minutes = int.tryParse(parts[1]);
        if (hours != null && minutes != null) {
          parsedDuration = Duration(hours: hours, minutes: minutes);
        }
      }

      if (parsedDuration == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter duration in HH:MM format.'),
          ),
        );
        return;
      }

      // Duration rounding logic
      int totalMinutes = parsedDuration.inMinutes;
      if (totalMinutes % 5 != 0) {
        totalMinutes = totalMinutes - (totalMinutes % 5) + 5;
      }
      _selectedDuration = Duration(minutes: totalMinutes);

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create the task
      final newTask = Task(
        name: _nameController.text,
        details: _detailsController.text,
        estimatedDuration: _selectedDuration!,
        deadline: _selectedDeadline!,
        difficulty: _selectedDifficulty ?? TaskDifficulty.easy,
      );

      // Get existing data
      final fixedEvents = await DatabaseHelper.instance.getAllFixedEvents();
      final existingTasks = await DatabaseHelper.instance.getAllTasks();

      // Try to schedule with splitting
      final scheduledSplits = await TaskSplitter.scheduleTaskSessions(
        task: newTask,
        fixedEvents: fixedEvents,
        existingTasks: existingTasks,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (scheduledSplits.isEmpty) {
        // Couldn't schedule
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to schedule this task before the deadline. '
              'Try extending the deadline or reducing task duration.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Show confirmation dialog if task was split
      if (scheduledSplits.length > 1) {
        final confirmed = await _showSplitConfirmation(scheduledSplits);
        if (!confirmed) return;
      }

      // Save all task sessions to database
      final taskObjects = TaskSplitter.convertSplitsToTasks(
        newTask,
        scheduledSplits,
      );

      for (var task in taskObjects) {
        await DatabaseHelper.instance.addTask(task);
      }

      if (!mounted) return;

      // Show success message
      if (scheduledSplits.length == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task scheduled for ${DateFormat('MMM d at h:mm a').format(scheduledSplits.first.scheduledTime!)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task split into ${scheduledSplits.length} sessions and scheduled!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  Future<bool> _showSplitConfirmation(List<TaskSplit> splits) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.content_cut, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Task Split'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This task will be split into ${splits.length} sessions:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...splits.map(
                    (split) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              split.sessionName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('MMM d, h:mm a').format(split.scheduledTime!)} • ${_formatDuration(split.duration)}',
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Confirm Schedule',
                  style: TextStyle(color: AppColors.textOnPrimary),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDuration(Duration duration) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _detailsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Task Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Finish OS Project',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Estimated Duration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  hintText: 'HH:MM (e.g., 01:30)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.datetime,
              ),

              // Split Preview
              if (_splitPreview.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(77),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _splitPreview,
                            style: TextStyle(
                              color: AppColors.primary.withAlpha(230),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              const Text(
                'Difficulty',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _DifficultyButton(
                    label: 'Easy',
                    color: AppColors.success,
                    isSelected: _selectedDifficulty == TaskDifficulty.easy,
                    onTap: () => setState(
                      () => _selectedDifficulty = TaskDifficulty.easy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyButton(
                    label: 'Medium',
                    color: AppColors.warning,
                    isSelected: _selectedDifficulty == TaskDifficulty.medium,
                    onTap: () => setState(
                      () => _selectedDifficulty = TaskDifficulty.medium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DifficultyButton(
                    label: 'Hard',
                    color: AppColors.danger,
                    isSelected: _selectedDifficulty == TaskDifficulty.hard,
                    onTap: () => setState(
                      () => _selectedDifficulty = TaskDifficulty.hard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Deadline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Select Date & Time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),

              const Text(
                'Task Details (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add any extra notes here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Schedule Task',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
      ),
    );
  }
}
