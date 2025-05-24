import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  State<ManageAnnouncementsScreen> createState() => _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String _searchQuery = '';
  List<DocumentSnapshot> _announcements = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _fetchAnnouncements();
  }

  Future<void> _fetchUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = userDoc['role'];
      });
    }
  }

  Future<void> _fetchAnnouncements() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    Query query = _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(_limit);

    if (_searchQuery.isNotEmpty) {
      query = query.where('title', isGreaterThanOrEqualTo: _searchQuery)
                   .where('title', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
    }

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.length < _limit) {
      _hasMore = false;
    }

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      setState(() {
        _announcements.addAll(querySnapshot.docs);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
    setState(() {
      _announcements.removeWhere((doc) => doc.id == id);
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _announcements.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _fetchAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole != 'admin') {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Announcements',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _announcements.length + 1,
              itemBuilder: (context, index) {
                if (index == _announcements.length) {
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (_hasMore) {
                    _fetchAnnouncements();
                    return const SizedBox.shrink();
                  } else {
                    return const Center(child: Text('No more announcements'));
                  }
                }

                var announcement = _announcements[index].data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(announcement['title']),
                    subtitle: Text(announcement['description']),
                    trailing: _userRole == 'admin'
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteAnnouncement(_announcements[index].id),
                          )
                        : null,
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
