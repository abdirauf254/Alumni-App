import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'edit_event_screen.dart';

class ManageEventsScreen extends StatefulWidget {
  @override
  _ManageEventsScreenState createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<ManageEventsScreen> {
  final List<DocumentSnapshot> _allEvents = [];
  List<DocumentSnapshot> _filteredEvents = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
      _allEvents.clear();
      _allEvents.addAll(querySnapshot.docs);
      _filteredEvents = List.from(_allEvents);
      _isLoading = false;
    });
  }

  void _filterEvents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredEvents = _allEvents.where((event) {
        final title = (event['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event deleted successfully')));
        _fetchEvents(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete event: $e')));
      }
    }
  }

  void _viewEvent(DocumentSnapshot event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('View Event'),
        content: Text('Do you want to view this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('View')),
        ],
      ),
    );

    if (confirm == true) {
      final imageUrl = event['imageUrl'] as String?;
      final title = event['title'] ?? '';
      final description = event['description'] ?? '';
      final rawDate = event['dateTime'];
      DateTime dateTime;

      if (rawDate is Timestamp) {
        dateTime = rawDate.toDate();
      } else if (rawDate is String) {
        dateTime = DateTime.parse(rawDate);
      } else {
        dateTime = DateTime.now();
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Image.network(imageUrl),
              SizedBox(height: 10),
              Text(description),
              SizedBox(height: 10),
              Text('Date: ${dateTime.toLocal().toString().split(' ')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _editEvent(DocumentSnapshot event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Event'),
        content: Text('Do you want to edit this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Edit')),
        ],
      ),
    );

    if (confirm == true) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => EditEventScreen(eventId: event.id)))
          .then((_) => _fetchEvents());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterEvents,
              decoration: InputDecoration(
                labelText: 'Search by title',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                    ? Center(child: Text('No events found.'))
                    : ListView.builder(
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          final imageUrl = event['imageUrl'] as String?;
                          final title = event['title'] as String? ?? '';
                          final description = event['description'] as String? ?? '';
                          final rawDate = event['dateTime'];
                          DateTime dateTime;

                          if (rawDate is Timestamp) {
                            dateTime = rawDate.toDate();
                          } else if (rawDate is String) {
                            dateTime = DateTime.parse(rawDate);
                          } else {
                            dateTime = DateTime.now();
                          }

                          return ListTile(
                            leading: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                                : Icon(Icons.event),
                            title: Text(title),
                            subtitle: Text(
                                '${description}\n${dateTime.toLocal().toString().split(' ')[0]}'),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'view') {
                                  _viewEvent(event);
                                } else if (value == 'edit') {
                                  _editEvent(event);
                                } else if (value == 'delete') {
                                  _deleteEvent(event.id);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'view', child: Text('View')),
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
