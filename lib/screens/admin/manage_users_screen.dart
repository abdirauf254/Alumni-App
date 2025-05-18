import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  DocumentSnapshot? _lastDoc;
  bool _hasNextPage = true;
  bool _isLoading = false;
  List<DocumentSnapshot> _users = [];
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUsers(); // Initial load
    _tabController.addListener(() {
      _lastDoc = null;
      _hasNextPage = true;
      _users.clear();
      fetchUsers();
    });
  }

  Future<void> fetchUsers({bool isNext = false}) async {
    if (_isLoading || (!_hasNextPage && isNext)) return;
    setState(() => _isLoading = true);

    String? roleFilter;
    if (_tabController.index == 1) roleFilter = 'admin';
    if (_tabController.index == 2) roleFilter = 'user';

    Query query = FirebaseFirestore.instance.collection('users')
      ..orderBy('email')
      ..limit(_limit);

    if (_searchQuery.isNotEmpty) {
      query = query.where('email', isGreaterThanOrEqualTo: _searchQuery)
                   .where('email', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
    }

    if (roleFilter != null) {
      query = query.where('role', isEqualTo: roleFilter);
    }

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.length < _limit) {
      _hasNextPage = false;
    }

    if (isNext && _lastDoc != null) {
      _users.addAll(snapshot.docs);
    } else {
      _users = snapshot.docs;
    }

    if (_users.isNotEmpty) {
      _lastDoc = _users.last;
    }

    setState(() => _isLoading = false);
  }

  void deleteUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted')));
    _lastDoc = null;
    _hasNextPage = true;
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Admins'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _lastDoc = null;
                _hasNextPage = true;
                fetchUsers();
              },
            ),
          ),

          // 📋 User list
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        title: Text(user['email']),
                        subtitle: Text('Role: ${user['role']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              deleteUser(user.id), // Use user.id for UID
                        ),
                      );
                    },
                  ),
          ),

          // 📄 Pagination
          if (_hasNextPage)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => fetchUsers(isNext: true),
                child: const Text('Next Page'),
              ),
            ),
        ],
      ),
    );
  }
}
