import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotificationScreen extends StatefulWidget {
  @override
  _PushNotificationScreenState createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String? selectedUserId;
  String? selectedUserToken;

  Future<void> _sendPushNotification() async {
  if (selectedUserToken == null || selectedUserId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select a user with a valid FCM token')),
    );
    return;
  }

  if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Title and message must not be empty')),
    );
    return;
  }

  const String serverKey = 'YOUR_SERVER_KEY_HERE'; // Replace this

  try {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$serverKey',
    };

    final body = jsonEncode({
      'to': selectedUserToken,
      'notification': {
        'title': _titleController.text,
        'body': _messageController.text,
      },
      'priority': 'high',
    });

    final response = await http.post(url, headers: headers, body: body);
    print("FCM response: ${response.statusCode} | ${response.body}");

    if (response.statusCode == 200) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': selectedUserId,
        'title': _titleController.text,
        'body': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: ${response.body}')),
      );
    }
  } catch (e) {
    print("Notification error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sending notification: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Push Notifications")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                final users = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  hint: Text("Select User"),
                  value: selectedUserId,
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value;
                      final user = users.firstWhere((u) => u.id == value);
                      selectedUserToken = user['fcmToken'];
                    });
                  },
                  items: users.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['email'] ?? 'No Email'),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'Message'),
            ),
            SizedBox(height: 16),
           ElevatedButton(
  onPressed: () {
    print("Send Notification button clicked");
    _sendPushNotification();
  },
  child: Text("Send Notification"),
),

            SizedBox(height: 16),
            Divider(),
            Text("Notification History", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: selectedUserId == null
                  ? Center(child: Text("Select a user to view history"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .where('toUserId', isEqualTo: selectedUserId)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) return Center(child: Text("No notifications yet"));

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index];
                            return ListTile(
                              title: Text(data['title']),
                              subtitle: Text(data['body']),
                              trailing: Text(
                                (data['timestamp'] as Timestamp?)?.toDate().toString().split('.').first ?? '',
                                style: TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
