// lib/screens/onboarding/step2_sleep_schedule.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';

class Step2SleepSchedule extends StatefulWidget {
  final Function(TimeOfDay, TimeOfDay) onNext;

  const Step2SleepSchedule({super.key, required this.onNext});

  @override
  State<Step2SleepSchedule> createState() => _Step2SleepScheduleState();
}

class _Step2SleepScheduleState extends State<Step2SleepSchedule> {
  TimeOfDay? _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay? _wakeTime = const TimeOfDay(hour: 7, minute: 0);

  Future<void> _selectTime(BuildContext context, bool isSleepTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: (isSleepTime ? _sleepTime : _wakeTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isSleepTime) {
          _sleepTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  void _handleNext() {
    if (_sleepTime == null || _wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both sleep and wake times'),
        ),
      );
      return;
    }

    // Validate sleep duration
    final sleepDuration = PreferencesHelper.calculateSleepDuration(
      _sleepTime!,
      _wakeTime!,
    );

    if (sleepDuration.inHours < 7) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Health Alert'),
            ],
          ),
          content: Text(
            'You\'ve scheduled ${sleepDuration.inHours} hours and ${sleepDuration.inMinutes % 60} minutes of sleep.\n\n'
            'Medical experts recommend at least 7-9 hours for optimal productivity and health.\n\n'
            'Would you like to adjust your schedule?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Adjust Schedule'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onNext(_sleepTime!, _wakeTime!);
              },
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );
    } else {
      widget.onNext(_sleepTime!, _wakeTime!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepDuration = _sleepTime != null && _wakeTime != null
        ? PreferencesHelper.calculateSleepDuration(_sleepTime!, _wakeTime!)
        : null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bedtime, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Sleep Schedule',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When do you usually sleep and wake up? This helps us avoid scheduling tasks during your rest time.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Sleep Time
          _TimeSelector(
            label: 'Sleep Time',
            icon: Icons.nightlight_round,
            time: _sleepTime,
            onTap: () => _selectTime(context, true),
          ),
          const SizedBox(height: 16),

          // Wake Time
          _TimeSelector(
            label: 'Wake Up Time',
            icon: Icons.wb_sunny,
            time: _wakeTime,
            onTap: () => _selectTime(context, false),
          ),

          // Sleep Duration Display
          if (sleepDuration != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sleepDuration.inHours >= 7
                      ? AppColors.success.withAlpha(26)
                      : AppColors.warning.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sleepDuration.inHours >= 7
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sleepDuration.inHours >= 7
                          ? Icons.check_circle
                          : Icons.info,
                      color: sleepDuration.inHours >= 7
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Total sleep: ${sleepDuration.inHours}h ${sleepDuration.inMinutes % 60}m',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sleepDuration.inHours >= 7
                              ? AppColors.success
                              : AppColors.warning,
                        ),
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

  const _TimeSelector({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
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
