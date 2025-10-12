// lib/screens/onboarding/step7_complete.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';

class Step7Complete extends StatelessWidget {
  final String userName;
  final VoidCallback onComplete;

  const Step7Complete({
    super.key,
    required this.userName,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re All Set, $userName!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'TIME_OS is now personalized to your schedule and work style. Let\'s start scheduling your success!',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          _FeatureHighlight(
            icon: Icons.auto_awesome,
            title: 'Smart Scheduling',
            description: 'Tasks are automatically placed in your free time',
          ),
          const SizedBox(height: 16),

          _FeatureHighlight(
            icon: Icons.psychology,
            title: 'Peak Performance',
            description: 'Difficult tasks scheduled during your best hours',
          ),
          const SizedBox(height: 16),

          _FeatureHighlight(
            icon: Icons.balance,
            title: 'Sustainable Pace',
            description: 'Workload balanced to prevent burnout',
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Using TIME_OS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onComplete,
            child: const Text(
              'You can customize these settings anytime in your profile',
              style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}
