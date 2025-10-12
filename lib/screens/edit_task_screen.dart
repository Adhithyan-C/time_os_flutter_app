// lib/screens/edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/theme.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _detailsController;
  late TextEditingController _dateController;

  TaskDifficulty? _selectedDifficulty;
  DateTime? _selectedDeadline;
  Duration? _selectedDuration;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _detailsController = TextEditingController(text: widget.task.details);
    _durationController = TextEditingController(
      text:
          '${widget.task.estimatedDuration.inHours.toString().padLeft(2, '0')}:${(widget.task.estimatedDuration.inMinutes % 60).toString().padLeft(2, '0')}',
    );
    _dateController = TextEditingController(
      text: DateFormat('MMM d, yyyy - hh:mm a').format(widget.task.deadline),
    );

    _selectedDifficulty = widget.task.difficulty;
    _selectedDeadline = widget.task.deadline;
    _selectedDuration = widget.task.estimatedDuration;
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

  Future<void> _updateTask() async {
    if (!mounted) return;
    if (_formKey.currentState!.validate()) {
      final parts = _durationController.text.split(':');
      if (parts.length == 2) {
        final hours = int.tryParse(parts[0]);
        final minutes = int.tryParse(parts[1]);
        if (hours != null && minutes != null) {
          _selectedDuration = Duration(hours: hours, minutes: minutes);
        }
      }

      final updatedTask = Task(
        id: widget.task.id,
        name: _nameController.text,
        details: _detailsController.text,
        estimatedDuration: _selectedDuration!,
        deadline: _selectedDeadline!,
        difficulty: _selectedDifficulty!,
        isComplete: widget.task.isComplete,
        scheduledTime:
            widget.task.scheduledTime, // BUG FIX: Preserve the scheduled time
      );

      await DatabaseHelper.instance.updateTask(updatedTask);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Updated Successfully!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _deleteTask() async {
    // This is the correct pattern
    await DatabaseHelper.instance.deleteTask(widget.task.id!);
    if (!mounted) return;
    // Pop twice to close dialog and edit screen
    Navigator.of(context).popUntil((route) => route.isFirst);
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
        title: const Text('Edit Task'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text(
                      'Are you sure you want to delete this task?',
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      TextButton(
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.danger),
                        ),
                        onPressed: _deleteTask,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
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
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a task name'
                    : null,
              ),
              const SizedBox(height: 24),

              const Text(
                'Estimated Duration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.datetime,
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
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),

              const Text(
                'Task Details (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _detailsController, maxLines: 4),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Task',
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
