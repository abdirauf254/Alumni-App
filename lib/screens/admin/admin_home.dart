import 'package:flutter/material.dart';
import 'package:flutterauthentication/screens/user/announcements_screen.dart';
import 'dashboard_screen.dart';
import 'manage_users_screen.dart';
import 'create_event_screen.dart';
import 'user_messages_screen.dart';
import 'push_notification_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ManageUsersScreen(),
    CreateEventScreen(),
    AnnouncementsScreen(),
    UserMessagesScreen(),
    PushNotificationScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Manage Users',
    'Create Event',
    'Announcements',
    'User Messages',
    'Push Notifications',
  ];

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Close the drawer
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Add logout logic
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color.from(alpha: 0.788, red: 0.039, green: 0.055, blue: 0.945)),
              child: Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
            _buildDrawerItem(Icons.group, 'Manage Users', 1),
            _buildDrawerItem(Icons.event, 'Create Event', 2),
            _buildDrawerItem(Icons.announcement, 'Announcements', 3),
            _buildDrawerItem(Icons.message, 'User Messages', 4),
            _buildDrawerItem(Icons.notifications, 'Push Notifications', 5),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
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
