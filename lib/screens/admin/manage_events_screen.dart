import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_event_screen.dart';

class ManageEventsScreen extends StatefulWidget {
  @override
  _ManageEventsScreenState createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final List<DocumentSnapshot> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('dateTime', descending: true)
        .get();

    setState(() {
      _events.clear();
      _events.addAll(querySnapshot.docs);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Events')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(child: Text('No events found.'))
              : ListView.builder(
                  itemCount: _events.length,
                itemBuilder: (context, index) {
  final event = _events[index];
  final imageUrl = event['imageUrl'] as String?;
  final title = event['title'] as String? ?? '';
  final description = event['description'] as String? ?? '';
  final dateTime = DateTime.parse(event['dateTime']); // 👈 FIXED

  return ListTile(
    leading: imageUrl != null
        ? Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
        : Icon(Icons.event),
    title: Text(title),
    subtitle: Text(
        '${description}\n${dateTime.toLocal().toString().split(' ')[0]}'),
    isThreeLine: true,
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditEventScreen(
            eventId: event.id,
          ),
        ),
      ).then((_) => _fetchEvents());
    },
  );
}   
                ),
    );
  }
}