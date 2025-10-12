// lib/screens/onboarding/step1_welcome.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';

class Step1Welcome extends StatefulWidget {
  final Function(String) onNext;

  const Step1Welcome({super.key, required this.onNext});

  @override
  State<Step1Welcome> createState() => _Step1WelcomeState();
}

class _Step1WelcomeState extends State<Step1Welcome> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      widget.onNext(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.waving_hand, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Welcome to TIME_OS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your AI-powered productivity companion that helps you schedule smarter, not harder.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'What should I call you?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'e.g., Alex',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleNext(),
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
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
