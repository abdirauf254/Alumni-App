import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _selectedDate;
  File? _selectedImage;
  bool _loading = false;

  final picker = ImagePicker();

  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final fileName = basename(imageFile.path);
    final ref = FirebaseStorage.instance.ref('event_images/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> submitEvent() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty || _selectedDate == null || _selectedImage == null) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    setState(() => _loading = true);

    try {
      final imageUrl = await uploadImage(_selectedImage!);
      await FirebaseFirestore.instance.collection('events').add({
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'imageUrl': imageUrl,
        'date': _selectedDate,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context as BuildContext).showSnackBar(const SnackBar(content: Text('Event created successfully')));
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _selectedImage = null;
        _selectedDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select date'
                            : DateFormat.yMMMd().format(_selectedDate!),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _selectedImage != null
                      ? Image.file(_selectedImage!, height: 150)
                      : const Text('No image selected'),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Select Image'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: submitEvent,
                    child: const Text('Submit Event'),
                  )
                ],
              ),
            ),
    );
  }
}
