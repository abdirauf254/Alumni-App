import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final nameCtrl = TextEditingController();
  final batchCtrl = TextEditingController();
  final courseCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      nameCtrl.text = data['name'] ?? '';
      batchCtrl.text = data['batch'] ?? '';
      courseCtrl.text = data['course'] ?? '';
      locationCtrl.text = data['location'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'name': nameCtrl.text.trim(),
      'batch': batchCtrl.text.trim(),
      'course': courseCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch')),
            TextField(controller: courseCtrl, decoration: const InputDecoration(labelText: 'Course')),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveProfile, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}