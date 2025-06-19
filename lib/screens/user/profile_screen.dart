import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();

  File? _selectedImage;
  String? _photoUrl;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _courseController.text = data['course'] ?? '';
      _batchController.text = data['batchYear'] ?? '';
      setState(() {
        _photoUrl = data['photoUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('profile_pics/${user!.uid}');
      await storageRef.putFile(_selectedImage!);
      final url = await storageRef.getDownloadURL();

      setState(() {
        _photoUrl = url;
      });

      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'photoUrl': url,
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'name': _nameController.text.trim(),
      'course': _courseController.text.trim(),
      'batchYear': _batchController.text.trim(),
      'email': user!.email,
      'photoUrl': _photoUrl,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Profile updated')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _selectedImage != null ? FileImage(_selectedImage!) :
                      _photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null,
                  child: _photoUrl == null && _selectedImage == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: 'Course'),
                validator: (val) => val == null || val.isEmpty ? 'Enter course' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(labelText: 'Batch Year'),
                validator: (val) => val == null || val.isEmpty ? 'Enter batch year' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
