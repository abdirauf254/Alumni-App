import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Optional: if using Firebase Auth
import 'dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'push_notification_screen.dart';
import 'create_event_screen.dart';
import 'manage_events_screen.dart';
import 'create_announcements_screen.dart';
import 'manage_announcements_screen.dart';
import 'view_feedbacks_screen.dart';


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
  'View Feedbacks',
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
    ViewFeedbacksScreen(), // Ensure this screen is implemented
    ];
  }

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Close drawer
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login'); // Make sure this route exists
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
            onPressed: () => _logout(context),
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
            _buildDrawerItem(Icons.feedback, 'View Feedbacks', 7),

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
