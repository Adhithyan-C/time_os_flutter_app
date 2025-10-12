// lib/screens/onboarding/step3_work_window.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';

class Step3WorkWindow extends StatefulWidget {
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final Function(TimeOfDay, TimeOfDay) onNext;

  const Step3WorkWindow({
    super.key,
    required this.wakeTime,
    required this.sleepTime,
    required this.onNext,
  });

  @override
  State<Step3WorkWindow> createState() => _Step3WorkWindowState();
}

class _Step3WorkWindowState extends State<Step3WorkWindow> {
  TimeOfDay? _dayStart;
  TimeOfDay? _dayEnd;

  @override
  void initState() {
    super.initState();
    // Set smart defaults based on wake/sleep times
    _dayStart = TimeOfDay(
      hour: (widget.wakeTime.hour + 2) % 24, // 2 hours after waking
      minute: widget.wakeTime.minute,
    );
    _dayEnd = TimeOfDay(
      hour: widget.sleepTime.hour > 0 ? widget.sleepTime.hour - 1 : 22,
      minute: widget.sleepTime.minute,
    );
  }

  Future<void> _selectTime(BuildContext context, bool isDayStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isDayStart ? _dayStart : _dayEnd) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDayStart) {
          _dayStart = picked;
        } else {
          _dayEnd = picked;
        }
      });
    }
  }

  void _handleNext() {
    if (_dayStart == null || _dayEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end times')),
      );
      return;
    }

    // Validate that day starts after wake time
    final dayStartMinutes = _dayStart!.hour * 60 + _dayStart!.minute;
    final wakeMinutes = widget.wakeTime.hour * 60 + widget.wakeTime.minute;

    if (dayStartMinutes < wakeMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your productive day should start after you wake up!'),
        ),
      );
      return;
    }

    // Calculate work window duration
    int dayStartMins = _dayStart!.hour * 60 + _dayStart!.minute;
    int dayEndMins = _dayEnd!.hour * 60 + _dayEnd!.minute;
    if (dayEndMins < dayStartMins) dayEndMins += 24 * 60;

    final workWindow = Duration(minutes: dayEndMins - dayStartMins);

    if (workWindow.inHours < 8) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Short Work Window'),
          content: Text(
            'Your productive window is only ${workWindow.inHours} hours.\n\n'
            'This might make it difficult to schedule all your tasks. '
            'Consider extending your work hours.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Adjust'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onNext(_dayStart!, _dayEnd!);
              },
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
    } else {
      widget.onNext(_dayStart!, _dayEnd!);
    }
  }

  @override
  Widget build(BuildContext context) {
    int? workHours;
    if (_dayStart != null && _dayEnd != null) {
      int startMins = _dayStart!.hour * 60 + _dayStart!.minute;
      int endMins = _dayEnd!.hour * 60 + _dayEnd!.minute;
      if (endMins < startMins) endMins += 24 * 60;
      workHours = (endMins - startMins) ~/ 60;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_twilight, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Daily Work Window',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When does your productive day typically start and end? This is different from your sleep schedule - it accounts for morning routines and wind-down time.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Day Start Time
          _TimeSelector(
            label: 'Day Starts',
            icon: Icons.wb_sunny,
            time: _dayStart,
            onTap: () => _selectTime(context, true),
            hint: 'After breakfast, getting ready',
          ),
          const SizedBox(height: 16),

          // Day End Time
          _TimeSelector(
            label: 'Day Ends',
            icon: Icons.dark_mode,
            time: _dayEnd,
            onTap: () => _selectTime(context, false),
            hint: 'Wind-down time begins',
          ),

          // Work Window Display
          if (workHours != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      '$workHours hours of productive time',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, color: AppColors.textOnPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final String hint;

  const _TimeSelector({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondaryText.withAlpha(77)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time?.format(context) ?? 'Select Time',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}
