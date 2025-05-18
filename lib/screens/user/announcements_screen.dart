import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final announcements = snapshot.data!.docs;
          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final data = announcements[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.campaign),
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['description'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
