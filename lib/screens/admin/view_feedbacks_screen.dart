import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewFeedbacksScreen extends StatelessWidget {
  final String serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // Replace with your actual key

  ViewFeedbacksScreen({super.key});

  Future<void> _sendReply(
    BuildContext context,
    String docId,
    String userId,
    String replyMessage,
  ) async {
    try {
      // 1. Save reply to Firestore
      await FirebaseFirestore.instance.collection('feedbacks').doc(docId).update({
        'reply': replyMessage,
        'repliedAt': Timestamp.now(),
      });

      // 2. Get user token
      final tokenSnapshot = await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(userId)
          .get();

      if (tokenSnapshot.exists) {
        final token = tokenSnapshot['token'];

        // 3. Send FCM Notification
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': token,
            'notification': {
              'title': 'Feedback Reply',
              'body': replyMessage,
            },
            'priority': 'high',
          }),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent successfully')),
      );
    } catch (e) {
      print('Reply error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send reply')),
      );
    }
  }

  void _showReplyDialog(
    BuildContext context,
    String docId,
    String userId,
    String? existingReply,
  ) {
    final replyController = TextEditingController(text: existingReply ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Feedback'),
        content: TextFormField(
          controller: replyController,
          decoration: const InputDecoration(labelText: 'Reply message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendReply(context, docId, userId, replyController.text.trim());
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Feedbacks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final feedbacks = snapshot.data!.docs;

          // Group feedbacks by userId
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in feedbacks) {
            final userId = doc['userId'] ?? 'Unknown';
            grouped.putIfAbsent(userId, () => []).add(doc);
          }

          return ListView(
            children: grouped.entries.map((entry) {
              final userId = entry.key;
              final userFeedbacks = entry.value;

              return Card(
                margin: const EdgeInsets.all(12),
                child: ExpansionTile(
                  title: Text('User: $userId'),
                  children: userFeedbacks.map((doc) {
                    final message = doc['message'] ?? 'No message';
                    final data = doc.data() as Map<String, dynamic>;
                    final reply = data.containsKey('reply') ? data['reply'] : null;

                    return ListTile(
                      title: Text('📝 $message'),
                      subtitle: reply != null
                          ? Text('💬 Reply: $reply')
                          : const Text('❌ No reply yet'),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.reply),
                        label: Text(reply != null ? 'Edit Reply' : 'Reply'),
                        onPressed: () => _showReplyDialog(
                          context,
                          doc.id,
                          doc['userId'] ?? '',
                          reply,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
