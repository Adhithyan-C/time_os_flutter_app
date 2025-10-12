// lib/screens/onboarding/step5_work_style.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';

class Step5WorkStyle extends StatefulWidget {
  final Function(int workBlockMinutes, int breakMinutes) onNext;

  const Step5WorkStyle({super.key, required this.onNext});

  @override
  State<Step5WorkStyle> createState() => _Step5WorkStyleState();
}

class _Step5WorkStyleState extends State<Step5WorkStyle> {
  int? _workBlockMinutes;
  int? _breakMinutes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Work Style',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How do you prefer to work? This helps us schedule tasks in a way that matches your natural rhythm.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'Preferred work block duration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),

          _WorkBlockOption(
            icon: Icons.flash_on,
            title: 'Sprint Mode',
            subtitle: '25-30 minutes',
            description: 'Short, focused bursts (Pomodoro style)',
            value: 30,
            isSelected: _workBlockMinutes == 30,
            onTap: () => setState(() => _workBlockMinutes = 30),
          ),
          const SizedBox(height: 8),

          _WorkBlockOption(
            icon: Icons.balance,
            title: 'Balanced',
            subtitle: '45-60 minutes',
            description: 'Standard work sessions',
            value: 60,
            isSelected: _workBlockMinutes == 60,
            onTap: () => setState(() => _workBlockMinutes = 60),
          ),
          const SizedBox(height: 8),

          _WorkBlockOption(
            icon: Icons.psychology_alt,
            title: 'Deep Work',
            subtitle: '90-120 minutes',
            description: 'Extended focus periods',
            value: 90,
            isSelected: _workBlockMinutes == 90,
            onTap: () => setState(() => _workBlockMinutes = 90),
          ),
          const SizedBox(height: 8),

          _WorkBlockOption(
            icon: Icons.all_inclusive,
            title: 'No Preference',
            subtitle: 'Flexible',
            description: 'I\'ll decide per task',
            value: 0,
            isSelected: _workBlockMinutes == 0,
            onTap: () => setState(() => _workBlockMinutes = 0),
          ),

          const SizedBox(height: 24),

          const Text(
            'Break duration between tasks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _BreakChip(
                label: 'No breaks',
                minutes: 0,
                isSelected: _breakMinutes == 0,
                onTap: () => setState(() => _breakMinutes = 0),
              ),
              const SizedBox(width: 8),
              _BreakChip(
                label: '5 min',
                minutes: 5,
                isSelected: _breakMinutes == 5,
                onTap: () => setState(() => _breakMinutes = 5),
              ),
              const SizedBox(width: 8),
              _BreakChip(
                label: '10 min',
                minutes: 10,
                isSelected: _breakMinutes == 10,
                onTap: () => setState(() => _breakMinutes = 10),
              ),
              const SizedBox(width: 8),
              _BreakChip(
                label: '15 min',
                minutes: 15,
                isSelected: _breakMinutes == 15,
                onTap: () => setState(() => _breakMinutes = 15),
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _workBlockMinutes != null && _breakMinutes != null
                  ? () => widget.onNext(_workBlockMinutes!, _breakMinutes!)
                  : null,
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

class _WorkBlockOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _WorkBlockOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(26) : null,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.secondaryText.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.secondaryText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primaryText,
                    ),
                  ),
                  Text(
                    '$subtitle • $description',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakChip extends StatelessWidget {
  final String label;
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _BreakChip({
    required this.label,
    required this.minutes,
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
            color: isSelected ? AppColors.primary : AppColors.tertiary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? AppColors.textOnPrimary
                  : AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
