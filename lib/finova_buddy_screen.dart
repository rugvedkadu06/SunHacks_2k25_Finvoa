import 'package:flutter/material.dart';

class FinovaBuddyScreen extends StatelessWidget {
  const FinovaBuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finova Buddy'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: const Center(
        child: Text(
          'Finova Buddy Screen Content',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}