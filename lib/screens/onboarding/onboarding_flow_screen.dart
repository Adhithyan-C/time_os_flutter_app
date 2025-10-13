// lib/screens/onboarding/onboarding_flow_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/screens/onboarding/step1_welcome.dart';
import 'package:time_os_final/screens/onboarding/step2_sleep_schedule.dart';
import 'package:time_os_final/screens/onboarding/step3_work_window.dart';
import 'package:time_os_final/screens/onboarding/step4_peak_productivity.dart';
import 'package:time_os_final/screens/onboarding/step5_work_style.dart';
import 'package:time_os_final/screens/onboarding/step6_task_limits.dart';
import 'package:time_os_final/screens/onboarding/step_weekly_events.dart'; // NEW
import 'package:time_os_final/screens/onboarding/step7_complete.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';
import 'package:time_os_final/theme.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 8; // CHANGED FROM 7 to 8

  // Collected data
  String userName = '';
  TimeOfDay? sleepStart;
  TimeOfDay? sleepEnd;
  TimeOfDay? dayStart;
  TimeOfDay? dayEnd;
  PeakProductivityWindow peakWindow = PeakProductivityWindow.none;
  int workBlockMinutes = 0;
  int breakMinutes = 0;
  int maxHardTasks = 3;

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _previousStep,
                        )
                      else
                        const SizedBox(width: 48),
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.tertiary,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ],
              ),
            ),
            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  Step1Welcome(
                    onNext: (name) {
                      userName = name;
                      _nextStep();
                    },
                  ),
                  Step2SleepSchedule(
                    onNext: (start, end) {
                      sleepStart = start;
                      sleepEnd = end;
                      _nextStep();
                    },
                  ),
                  Step3WorkWindow(
                    wakeTime: sleepEnd ?? const TimeOfDay(hour: 7, minute: 0),
                    sleepTime:
                        sleepStart ?? const TimeOfDay(hour: 23, minute: 0),
                    onNext: (start, end) {
                      dayStart = start;
                      dayEnd = end;
                      _nextStep();
                    },
                  ),
                  Step4PeakProductivity(
                    onNext: (window) {
                      peakWindow = window;
                      _nextStep();
                    },
                  ),
                  Step5WorkStyle(
                    onNext: (workBlock, breakDuration) {
                      workBlockMinutes = workBlock;
                      breakMinutes = breakDuration;
                      _nextStep();
                    },
                  ),
                  Step6TaskLimits(
                    onNext: (maxTasks) {
                      maxHardTasks = maxTasks;
                      _nextStep();
                    },
                  ),
                  // NEW STEP: Weekly Events
                  StepWeeklyEvents(onNext: () => _nextStep()),
                  Step7Complete(
                    userName: userName,
                    onComplete: _completeOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // Save all preferences
    await PreferencesHelper.setUserName(userName);
    await PreferencesHelper.setSleepSchedule(
      sleepStart ?? const TimeOfDay(hour: 23, minute: 0),
      sleepEnd ?? const TimeOfDay(hour: 7, minute: 0),
    );
    await PreferencesHelper.setDayWindow(
      dayStart ?? const TimeOfDay(hour: 9, minute: 0),
      dayEnd ?? const TimeOfDay(hour: 22, minute: 0),
    );
    await PreferencesHelper.setPeakProductivityWindow(peakWindow);
    await PreferencesHelper.setPreferredWorkBlockMinutes(workBlockMinutes);
    await PreferencesHelper.setAutoBreakDuration(breakMinutes);
    await PreferencesHelper.setMaxHardTasksPerDay(maxHardTasks);
    await PreferencesHelper.setHasOnboarded(true);

    if (!mounted) return;

    // Navigate to main screen
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
