import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Default values to prevent null errors before data is loaded
  String _userName = 'User';
  String _monthlyBudget = '0';
  String _budgetPeriod = '...';

  @override
  void initState() {
    super.initState();
    _loadProfileAndBudget();
  }

  /// Loads the user's name, budget, and calculates the budget period from local storage.
  void _loadProfileAndBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName');
    final budget = prefs.getString('monthlyBudget');
    final startDateString = prefs.getString('budgetStartDate');

    if (name != null) {
      _userName = name;
    }
    if (budget != null) {
      _monthlyBudget = budget;
    }
    if (startDateString != null) {
      final startDate = DateTime.parse(startDateString);
      _budgetPeriod = DateFormat('MMMM').format(startDate);
    }

    setState(() {}); // Trigger a rebuild to update the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            // Center the column and make it stretch to full width
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildBalanceCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Builds the top header with the user's profile.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF4571C4),
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hello,',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _userName,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main budget and balance card.
  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C59A4),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center contents
          children: [
            const Text(
              'Monthly Budget',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Budget Amount
            Text(
              '₹$_monthlyBudget',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48, // Bigger font
                fontWeight: FontWeight.bold,
              ),
            ),
            // Budget Period (Month)
            Text(
              '$_budgetPeriod',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18, // Smaller font
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds the bottom navigation bar.
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF2C59A4),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card_outlined),
          label: 'Budget',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.insights_outlined),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Finova Buddy',
        ),
      ],
    );
  }
}