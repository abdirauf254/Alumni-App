import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<Map<String, int>> _fetchMetrics() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final eventsSnapshot = await FirebaseFirestore.instance.collection('events').get();
    final announcementsSnapshot = await FirebaseFirestore.instance.collection('announcements').get();
    final messagesSnapshot = await FirebaseFirestore.instance.collection('messages').get();

    int totalUsers = 0;
    int totalAdmins = 0;

    for (var doc in usersSnapshot.docs) {
      final role = doc.data()['role'];
      if (role == 'admin') {
        totalAdmins++;
      } else {
        totalUsers++;
      }
    }

    return {
      'alumni': totalUsers,
      'admins': totalAdmins,
      'events': eventsSnapshot.size,
      'announcements': announcementsSnapshot.size,
      'messages': messagesSnapshot.size,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchMetrics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        final data = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Alumni Users', data['alumni']!, Colors.blue),
              _buildStatCard('Admins', data['admins']!, Colors.green),
              _buildStatCard('Events', data['events']!, Colors.orange),
              _buildStatCard('Announcements', data['announcements']!, Colors.purple),
              _buildStatCard('Messages', data['messages']!, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: ListTile(
          title: Text(
            count.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          subtitle: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
