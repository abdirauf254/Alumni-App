import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlumniListScreen extends StatelessWidget {
  const AlumniListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alumni Directory")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['name'] ?? 'No Name'),
                subtitle: Text('${data['course'] ?? ''} • Batch ${data['batch'] ?? ''}'),
              );
            },
          );
        },
      ),
    );
  }
}
