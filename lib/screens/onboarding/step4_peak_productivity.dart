// lib/screens/onboarding/step4_peak_productivity.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';

class Step4PeakProductivity extends StatefulWidget {
  final Function(PeakProductivityWindow) onNext;

  const Step4PeakProductivity({super.key, required this.onNext});

  @override
  State<Step4PeakProductivity> createState() => _Step4PeakProductivityState();
}

class _Step4PeakProductivityState extends State<Step4PeakProductivity> {
  PeakProductivityWindow? _selectedWindow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Peak Productivity',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'When are you most productive? We\'ll prioritize scheduling difficult tasks during your peak hours.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          _ProductivityOption(
            icon: Icons.wb_sunny,
            emoji: '🌅',
            title: 'Morning Person',
            subtitle: '6 AM - 12 PM',
            description: 'I\'m most alert and focused in the morning',
            isSelected: _selectedWindow == PeakProductivityWindow.morning,
            onTap: () => setState(
              () => _selectedWindow = PeakProductivityWindow.morning,
            ),
          ),
          const SizedBox(height: 12),

          _ProductivityOption(
            icon: Icons.wb_twilight,
            emoji: '☀️',
            title: 'Afternoon Person',
            subtitle: '12 PM - 6 PM',
            description: 'I hit my stride after lunch',
            isSelected: _selectedWindow == PeakProductivityWindow.afternoon,
            onTap: () => setState(
              () => _selectedWindow = PeakProductivityWindow.afternoon,
            ),
          ),
          const SizedBox(height: 12),

          _ProductivityOption(
            icon: Icons.nightlight_round,
            emoji: '🌙',
            title: 'Evening Person',
            subtitle: '6 PM - 12 AM',
            description: 'I work best when it\'s quiet at night',
            isSelected: _selectedWindow == PeakProductivityWindow.evening,
            onTap: () => setState(
              () => _selectedWindow = PeakProductivityWindow.evening,
            ),
          ),
          const SizedBox(height: 12),

          _ProductivityOption(
            icon: Icons.all_inclusive,
            emoji: '🤷',
            title: 'No Preference',
            subtitle: 'Anytime works',
            description: 'I\'m flexible throughout the day',
            isSelected: _selectedWindow == PeakProductivityWindow.none,
            onTap: () =>
                setState(() => _selectedWindow = PeakProductivityWindow.none),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedWindow != null
                  ? () => widget.onNext(_selectedWindow!)
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

class _ProductivityOption extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductivityOption({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
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
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
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
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
