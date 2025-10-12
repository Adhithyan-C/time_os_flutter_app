// lib/screens/edit_event_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/theme.dart';

class EditEventScreen extends StatefulWidget {
  final FixedEvent event;
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Set<DayOfWeek> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name);
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
    _selectedDays.addAll(widget.event.daysOfWeek);
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isStartTime ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_startTime == null || _endTime == null || _selectedDays.isEmpty) {
        return;
      }

      final updatedEvent = FixedEvent(
        id: widget.event.id,
        name: _nameController.text,
        startTime: _startTime!,
        endTime: _endTime!,
        daysOfWeek: _selectedDays.toList(),
      );

      await DatabaseHelper.instance.updateFixedEvent(updatedEvent);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  // BUG FIX: Corrected delete logic
  Future<void> _deleteEvent() async {
    await DatabaseHelper.instance.deleteFixedEvent(widget.event.id!);
    if (!mounted) return;
    // Pop until we get back to the root screen (the main app shell)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        foregroundColor: AppColors.primaryText,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: Text(
                    'Are you sure you want to delete "${widget.event.name}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Close the dialog THEN call the delete function
                        Navigator.pop(dialogContext);
                        _deleteEvent();
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
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
                'Event Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 24),
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
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startTime?.format(context) ?? 'Select Time',
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
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
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endTime?.format(context) ?? 'Select Time',
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Repeats on',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: DayOfWeek.values.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  final dayName = day.name.substring(0, 3).toUpperCase();
                  return FilterChip(
                    label: Text(dayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
