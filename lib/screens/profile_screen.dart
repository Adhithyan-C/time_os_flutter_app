// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/database/database_helper.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';
import 'package:time_os_final/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';
  String _userInitials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await PreferencesHelper.getUserName();

    setState(() {
      _userName = name;
      _userInitials = _generateInitials(name);
    });
  }

  String _generateInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'U';

    final nameParts = trimmedName.split(' ');

    if (nameParts.length == 1) {
      return trimmedName
          .substring(0, trimmedName.length >= 2 ? 2 : 1)
          .toUpperCase();
    } else {
      final firstInitial = nameParts.first[0];
      final lastInitial = nameParts.last[0];
      return (firstInitial + lastInitial).toUpperCase();
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete all your tasks and events?',
                ),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
              onPressed: () async {
                await DatabaseHelper.instance.deleteAllData();
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been deleted.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditPreferencesScreen()),
    ).then((_) => _loadUserData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Text(
                  _userInitials,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _navigateToEditPreferences,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Preferences'),
            ),
            const Divider(height: 32),

            _PreferenceSection(
              icon: Icons.bedtime,
              title: 'Sleep & Work Schedule',
              onTap: _navigateToEditPreferences,
            ),
            _PreferenceSection(
              icon: Icons.psychology,
              title: 'Productivity Settings',
              onTap: _navigateToEditPreferences,
            ),
            _PreferenceSection(
              icon: Icons.timer,
              title: 'Work Style & Breaks',
              onTap: _navigateToEditPreferences,
            ),

            const Divider(height: 32),
            const Text(
              'Stats (Coming Soon)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This area will show your productivity stats in a future update.',
              style: TextStyle(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: AppColors.danger),
                label: const Text(
                  'Delete All Data',
                  style: TextStyle(color: AppColors.danger),
                ),
                onPressed: _showDeleteConfirmationDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PreferenceSection({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
      onTap: onTap,
    );
  }
}

// Edit Preferences Screen
class EditPreferencesScreen extends StatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  final _nameController = TextEditingController();
  TimeOfDay? _sleepStart;
  TimeOfDay? _sleepEnd;
  TimeOfDay? _dayStart;
  TimeOfDay? _dayEnd;
  PeakProductivityWindow? _peakWindow;
  int? _workBlock;
  int? _breakDuration;
  int? _maxHardTasks;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final name = await PreferencesHelper.getUserName();
    final sleepStart = await PreferencesHelper.getSleepStartTime();
    final sleepEnd = await PreferencesHelper.getSleepEndTime();
    final dayStart = await PreferencesHelper.getDayStartTime();
    final dayEnd = await PreferencesHelper.getDayEndTime();
    final peakWindow = await PreferencesHelper.getPeakProductivityWindow();
    final workBlock = await PreferencesHelper.getPreferredWorkBlockMinutes();
    final breakDuration = await PreferencesHelper.getAutoBreakDuration();
    final maxHardTasks = await PreferencesHelper.getMaxHardTasksPerDay();

    setState(() {
      _nameController.text = name;
      _sleepStart = sleepStart;
      _sleepEnd = sleepEnd;
      _dayStart = dayStart;
      _dayEnd = dayEnd;
      _peakWindow = peakWindow;
      _workBlock = workBlock;
      _breakDuration = breakDuration;
      _maxHardTasks = maxHardTasks;
    });
  }

  Future<void> _savePreferences() async {
    await PreferencesHelper.setUserName(_nameController.text);
    await PreferencesHelper.setSleepSchedule(_sleepStart!, _sleepEnd!);
    await PreferencesHelper.setDayWindow(_dayStart!, _dayEnd!);
    await PreferencesHelper.setPeakProductivityWindow(_peakWindow!);
    await PreferencesHelper.setPreferredWorkBlockMinutes(_workBlock!);
    await PreferencesHelper.setAutoBreakDuration(_breakDuration!);
    await PreferencesHelper.setMaxHardTasksPerDay(_maxHardTasks!);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Preferences saved!')));
    Navigator.pop(context);
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    TimeOfDay? initial;
    switch (type) {
      case 'sleepStart':
        initial = _sleepStart;
        break;
      case 'sleepEnd':
        initial = _sleepEnd;
        break;
      case 'dayStart':
        initial = _dayStart;
        break;
      case 'dayEnd':
        initial = _dayEnd;
        break;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'sleepStart':
            _sleepStart = picked;
            break;
          case 'sleepEnd':
            _sleepEnd = picked;
            break;
          case 'dayStart':
            _dayStart = picked;
            break;
          case 'dayEnd':
            _dayEnd = picked;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preferences'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        actions: [
          TextButton(onPressed: _savePreferences, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            const Text(
              'Sleep Schedule',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Sleep',
                    time: _sleepStart,
                    onTap: () => _selectTime(context, 'sleepStart'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeButton(
                    label: 'Wake',
                    time: _sleepEnd,
                    onTap: () => _selectTime(context, 'sleepEnd'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Work Window',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Day Start',
                    time: _dayStart,
                    onTap: () => _selectTime(context, 'dayStart'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeButton(
                    label: 'Day End',
                    time: _dayEnd,
                    onTap: () => _selectTime(context, 'dayEnd'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Peak Productivity',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PeakProductivityWindow>(
              value: _peakWindow,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: PeakProductivityWindow.values.map((window) {
                return DropdownMenuItem(
                  value: window,
                  child: Text(window.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) => setState(() => _peakWindow = value),
            ),
            const SizedBox(height: 24),

            const Text(
              'Work Block (minutes)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _workBlock,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text('No Preference')),
                DropdownMenuItem(value: 30, child: Text('30 min (Sprint)')),
                DropdownMenuItem(value: 60, child: Text('60 min (Balanced)')),
                DropdownMenuItem(value: 90, child: Text('90 min (Deep Work)')),
              ],
              onChanged: (value) => setState(() => _workBlock = value),
            ),
            const SizedBox(height: 24),

            const Text(
              'Break Duration (minutes)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _breakDuration,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 0, child: Text('No Breaks')),
                DropdownMenuItem(value: 5, child: Text('5 minutes')),
                DropdownMenuItem(value: 10, child: Text('10 minutes')),
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
              ],
              onChanged: (value) => setState(() => _breakDuration = value),
            ),
            const SizedBox(height: 24),

            const Text(
              'Max Hard Tasks Per Day',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _maxHardTasks,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 2, child: Text('1-2 (Gentle)')),
                DropdownMenuItem(value: 3, child: Text('2-3 (Balanced)')),
                DropdownMenuItem(value: 4, child: Text('3-4 (High Energy)')),
              ],
              onChanged: (value) => setState(() => _maxHardTasks = value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondaryText),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              time?.format(context) ?? '--:--',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
