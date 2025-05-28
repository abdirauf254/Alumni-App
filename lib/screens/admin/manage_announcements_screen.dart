import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  State<ManageAnnouncementsScreen> createState() =>
      _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _perPage = 10;

  List<DocumentSnapshot> _announcements = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _fetchAnnouncements() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(_perPage);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      _announcements.addAll(snapshot.docs);
    } else {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchAnnouncements();
    }
  }

  void _confirmView(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data?['title'] ?? 'No Title'),
        content: Text(data?['description'] ?? 'No Description'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAnnouncement(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
      setState(() {
        _announcements.removeWhere((doc) => doc.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Announcement deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to delete: $e')),
      );
    }
  }

  void _editAnnouncement(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final titleController = TextEditingController(text: data?['title'] ?? '');
    final descriptionController = TextEditingController(text: data?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Edit'),
                  content: const Text('Are you sure you want to update this announcement?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await FirebaseFirestore.instance.collection('announcements').doc(doc.id).update({
                    'title': titleController.text,
                    'description': descriptionController.text,
                  });
                  setState(() {
                    final index = _announcements.indexWhere((d) => d.id == doc.id);
                    if (index != -1) {
                      _announcements[index] = doc;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Announcement updated')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Failed to update: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAnnouncements = _announcements.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final title = data?['title']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Announcements')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by title',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredAnnouncements.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= filteredAnnouncements.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final doc = filteredAnnouncements[index];
                final data = doc.data() as Map<String, dynamic>?;

                final title = data?['title'] ?? 'No Title';
                final description = data?['description'] ?? 'No Description';
                final timestamp = data?['createdAt'] as Timestamp?;
                final createdAt = timestamp?.toDate();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () => _confirmView(doc),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(description),
                        if (createdAt != null)
                          Text(
                            'Posted on ${createdAt.toLocal()}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                       children: [
                         IconButton(
                           icon: const Icon(Icons.visibility, color: Colors.green),
                             onPressed: () => _confirmView(doc),
                          ),
                       IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editAnnouncement(doc),
                          ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                               onPressed: () => _confirmDelete(doc.id),
                        ),
                     ],
                  ),

                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
