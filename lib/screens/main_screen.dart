import 'package:flutter/material.dart';
import 'package:health_healing/screens/calendar_screen.dart'; // Placeholder
import 'package:health_healing/screens/home_screen.dart'; // Placeholder
import 'package:health_healing/screens/profile_screen.dart'; // Placeholder

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Define the screens for each tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Placeholder for Home
    CalendarScreen(), // Placeholder for Calendar
    ProfileScreen(), // Placeholder for Profile/Settings
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Theme properties are applied via BottomNavigationBarThemeData in theme.dart
      ),
    );
  }
}

