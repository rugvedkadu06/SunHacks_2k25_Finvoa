import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Check if a user and budget have already been set
  Future<bool> _checkIsFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName');
    final budget = prefs.getString('monthlyBudget');
    return userName == null || budget == null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _checkIsFirstTimeUser(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final bool isFirstTimeUser = snapshot.data ?? true;
            if (isFirstTimeUser) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showBudgetSetupDialog(context);
              });
            }
            return const DashboardScreen();
          } else {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }

  void _showBudgetSetupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController budgetController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Welcome! Set Up Your Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                  hintText: 'e.g., 3000',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Set Profile'),
              onPressed: () {
                final name = nameController.text.trim();
                final budget = budgetController.text.trim();
                if (name.isNotEmpty && budget.isNotEmpty) {
                  _saveProfile(name, budget);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _saveProfile(String name, String budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('monthlyBudget', budget);
    await prefs.setString('budgetStartDate', DateTime.now().toIso8601String());
  }
}