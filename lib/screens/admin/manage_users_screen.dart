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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted')),
      );
      _lastDoc = null;
      _hasNextPage = true;
      fetchUsers();
    }
  }

  void viewUser(DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${user['email']}'),
            Text('Role: ${user['role']}'),
            if (user.data().toString().contains('name'))
              Text('Name: ${user['name']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void editUser(DocumentSnapshot user) {
    final _emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'user', child: Text('User')),
              ],
              onChanged: (value) {
                if (value != null) selectedRole = value;
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .update({
                'email': _emailController.text.trim(),
                'role': selectedRole,
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User updated successfully')),
              );
              fetchUsers();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              tooltip: 'View',
                              onPressed: () => viewUser(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () => editUser(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                              onPressed: () => deleteUser(user.id),
                            ),
                          ],
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
