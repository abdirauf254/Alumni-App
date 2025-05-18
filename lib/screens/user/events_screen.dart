import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  Future<void> rsvpEvent(String eventId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('rsvps')
        .doc(uid)
        .set({'attending': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upcoming Events")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!.docs;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(event['title'] ?? 'Untitled'),
                  subtitle: Text(event['date'] ?? 'No Date'),
                  trailing: ElevatedButton(
                    onPressed: () => rsvpEvent(events[index].id),
                    child: const Text('RSVP'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

