// lib/screens/onboarding/step_weekly_events.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/helpers/event_validator.dart';
import 'package:time_os_final/theme.dart';

class StepWeeklyEvents extends StatefulWidget {
  final VoidCallback onNext;

  const StepWeeklyEvents({super.key, required this.onNext});

  @override
  State<StepWeeklyEvents> createState() => _StepWeeklyEventsState();
}

class _StepWeeklyEventsState extends State<StepWeeklyEvents> {
  List<FixedEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingEvents();
  }

  Future<void> _loadExistingEvents() async {
    final events = await DatabaseHelper.instance.getAllFixedEvents();
    setState(() {
      _events = events;
    });
  }

  void _addEvent() async {
    final result = await showDialog<FixedEvent>(
      context: context,
      builder: (context) => AddEventDialog(existingEvents: _events),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      await DatabaseHelper.instance.addFixedEvent(result);
      await _loadExistingEvents();
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${result.name}"'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _editEvent(FixedEvent event) async {
    final result = await showDialog<FixedEvent>(
      context: context,
      builder: (context) =>
          AddEventDialog(existingEvents: _events, eventToEdit: event),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      await DatabaseHelper.instance.updateFixedEvent(result);
      await _loadExistingEvents();
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event updated')));
    }
  }

  void _deleteEvent(FixedEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Remove "${event.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteFixedEvent(event.id!);
      await _loadExistingEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.calendar_month, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Weekly Schedule',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your recurring commitments like classes, gym, or meals. Tasks will be scheduled around these.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Event count and quick stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_events.length} Events',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (_events.isNotEmpty)
                      Text(
                        _getTotalHoursBlocked(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: _addEvent,
                  icon: const Icon(Icons.add_circle, size: 32),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Event list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
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
                        const Text(
                          'No events yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _addEvent,
                          icon: const Icon(Icons.add),
                          label: const Text('Add your first event'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _EventCard(
                          event: event,
                          onTap: () => _editEvent(event),
                          onDelete: () => _deleteEvent(event),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            children: [
              TextButton(
                onPressed: widget.onNext,
                child: const Text('Skip for now'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: AppColors.textOnPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTotalHoursBlocked() {
    int totalMinutes = 0;
    for (var event in _events) {
      final duration =
          (event.endTime.hour * 60 + event.endTime.minute) -
          (event.startTime.hour * 60 + event.startTime.minute);
      totalMinutes += duration * event.daysOfWeek.length;
    }
    final hours = totalMinutes ~/ 60;
    return '$hours hours blocked per week';
  }
}

// Event Card Widget
class _EventCard extends StatelessWidget {
  final FixedEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDays() {
    if (event.daysOfWeek.length == 7) return 'Every Day';
    return event.daysOfWeek
        .map((day) => day.name.substring(0, 3).toUpperCase())
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: event.getTypeColor().withAlpha(77),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: event.getTypeColor().withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                event.getTypeIcon(),
                color: event.getTypeColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.startTime.format(context)} - ${event.endTime.format(context)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDays(),
                    style: TextStyle(
                      fontSize: 12,
                      color: event.getTypeColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// Add/Edit Event Dialog
class AddEventDialog extends StatefulWidget {
  final List<FixedEvent> existingEvents;
  final FixedEvent? eventToEdit;

  const AddEventDialog({
    super.key,
    required this.existingEvents,
    this.eventToEdit,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  EventType _selectedType = EventType.other;
  Set<DayOfWeek> _selectedDays = {};
  List<EventConflict> _conflicts = [];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _nameController.text = event.name;
      _startTime = event.startTime;
      _endTime = event.endTime;
      _selectedType = event.eventType;
      _selectedDays = event.daysOfWeek.toSet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _checkConflicts();
      });
    }
  }

  void _checkConflicts() {
    if (_startTime == null || _endTime == null || _selectedDays.isEmpty) {
      setState(() => _conflicts = []);
      return;
    }

    final tempEvent = FixedEvent(
      id: widget.eventToEdit?.id,
      name: _nameController.text,
      startTime: _startTime!,
      endTime: _endTime!,
      daysOfWeek: _selectedDays.toList(),
      eventType: _selectedType,
    );

    setState(() {
      _conflicts = EventValidator.findConflicts(
        tempEvent,
        widget.existingEvents,
      );
    });
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final newEvent = FixedEvent(
      id: widget.eventToEdit?.id,
      name: _nameController.text.trim(),
      startTime: _startTime!,
      endTime: _endTime!,
      daysOfWeek: _selectedDays.toList(),
      eventType: _selectedType,
    );

    // Validate the event
    final error = EventValidator.validateEvent(newEvent);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Check conflicts
    if (_conflicts.isNotEmpty) {
      _showConflictDialog();
      return;
    }

    Navigator.pop(context, newEvent);
  }

  void _showConflictDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Schedule Conflict'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This event conflicts with:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._conflicts.map(
                (conflict) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    '• ${conflict.message}',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit Event'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close conflict dialog
              Navigator.pop(
                context,
                FixedEvent(
                  id: widget.eventToEdit?.id,
                  name: _nameController.text.trim(),
                  startTime: _startTime!,
                  endTime: _endTime!,
                  daysOfWeek: _selectedDays.toList(),
                  eventType: _selectedType,
                ),
              );
            },
            child: const Text(
              'Save Anyway',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventToEdit != null ? 'Edit Event' : 'Add Event',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Event Name',
                            hintText: 'e.g., Math Class',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => value?.trim().isEmpty ?? true
                              ? 'Please enter a name'
                              : null,
                          onChanged: (_) => _checkConflicts(),
                        ),
                        const SizedBox(height: 16),

                        // Event Type
                        const Text(
                          'Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: EventType.values.map((type) {
                            final isSelected = _selectedType == type;
                            return FilterChip(
                              label: Text(_getTypeName(type)),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() => _selectedType = type);
                              },
                              avatar: Icon(
                                _getTypeIcon(type),
                                size: 16,
                                color: isSelected ? Colors.white : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Time Selection
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _TimeButton(
                                    time: _startTime,
                                    onTap: () => _selectTime(true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Time',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _TimeButton(
                                    time: _endTime,
                                    onTap: () => _selectTime(false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Days Selection
                        const Text(
                          'Repeats On',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DayOfWeek.values.map((day) {
                            final isSelected = _selectedDays.contains(day);
                            return FilterChip(
                              label: Text(
                                day.name.substring(0, 3).toUpperCase(),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedDays.add(day);
                                  } else {
                                    _selectedDays.remove(day);
                                  }
                                  _checkConflicts();
                                });
                              },
                            );
                          }).toList(),
                        ),

                        // Conflict Warning
                        if (_conflicts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.warning),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber,
                                        color: AppColors.warning,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Conflicts detected',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...(_conflicts
                                      .take(2)
                                      .map(
                                        (conflict) => Text(
                                          '• ${conflict.message}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      )),
                                  if (_conflicts.length > 2)
                                    Text(
                                      '... and ${_conflicts.length - 2} more',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        widget.eventToEdit != null ? 'Update' : 'Add Event',
                        style: const TextStyle(color: AppColors.textOnPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeName(EventType type) {
    switch (type) {
      case EventType.class_:
        return 'Class';
      case EventType.personal:
        return 'Personal';
      case EventType.exercise:
        return 'Exercise';
      case EventType.meal:
        return 'Meal';
      case EventType.work:
        return 'Work';
      case EventType.other:
        return 'Other';
    }
  }

  IconData _getTypeIcon(EventType type) {
    switch (type) {
      case EventType.class_:
        return Icons.school;
      case EventType.exercise:
        return Icons.fitness_center;
      case EventType.meal:
        return Icons.restaurant;
      case EventType.work:
        return Icons.work;
      case EventType.personal:
        return Icons.person;
      case EventType.other:
        return Icons.event;
    }
  }
}

class _TimeButton extends StatelessWidget {
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeButton({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondaryText),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time?.format(context) ?? 'Select',
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.access_time, size: 20),
          ],
        ),
      ),
    );
  }
}
