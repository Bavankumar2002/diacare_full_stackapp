// =============================================================================
// DiaCare - Main Navigation Screen with 5 Core Tabs
// =============================================================================

import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'home/home_dashboard_screen.dart';
import 'tracker/sugar_tracker_screen.dart';
import 'calories/calorie_tracker_screen.dart';
import 'reminders/reminders_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    SugarTrackerScreen(),
    CalorieTrackerScreen(),
    RemindersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        indicatorColor: AppConstants.primaryTealLight,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppConstants.primaryTeal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop_rounded, color: AppConstants.primaryTeal),
            label: 'Tracker',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded, color: AppConstants.primaryTeal),
            label: 'Calories',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm_rounded, color: AppConstants.primaryTeal),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppConstants.primaryTeal),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
