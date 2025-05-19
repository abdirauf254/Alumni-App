import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ManageAnnouncementScreen extends StatefulWidget {
  const ManageAnnouncementScreen({super.key});

  @override
  State<ManageAnnouncementScreen> createState() => _ManageAnnouncementScreenState();
}

class _ManageAnnouncementScreenState extends State<ManageAnnouncementScreen> {
  final CollectionReference announcementsRef =
      FirebaseFirestore.instance.collection('announcements');

  Future<void> _deleteAnnouncement(String id, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm ?? false) {
      await announcementsRef.doc(id).delete();

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      }
    }
  }

  void _editAnnouncement(String id, Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['description']);
    String? imageUrl = data['imageUrl'];
    File? newImageFile;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Announcement'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  if (newImageFile != null)
                    Image.file(newImageFile!, height: 100)
                  else if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(imageUrl!, height: 100),
                  TextButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Change Image'),
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setStateDialog(() {
                          newImageFile = File(picked.path);
                        });
                      }
                    },
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  String? updatedImageUrl = imageUrl;

                  if (newImageFile != null) {
                    final ref = FirebaseStorage.instance
                        .ref('announcements/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    await ref.putFile(newImageFile!);
                    updatedImageUrl = await ref.getDownloadURL();
                  }

                  await announcementsRef.doc(id).update({
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'imageUrl': updatedImageUrl,
                  });

                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Announcements')),
      body: StreamBuilder<QuerySnapshot>(
        stream: announcementsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data?.docs ?? [];

          if (announcements.isEmpty) {
            return const Center(child: Text('No announcements found.'));
          }

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (ctx, i) {
              final data = announcements[i].data() as Map<String, dynamic>;
              final docId = announcements[i].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.announcement),
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(data['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editAnnouncement(docId, data);
                      } else if (value == 'delete') {
                        _deleteAnnouncement(docId, data['imageUrl']);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
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
