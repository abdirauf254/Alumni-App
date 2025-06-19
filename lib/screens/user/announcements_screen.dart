import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            itemCount: announcements.length,
         itemBuilder: (context, index) {
  final announcement = announcements[index];
  final data = announcement.data() as Map<String, dynamic>; // ✅ Fix here

  final title = data['title'] ?? 'No Title';
  final description = data['description'] ?? '';
  final category = data.containsKey('category') ? data['category'] : 'General';

  final timestamp = data['createdAt'];
  final createdAt = timestamp != null && timestamp is Timestamp
      ? timestamp.toDate()
      : DateTime.now();

  return Card(
    margin: const EdgeInsets.all(12),
    child: ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 4),
          Text('Category: $category'),
          const SizedBox(height: 4),
          Text('Posted on: ${DateFormat.yMMMd().add_jm().format(createdAt)}'),
        ],
      ),
    ),
  );
}
,
          );
        },
      ),
    );
  }
}
