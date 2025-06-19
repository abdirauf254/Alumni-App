import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text(
              'Welcome to Alumni Portal!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: ListTile(
                leading: Icon(Icons.person, color: Colors.blueAccent),
                title: Text('View & Edit Your Profile'),
                subtitle: Text('Update your personal information'),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: ListTile(
                leading: const Icon(Icons.group, color: Colors.green),
                title: const Text('Alumni Directory'),
                subtitle: const Text('Explore and connect with alumni'),
                onTap: () {
                  // Optional: Navigate to Alumni tab or page
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.orange),
                title: const Text('Upcoming Events'),
                subtitle: const Text('Check alumni meetups and webinars'),
                onTap: () {
                  // Optional: Navigate to Events tab or page
                },
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: ListTile(
                leading: const Icon(Icons.announcement, color: Colors.purple),
                title: const Text('News & Announcements'),
                subtitle: const Text('Latest alumni news and updates'),
                onTap: () {
                  // Optional: Navigate to Announcements tab or page
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
