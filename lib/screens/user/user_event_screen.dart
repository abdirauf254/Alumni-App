import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserEventScreen extends StatelessWidget {
  const UserEventScreen({super.key});

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('User Events')),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('dateTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            // ✅ PLACE THIS HERE:
            final event = events[index];
            final title = event['title'] ?? 'No Title';
            final description = event['description'] ?? '';
            final location = event['location'] ?? '';

            final rawDate = event['dateTime'];
            DateTime? dateTime;

            if (rawDate is Timestamp) {
              dateTime = rawDate.toDate();
            } else if (rawDate is String) {
              dateTime = DateTime.tryParse(rawDate);
            }

            return Card(
  margin: const EdgeInsets.all(12),
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(description),
        const SizedBox(height: 4),
        Text('📍 Location: $location'),
        const SizedBox(height: 4),
        Text('📅 Date: ${dateTime != null ? DateFormat.yMMMd().add_jm().format(dateTime) : 'Invalid Date'}'),
        const SizedBox(height: 10),
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('events')
              .doc(event.id)
              .collection('registrations')
              .doc(FirebaseFirestore.instance.app.options.projectId) // Replace with user ID!
              .get(),
          builder: (context, regSnapshot) {
            if (regSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final isRegistered = regSnapshot.data?.exists ?? false;

            return ElevatedButton.icon(
              icon: Icon(isRegistered ? Icons.check : Icons.event_available),
              label: Text(isRegistered ? 'Registered' : 'Register'),
              onPressed: isRegistered
                  ? null
                  : () async {
                      final user = FirebaseFirestore.instance.app.options.projectId; // 👈 Replace with real UID
                      await FirebaseFirestore.instance
                          .collection('events')
                          .doc(event.id)
                          .collection('registrations')
                          .doc(user)
                          .set({
                        'userId': user,
                        'registeredAt': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Registered for event!')),
                      );
                    },
            );
          },
        ),
      ],
    ),
  ),
);
            // ✅ PLACE THIS HERE
            // Wrap the Card widget with Padding for better spacing
            // and use FutureBuilder to check registration status
          },
        );
      },
    ),
  );
}

}
