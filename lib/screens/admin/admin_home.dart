import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Optional: if using Firebase Auth
import 'dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'push_notification_screen.dart';
import 'create_event_screen.dart';
import 'manage_events_screen.dart';
import 'create_announcements_screen.dart';
import 'manage_announcements_screen.dart';


class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;
  final List<String> _titles = [
   'Dashboard',
  'Manage Users',
  'Create Event',
  'Manage Events',
  'Create Announcement',
  'Manage Announcements',
  'Push Notifications',
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
    DashboardScreen(),
    ManageUsersScreen(),
    CreateEventScreen(),
    ManageEventsScreen(),
    CreateAnnouncementsScreen(),
    ManageAnnouncementsScreen(),
    PushNotificationScreen(),
    ];
  }

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Close drawer
    });
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut(); // If using Firebase Auth
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(201, 10, 14, 241),
              ),
              child: Text(
                'Admin Panel',
                style: TextStyle(
                  color: Color.fromARGB(233, 219, 219, 223),
                  fontSize: 24,
                ),
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
            _buildDrawerItem(Icons.group, 'Manage Users', 1),
            _buildDrawerItem(Icons.event, 'Create Event', 2),
            _buildDrawerItem(Icons.event_available, 'Manage Events', 3),
            _buildDrawerItem(Icons.campaign, 'Create Announcement', 4),
            _buildDrawerItem(Icons.manage_search, 'Manage Announcements', 5),
            _buildDrawerItem(Icons.notifications, 'Push Notifications', 6),

          ],
        ),
      ),
      body: _screens.asMap().containsKey(_selectedIndex)
          ? _screens[_selectedIndex]
          : const Center(child: Text('Page not found')),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: index == _selectedIndex,
      onTap: () => _onSelect(index),
    );
  }
}
