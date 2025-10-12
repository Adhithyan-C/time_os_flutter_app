// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/theme.dart';
import 'package:time_os_final/screens/profile_screen.dart';
import 'package:time_os_final/screens/home_screen.dart';
import 'package:time_os_final/screens/tasks_screen.dart';
import 'package:time_os_final/screens/schedule_screen.dart';

// This is the main screen of your app after the user has onboarded.
// It contains the bottom navigation bar and switches between the main pages.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // The index of the currently selected tab.

  // The list of all our main screens.
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    TasksScreen(),
    ScheduleScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens.elementAt(
        _selectedIndex,
      ), // Shows the currently selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tasks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // These settings make the bottom bar look and feel good
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
