// lib/widgets/task_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_os_final/models/task_model.dart';
import 'package:time_os_final/theme.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  // New callback for when the checkbox value changes
  final Function(bool?)? onCompleted;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onCompleted, // Add it to the constructor
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isExpanded = false;

  Color _getDifficultyColor() {
    switch (widget.task.difficulty) {
      case TaskDifficulty.easy:
        return AppColors.success;
      case TaskDifficulty.medium:
        return AppColors.warning;
      case TaskDifficulty.hard:
        return AppColors.danger;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    return "${hours}h ${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // --- THIS IS THE UPDATED WIDGET ---
                Checkbox(
                  value: widget.task.isComplete,
                  onChanged: widget.onCompleted, // Use the new callback here
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryText,
                          // Add a line-through style if the task is complete
                          decoration: widget.task.isComplete
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.secondaryText,
                        ),
                      ),
                      if (widget.task.scheduledTime != null)
                        Text(
                          '${DateFormat('hh:mm a').format(widget.task.scheduledTime!)} - ${DateFormat('hh:mm a').format(widget.task.scheduledTime!.add(widget.task.estimatedDuration))}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Details: ${widget.task.details.isNotEmpty ? widget.task.details : 'No details provided.'}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${_formatDuration(widget.task.estimatedDuration)}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deadline: ${DateFormat('MMM d, yyyy - hh:mm a').format(widget.task.deadline)}',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
