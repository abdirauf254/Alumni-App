import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'alumni_list_screen.dart';
import 'events_screen.dart';
import 'announcements_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ProfileScreen(),
    AlumniListScreen(),
    EventsScreen(),
    AnnouncementsScreen(),
  ];

  final List<String> _titles = [
    'Profile',
    'Alumni',
    'Events',
    'Announcements',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Alumni'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.announcement), label: 'News'),
        ],
      ),
    );
  }
}
