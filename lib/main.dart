import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import the new splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finova',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        useMaterial3: true,
        primaryColor: const Color(0xFF2563EB),
      ),
      // The app's starting point is now the SplashScreen
      home: const SplashScreen(),
    );
  }
}