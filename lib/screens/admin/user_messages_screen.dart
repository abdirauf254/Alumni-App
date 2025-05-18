import 'package:flutter/material.dart';

class UserMessagesScreen extends StatelessWidget {
  const UserMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Messages')),
      body: const Center(
        child: Text('Chat view and respond to users...'),
      ),
    );
  }
}
