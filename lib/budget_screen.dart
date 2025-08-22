import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final List<String> _budgetOptions = ['Daily', 'Bills', 'Debt', 'Saving'];
  String _selectedOption = 'Daily';

  double _totalMonthlyBudget = 25000;
  double _totalExpenses = 0;
  final Map<String, double> _categoryBudgets = {}; // Initialized as empty
  final Map<String, double> _categoryExpenses = {};
  List<Map<String, dynamic>> _transactions = [];

  final _amountController = TextEditingController();
  String? _selectedCategory;
  String _selectedType = 'Debit';

  @override
  void initState() {
    super.initState();
    _loadBudgetAndTransactions();
    _listenForMessages();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // --- Local Data Management ---

  Future<void> _loadBudgetAndTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalMonthlyBudget = prefs.getDouble('totalMonthlyBudget') ?? 25000;
      final categoryBudgetsJson = prefs.getString('categoryBudgets');

      if (categoryBudgetsJson != null) {
        _categoryBudgets.clear();
        _categoryBudgets.addAll(
            Map<String, double>.from(json.decode(categoryBudgetsJson)));
      }

      // NEW: Check if category budgets are empty and set defaults
      if (_categoryBudgets.isEmpty) {
        _setDefaultBudgets();
      }

      final transactionsJson = prefs.getString('transactions');
      if (transactionsJson != null) {
        _transactions = (json.decode(transactionsJson) as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
      _calculateExpenses();
    });
  }

  // NEW: Method to set a default budget for initial setup
  void _setDefaultBudgets() {
    final defaultDailyCategories = ['Shopping', 'Food', 'Travel', 'Entertainment'];
    final defaultBudgetPerCategory = _totalMonthlyBudget / defaultDailyCategories.length;

    for (var category in defaultDailyCategories) {
      _categoryBudgets[category] = defaultBudgetPerCategory;
    }
    _saveBudgetAndTransactions();
  }

  Future<void> _saveBudgetAndTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('totalMonthlyBudget', _totalMonthlyBudget);
    prefs.setString('categoryBudgets', json.encode(_categoryBudgets));
    prefs.setString('transactions', json.encode(_transactions));
  }

  void _calculateExpenses() {
    _totalExpenses = 0;
    _categoryExpenses.clear();
    for (var category in _categoryBudgets.keys) {
      _categoryExpenses[category] = 0.0;
    }
    for (var transaction in _transactions) {
      final amount = double.tryParse(transaction['amount'] as String) ?? 0;
      final category = transaction['category'];
      if (transaction['type'] == 'Debit' && _categoryExpenses.containsKey(category)) {
        _totalExpenses += amount;
        _categoryExpenses[category] =
            (_categoryExpenses[category] ?? 0.0) + amount;
      }
    }
    setState(() {});
  }

  // --- Message Listener for Automatic Transactions ---

  void _listenForMessages() {
    Future.delayed(const Duration(seconds: 5), () {
      _handleIncomingMessage('Debit alert: Rs. 1500 from your account for shopping.');
    });
  }

  void _handleIncomingMessage(String message) {
    String? type;
    String? amount;

    if (message.contains('Debit')) {
      type = 'Debit';
    } else if (message.contains('Credit')) {
      type = 'Credit';
    }

    final amountMatch = RegExp(r'Rs\.?\s*(\d+)').firstMatch(message);
    if (amountMatch != null) {
      amount = amountMatch.group(1);
    }

    if (type != null && amount != null) {
      _showCategorizePopup(type, amount);
    }
  }

  void _showCategorizePopup(String type, String amount) {
    showDialog(
      context: context,
      builder: (context) {
        String? newCategory;
        return AlertDialog(
          title: const Text('Categorize Transaction'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A new **$type** of ₹$amount was detected. Please categorize it.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: newCategory,
                    hint: const Text('Select a category'),
                    items: _categoryBudgets.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        newCategory = newValue;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newCategory != null) {
                  _addTransaction(
                    amount: amount,
                    category: newCategory!,
                    type: type,
                    isManual: false,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Transaction'),
            ),
          ],
        );
      },
    );
  }

  // --- Transaction Logic ---

  void _addTransaction({
    required String amount,
    required String category,
    required String type,
    bool isManual = true,
  }) {
    if (amount.isEmpty || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    final double transactionAmount = double.tryParse(amount) ?? 0;
    if (transactionAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount.')),
      );
      return;
    }

    if (isManual &&
        type == 'Debit' &&
        _categoryBudgets.containsKey(category) &&
        (_categoryExpenses[category] ?? 0.0) + transactionAmount >
            _categoryBudgets[category]!) {
      _showExceedWarning(transactionAmount, category);
      return;
    }

    setState(() {
      _transactions.insert(0, {
        'type': type,
        'amount': amount,
        'category': category,
        'date': DateTime.now().toIso8601String(),
        'source': isManual ? 'Manual' : 'SMS',
      });
      _saveBudgetAndTransactions();
      _calculateExpenses();
    });
    if (isManual) {
      _amountController.clear();
      _selectedCategory = null;
    }
  }

  // NEW: Method to delete a transaction by its index in the list
  void _deleteTransaction(int index) {
    setState(() {
      final removedTransaction = _transactions.removeAt(index);
      _saveBudgetAndTransactions();
      _calculateExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction for "${removedTransaction['category']}" deleted.')),
      );
    });
  }

  void _showExceedWarning(double amount, String category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Budget Exceeded'),
          content: Text(
              'This transaction of ₹$amount will exceed your budget for the "$category" category.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addTransaction(
                  amount: amount.toString(),
                  category: category,
                  type: 'Debit',
                  isManual: false,
                );
              },
              child: const Text('Proceed Anyway'),
            ),
          ],
        );
      },
    );
  }

  void _showSetLimitDialog(String category) {
    final limitController = TextEditingController();
    limitController.text = (_categoryBudgets[category] ?? 0.0).toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Limit for "$category"'),
          content: TextField(
            controller: limitController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'New Budget Limit (₹)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newLimit = double.tryParse(limitController.text);
                if (newLimit != null && newLimit >= 0) {
                  setState(() {
                    _categoryBudgets[category] = newLimit;
                    _calculateExpenses();
                  });
                  _saveBudgetAndTransactions();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) {
      limitController.dispose();
    });
  }

  // NEW: Method to show a dialog for adding a new category
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add New Category'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name.';
                      }
                      if (_categoryBudgets.containsKey(value.trim())) {
                        return 'This category already exists.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Budget Amount (₹)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a budget.';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    final budget = double.parse(budgetController.text);
                    setState(() {
                      _categoryBudgets[name] = budget;
                      _calculateExpenses();
                    });
                    _saveBudgetAndTransactions();
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }).then((_) {
      nameController.dispose();
      budgetController.dispose();
    });
  }


  // --- UI Building Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Budget',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildOptionSlider(),
            const SizedBox(height: 24),
            _buildContentBasedOnOption(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _budgetOptions.map((option) {
          final isSelected = _selectedOption == option;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedOption = option;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: isSelected
                  ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF2563EB),
                    width: 2,
                  ),
                ),
              )
                  : null,
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContentBasedOnOption() {
    switch (_selectedOption) {
      case 'Daily':
        return _buildDailyBudgetContent();
      case 'Bills':
        return _buildGenericContent('This is where your bills budget will be.');
      case 'Debt':
        return _buildGenericContent('Manage your debt repayments here.');
      case 'Saving':
        return _buildGenericContent('Track your saving goals here.');
      default:
        return Container();
    }
  }

  Widget _buildDailyBudgetContent() {
    return Column(
      children: [
        _buildCategoryBudgetSummary(),
        const SizedBox(height: 24),
        _buildManualTransactionForm(),
        const SizedBox(height: 24),
        _buildTransactionHistory(),
      ],
    );
  }

  // MODIFIED: Added a button to add new categories
  Widget _buildCategoryBudgetSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorical Budget Split',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (_categoryBudgets.isEmpty)
            Center(
              child: Text(
                'No categories yet. Add one below to get started.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ..._categoryBudgets.entries.map((entry) {
            final category = entry.key;
            final budget = entry.value;
            final expenses = _categoryExpenses[category] ?? 0.0;
            final progress = (budget > 0) ? expenses / budget : 0.0;
            final progressColor =
            progress > 0.8 ? Colors.red.shade400 : Colors.green.shade600;

            return _buildCategoryItem(
              category,
              budget,
              expenses,
              progress,
              progressColor,
            );
          }).toList(),
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add New Category'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
      String category, double budget, double expenses, double progress, Color progressColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹${expenses.toStringAsFixed(0)} / ₹${budget.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: progressColor,
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showSetLimitDialog(category),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                (_categoryBudgets[category] ?? 0.0) > 0.0 ? 'Change Limit' : 'Set Limit',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTransactionForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Select Category'),
              items: _categoryBudgets.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Type:'),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() => _selectedType = 'Debit');
                  },
                  icon: Icon(
                    Icons.arrow_upward_rounded,
                    color: _selectedType == 'Debit' ? Colors.red : Colors.grey,
                  ),
                ),
                const Text('Debit'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    setState(() => _selectedType = 'Credit');
                  },
                  icon: Icon(
                    Icons.arrow_downward_rounded,
                    color: _selectedType == 'Credit' ? Colors.green : Colors.grey,
                  ),
                ),
                const Text('Credit'),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a category.'),
                      ),
                    );
                    return;
                  }
                  _addTransaction(
                    amount: _amountController.text,
                    category: _selectedCategory!,
                    type: _selectedType,
                    isManual: true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODIFIED: Implemented Dismissible for swipe-to-delete
  Widget _buildTransactionHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (_transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'No transactions added yet.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            ),
          ..._transactions.asMap().entries.map((entry) {
            final int index = entry.key;
            final transaction = entry.value;

            final isDebit = transaction['type'] == 'Debit';
            final color = isDebit ? Colors.red : Colors.green;
            final icon = isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
            final date = DateTime.tryParse(transaction['date'] as String) ?? DateTime.now();

            return Dismissible(
              key: Key('${transaction['date']}_$index'),
              onDismissed: (direction) {
                _deleteTransaction(index);
              },
              background: Container(
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                child: const Icon(Icons.delete_forever, color: Colors.white),
              ),
              child: _buildTransactionItem(
                transaction['category'],
                '₹${transaction['amount']}',
                date, // Pass DateTime object
                '(${transaction['source']})', // Pass source separately
                icon,
                color,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // MODIFIED: Updated to handle formatted date
  Widget _buildTransactionItem(
      String title, String amount, DateTime date, String source, IconData icon, Color amountColor) {
    final formattedDate = DateFormat('MMM d, y').format(date); // Format the date

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: amountColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate $source', // Combine formatted date and source
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericContent(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}