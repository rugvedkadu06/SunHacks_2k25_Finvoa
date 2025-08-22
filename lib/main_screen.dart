// main_screen.dart

import 'package:flutter/material.dart';

// Import the screens that will be used in the navigation
import 'dashboard_screen.dart';
import 'budget_screen.dart';
import 'insights_screen.dart';
import 'finova_buddy_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // REMOVED: final GlobalKey<_BudgetScreenState> _budgetScreenKey = GlobalKey<_BudgetScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      DashboardScreen(
        onAddExpensePressed: () {
          _onItemTapped(1); // Navigate to the Budget screen
        },
        onViewBudgetPressed: () {
          _onItemTapped(1); // Navigate to the Budget screen
        },
      ),
      const BudgetScreen(), // Now a const constructor, as it no longer needs a key
      const InsightsScreen(),
      const FinovaBuddyScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_rounded, size: 24),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded, size: 24),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded, size: 24),
            label: 'Finova Buddy',
          ),
        ],
      ),
    );
  }
}