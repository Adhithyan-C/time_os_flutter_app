// lib/screens/add_event_screen.dart (ENHANCED)

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/models/event_model.dart';
import 'package:time_os_final/helpers/event_validator.dart';
import 'package:time_os_final/helpers/time_rounding_helper.dart';
import 'package:time_os_final/theme.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Set<DayOfWeek> _selectedDays = {};

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // ROUND TO NEAREST 15 MINUTES
        final rounded = TimeRoundingHelper.roundToNearest15Minutes(picked);

        if (isStartTime) {
          _startTime = rounded;
        } else {
          _endTime = rounded;
        }
      });
    }
  }

  Future<void> _addEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields
    if (_startTime == null || _endTime == null || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Validate end time is after start time
    if (!TimeRoundingHelper.isEndAfterStart(_startTime!, _endTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: End time must be after start time.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final newEvent = FixedEvent(
      name: _nameController.text.trim(),
      startTime: _startTime!,
      endTime: _endTime!,
      daysOfWeek: _selectedDays.toList(),
    );

    // Basic validation
    final validationError = EventValidator.validateEvent(newEvent);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $validationError'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Check for conflicts with existing events
    final existingEvents = await DatabaseHelper.instance.getAllFixedEvents();
    final conflicts = EventValidator.findConflicts(newEvent, existingEvents);

    if (conflicts.isNotEmpty) {
      // Show conflict error
      final conflictMessage = conflicts.first.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $conflictMessage'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // All validations passed - save the event
    await DatabaseHelper.instance.addFixedEvent(newEvent);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event "${newEvent.name}" added successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event'),
        foregroundColor: AppColors.primaryText,
        backgroundColor: AppColors.background,
        elevation: 0,
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
                  hintText: 'e.g., OS Class',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an event name';
                  }
                  return null;
                },
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

              // Show time validation hint
              if (_startTime != null && _endTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          TimeRoundingHelper.isEndAfterStart(
                            _startTime!,
                            _endTime!,
                          )
                          ? AppColors.success.withAlpha(26)
                          : AppColors.danger.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            TimeRoundingHelper.isEndAfterStart(
                              _startTime!,
                              _endTime!,
                            )
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          TimeRoundingHelper.isEndAfterStart(
                                _startTime!,
                                _endTime!,
                              )
                              ? Icons.check_circle
                              : Icons.error,
                          color:
                              TimeRoundingHelper.isEndAfterStart(
                                _startTime!,
                                _endTime!,
                              )
                              ? AppColors.success
                              : AppColors.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            TimeRoundingHelper.isEndAfterStart(
                                  _startTime!,
                                  _endTime!,
                                )
                                ? 'Duration: ${TimeRoundingHelper.getDurationInMinutes(_startTime!, _endTime!)} minutes'
                                : 'Error: End time must be after start time',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  TimeRoundingHelper.isEndAfterStart(
                                    _startTime!,
                                    _endTime!,
                                  )
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                child: ElevatedButton.icon(
                  onPressed: _addEvent,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Event'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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
