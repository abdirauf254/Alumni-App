import 'package:flutter/material.dart';

class PushNotificationScreen extends StatelessWidget {
  const PushNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification')),
      body: const Center(
        child: Text('Form to send push notifications...'),
      ),
    );
  }
}
