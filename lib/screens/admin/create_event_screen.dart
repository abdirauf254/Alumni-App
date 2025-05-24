import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String description = '';
  String location = '';
  DateTime? dateTime;
  Uint8List? imageBytes;
  XFile? pickedXFile;
  bool isUploading = false;

  final picker = ImagePicker();
  final format = DateFormat("yyyy-MM-dd HH:mm");

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBytes = bytes;
        pickedXFile = pickedFile;
      });
    }
  }

  Future<String?> uploadImage(XFile file) async {
    try {
      final fileName = const Uuid().v4() + path.extension(file.path);
      final storageRef = FirebaseStorage.instance.ref().child('event_images/$fileName');
      final uploadTask = await storageRef.putData(await file.readAsBytes());
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isUploading = true);

      String? imageUrl;
      if (pickedXFile != null) {
        imageUrl = await uploadImage(pickedXFile!);
      }

      try {
        await FirebaseFirestore.instance.collection('events').add({
          'title': title,
          'description': description,
          'location': location,
          'dateTime': dateTime?.toIso8601String(),
          'imageUrl': imageUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create event')),
        );
      } finally {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) => value!.isEmpty ? 'Enter a title' : null,
                      onSaved: (value) => title = value!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (value) => value!.isEmpty ? 'Enter a description' : null,
                      onSaved: (value) => description = value!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (value) => value!.isEmpty ? 'Enter a location' : null,
                      onSaved: (value) => location = value!,
                    ),
                    const SizedBox(height: 12),
                    DateTimeField(
                      format: format,
                      decoration: const InputDecoration(labelText: 'Date & Time'),
                      onShowPicker: (context, currentValue) async {
                        final date = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          initialDate: currentValue ?? DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                currentValue ?? DateTime.now()),
                          );
                          return DateTimeField.combine(date, time);
                        } else {
                          return currentValue;
                        }
                      },
                      onSaved: (value) => dateTime = value,
                      validator: (value) => value == null ? 'Select date & time' : null,
                    ),
                    const SizedBox(height: 12),
                    imageBytes != null
                        ? Image.memory(imageBytes!, height: 150)
                        : const Text('No image selected'),
                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createEvent,
                      child: const Text('Create Event'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
