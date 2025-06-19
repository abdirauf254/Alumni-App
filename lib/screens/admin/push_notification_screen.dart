import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotificationScreen extends StatefulWidget {
  @override
  _PushNotificationScreenState createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  // Your FCM server key
  final String serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Replace this with your actual FCM key
Future<void> _sendNotificationToAllUsers() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSending = true);

  final title = _titleController.text.trim();
  final body = _bodyController.text.trim();

  try {
    // ✅ Save to Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'timestamp': Timestamp.now(),
    });

    // ✅ Get all user tokens
    final snapshot = await FirebaseFirestore.instance.collection('user_tokens').get();
    final tokens = snapshot.docs.map((doc) => doc['token']).toList();

    for (String token in tokens) {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'priority': 'high',
        }),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification sent and saved!')),
    );
  } catch (e) {
    print('Error sending notifications: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send notifications')),
    );
  }

  setState(() => _isSending = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Push Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Notification Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter title' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(labelText: 'Notification Body'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter body' : null,
              ),
              SizedBox(height: 20),
              _isSending
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sendNotificationToAllUsers,
                      child: Text('Send Notification'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
