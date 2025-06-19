import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final DocumentSnapshot eventData;
  final bool isRegistered;

  const EventDetailScreen({
    super.key,
    required this.eventData,
    required this.isRegistered,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _isRegistered = widget.isRegistered;
  }

  Future<void> registerForEvent() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final eventId = widget.eventData.id;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .where('eventId', isEqualTo: eventId)
          .get();

      if (snapshot.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('registrations').add({
          'eventId': eventId,
          'userId': userId,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Successfully registered')),
        );

        setState(() => _isRegistered = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ℹ️ Already registered')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;
    final date = event['dateTime'] != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(event['dateTime'].toDate())
        : 'No date';

    return Scaffold(
      appBar: AppBar(title: Text(event['title'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (event['imageUrl'] != null && event['imageUrl'] != '')
              Image.network(event['imageUrl']),
            const SizedBox(height: 16),
            Text(
              event['title'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('📍 Location: ${event['location']}'),
            Text('🗓 Date: $date'),
            const SizedBox(height: 12),
            Text(event['description']),
            const SizedBox(height: 24),
            _isRegistered
                ? const Text('✅ You are registered for this event.', style: TextStyle(color: Colors.green))
                : ElevatedButton(
                    onPressed: registerForEvent,
                    child: const Text('Register for Event'),
                  ),
          ],
        ),
      ),
    );
  }
}
