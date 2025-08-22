import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'main_screen.dart'; // The main app screen with the BottomNavBar
import 'setup_screen.dart'; // The new dedicated setup screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the process as soon as the widget is initialized
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user data exists
    final userName = prefs.getString('userName');
    final budget = prefs.getString('monthlyBudget');

    // Wait for a short duration to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // Check if the widget is still in the tree

    // Navigate based on whether the user is new or returning
    if (userName == null || budget == null) {
      // User is new, navigate to SetupScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SetupScreen()),
      );
    } else {
      // User is returning, navigate to the main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A simple loading screen UI
    return const Scaffold(
      backgroundColor: Color(0xFF2563EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app logo here
            Text(
              'Finova',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}