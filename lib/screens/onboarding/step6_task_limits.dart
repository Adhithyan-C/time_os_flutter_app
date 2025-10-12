// lib/screens/onboarding/step6_task_limits.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';

class Step6TaskLimits extends StatefulWidget {
  final Function(int) onNext;

  const Step6TaskLimits({super.key, required this.onNext});

  @override
  State<Step6TaskLimits> createState() => _Step6TaskLimitsState();
}

class _Step6TaskLimitsState extends State<Step6TaskLimits> {
  int? _maxHardTasks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.trending_up, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Daily Task Load',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How many difficult tasks per day feels manageable? This helps prevent burnout and ensures sustainable productivity.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _TaskLoadOption(
            emoji: '🔥',
            title: 'High Energy',
            subtitle: '3-4 hard tasks per day',
            description:
                'I thrive on challenging work and can handle multiple difficult tasks',
            value: 4,
            color: AppColors.danger,
            isSelected: _maxHardTasks == 4,
            onTap: () => setState(() => _maxHardTasks = 4),
          ),
          const SizedBox(height: 12),

          _TaskLoadOption(
            emoji: '⚖️',
            title: 'Balanced',
            subtitle: '2-3 hard tasks per day',
            description:
                'A healthy mix of challenging and easier work keeps me motivated',
            value: 3,
            color: AppColors.warning,
            isSelected: _maxHardTasks == 3,
            onTap: () => setState(() => _maxHardTasks = 3),
          ),
          const SizedBox(height: 12),

          _TaskLoadOption(
            emoji: '🌱',
            title: 'Gentle Pace',
            subtitle: '1-2 hard tasks per day',
            description:
                'I prefer to focus deeply on one or two challenging tasks',
            value: 2,
            color: AppColors.success,
            isSelected: _maxHardTasks == 2,
            onTap: () => setState(() => _maxHardTasks = 2),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Don\'t worry - you can always change this later in your profile settings.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withAlpha(230),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _maxHardTasks != null
                  ? () => widget.onNext(_maxHardTasks!)
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

class _TaskLoadOption extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final int value;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaskLoadOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.value,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(26) : null,
          border: Border.all(
            color: isSelected ? color : AppColors.secondaryText.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}
