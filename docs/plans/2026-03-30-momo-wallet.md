# MoMo Wallet Implementation Plan (Session 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete MoMo Wallet Flutter application with balance management, send money rules, cash-out note breakdown calculator, stats, transaction filtering, and safety-checked undo deletion.

**Architecture:** Model-driven Flutter app with `StatefulWidget` state management, decoupled calculation logic (`CashOutCalculator`), modular custom widgets, and unit/widget test suites.

**Tech Stack:** Flutter, Dart, Material 3.

---

### Task 1: Transaction Model and Safety Helper Functions

**Files:**
- Create: `lib/models/transaction.dart`
- Create: `test/models/transaction_test.dart`

- [ ] **Step 1: Write failing test for Transaction model and safety check**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/models/transaction.dart';

void main() {
  test('Calculate balance correctly from transactions', () {
    final transactions = [
      Transaction(
        id: '1',
        description: 'Initial balance',
        amount: 10000,
        type: TransactionType.inMoney,
        date: DateTime.now(),
      ),
      Transaction(
        id: '2',
        description: 'Sent to 0788123456',
        amount: 2000,
        type: TransactionType.outMoney,
        date: DateTime.now(),
      ),
    ];

    expect(calculateBalance(transactions), 8000);
  });

  test('Refuse deletion if historical balance drops below 0', () {
    final transactions = [
      Transaction(
        id: '1',
        description: 'Deposit 1000',
        amount: 1000,
        type: TransactionType.inMoney,
        date: DateTime.now(),
      ),
      Transaction(
        id: '2',
        description: 'Spent 800',
        amount: 800,
        type: TransactionType.outMoney,
        date: DateTime.now(),
      ),
    ];

    // Deleting deposit '1' would leave balance at -800
    expect(canDeleteTransaction(transactions, transactions[0]), false);
    // Deleting expense '2' is allowed
    expect(canDeleteTransaction(transactions, transactions[1]), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/models/transaction_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Transaction model and helper functions**

```dart
enum TransactionType { inMoney, outMoney }

class Transaction {
  final String id;
  final String description;
  final int amount;
  final TransactionType type;
  final DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });
}

int calculateBalance(List<Transaction> transactions) {
  int balance = 0;
  for (final tx in transactions) {
    if (tx.type == TransactionType.inMoney) {
      balance += tx.amount;
    } else {
      balance -= tx.amount;
    }
  }
  return balance;
}

bool canDeleteTransaction(List<Transaction> transactions, Transaction txToDelete) {
  // Simulate remaining list
  final remaining = transactions.where((t) => t.id != txToDelete.id).toList();
  
  // Verify that balance never drops below 0 at any historical point
  int runningBalance = 0;
  for (final tx in remaining) {
    if (tx.type == TransactionType.inMoney) {
      runningBalance += tx.amount;
    } else {
      runningBalance -= tx.amount;
    }
    if (runningBalance < 0) {
      return false;
    }
  }
  return true;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/models/transaction_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/models/transaction.dart test/models/transaction_test.dart
git commit -m "feat: add Transaction model and balance safety helpers"
```

---

### Task 2: Cash-Out Note Breakdown Calculator

**Files:**
- Create: `lib/utils/cash_out_calculator.dart`
- Create: `test/utils/cash_out_calculator_test.dart`

- [ ] **Step 1: Write failing test for note breakdown calculator**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/utils/cash_out_calculator.dart';

void main() {
  test('Calculate exact note breakdown for 23,700 RWF', () {
    final breakdown = calculateNoteBreakdown(23700);

    expect(breakdown, {
      5000: 4,
      2000: 1,
      1000: 1,
      500: 1,
      100: 2,
    });

    expect(formatNoteBreakdown(breakdown), '5,000 × 4 · 2,000 × 1 · 1,000 × 1 · 500 × 1 · 100 × 2');
  });

  test('Refuse non-multiples of 100', () {
    expect(isValidCashOutAmount(250), false);
    expect(isValidCashOutAmount(1000), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/utils/cash_out_calculator_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement CashOutCalculator**

```dart
bool isValidCashOutAmount(int amount) {
  return amount > 0 && amount % 100 == 0;
}

Map<int, int> calculateNoteBreakdown(int amount) {
  final denominations = [5000, 2000, 1000, 500, 100];
  final Map<int, int> result = {};
  int remaining = amount;

  for (final note in denominations) {
    final count = remaining ~/ note;
    if (count > 0) {
      result[note] = count;
      remaining %= note;
    }
  }

  return result;
}

String formatNoteBreakdown(Map<int, int> breakdown) {
  if (breakdown.isEmpty) return '0 RWF';
  final parts = <String>[];
  breakdown.forEach((note, count) {
    // Format note with comma
    final noteFormatted = note.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    parts.add('$noteFormatted × $count');
  });
  return parts.join(' · ');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/utils/cash_out_calculator_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/utils/cash_out_calculator.dart test/utils/cash_out_calculator_test.dart
git commit -m "feat: add cash out note breakdown calculator"
```

---

### Task 3: Custom UI Widgets (Balance Card, Stats Card, Filter Chips)

**Files:**
- Create: `lib/widgets/balance_card.dart`
- Create: `lib/widgets/stats_card.dart`
- Create: `lib/widgets/filter_chips.dart`

- [ ] **Step 1: Create BalanceCard widget**

```dart
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final int balance;

  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final formattedBalance = balance.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MoMo Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '$formattedBalance RWF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create StatsCard widget**

```dart
import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int totalIn;
  final int totalOut;
  final int lowestBalance;

  const StatsCard({
    super.key,
    required this.totalIn,
    required this.totalOut,
    required this.lowestBalance,
  });

  String _format(int val) {
    return val.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Total IN', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('+${_format(totalIn)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                const Text('Total OUT', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('-${_format(totalOut)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                const Text('Lowest Bal.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${_format(lowestBalance)}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create FilterChips widget**

```dart
import 'package:flutter/material.dart';

class FilterChips extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'IN', 'OUT'];

    return Row(
      children: filters.map((f) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(f),
            selected: selectedFilter == f,
            onSelected: (selected) {
              if (selected) onFilterChanged(f);
            },
          ),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 4: Commit UI components**

```bash
git add lib/widgets/
git commit -m "feat: add BalanceCard, StatsCard, and FilterChips widgets"
```

---

### Task 4: Send Money Screen

**Files:**
- Create: `lib/screens/send_money_screen.dart`

- [ ] **Step 1: Implement SendMoneyScreen**

```dart
import 'package:flutter/material.dart';

class SendMoneyScreen extends StatefulWidget {
  final int currentBalance;

  const SendMoneyScreen({super.key, required this.currentBalance});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;

  void _submit() {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);

    if (phone.length != 10 || (!phone.startsWith('078') && !phone.startsWith('079'))) {
      setState(() {
        _error = 'Phone number must be 10 digits starting with 078 or 079';
      });
      return;
    }

    if (amount == null || amount < 100) {
      setState(() {
        _error = 'Amount must be at least 100 RWF';
      });
      return;
    }

    if (amount > widget.currentBalance) {
      setState(() {
        _error = 'Insufficient balance';
      });
      return;
    }

    Navigator.pop(context, {
      'phone': phone,
      'amount': amount,
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Recipient Phone Number (078... / 079...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Send Money'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit SendMoneyScreen**

```bash
git add lib/screens/send_money_screen.dart
git commit -m "feat: add SendMoneyScreen with validation rules"
```

---

### Task 5: Cash Out Screen

**Files:**
- Create: `lib/screens/cash_out_screen.dart`

- [ ] **Step 1: Implement CashOutScreen**

```dart
import 'package:flutter/material.dart';
import 'package:momo_wallet/utils/cash_out_calculator.dart';

class CashOutScreen extends StatefulWidget {
  final int currentBalance;

  const CashOutScreen({super.key, required this.currentBalance});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final _amountController = TextEditingController();
  String? _error;
  String _noteBreakdown = '';

  void _onAmountChanged(String val) {
    final amount = int.tryParse(val.trim());
    if (amount != null && isValidCashOutAmount(amount)) {
      final breakdown = calculateNoteBreakdown(amount);
      setState(() {
        _noteBreakdown = formatNoteBreakdown(breakdown);
        _error = null;
      });
    } else {
      setState(() {
        _noteBreakdown = '';
      });
    }
  }

  void _submit() {
    final amount = int.tryParse(_amountController.text.trim());

    if (amount == null || !isValidCashOutAmount(amount)) {
      setState(() {
        _error = 'Amount must be a multiple of 100 RWF';
      });
      return;
    }

    if (amount > widget.currentBalance) {
      setState(() {
        _error = 'Insufficient balance';
      });
      return;
    }

    Navigator.pop(context, amount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Out')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: _onAmountChanged,
              decoration: const InputDecoration(
                labelText: 'Amount (Multiple of 100 RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_noteBreakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notes Agent Will Hand You:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_noteBreakdown, style: TextStyle(color: Colors.green.shade800, fontSize: 15)),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.money),
              label: const Text('Confirm Cash Out'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit CashOutScreen**

```bash
git add lib/screens/cash_out_screen.dart
git commit -m "feat: add CashOutScreen with note breakdown preview"
```

---

### Task 6: Main Wallet Screen and App Entry Point

**Files:**
- Create: `lib/screens/wallet_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Implement WalletScreen**

```dart
import 'package:flutter/material.dart';
import 'package:momo_wallet/models/transaction.dart';
import 'package:momo_wallet/screens/cash_out_screen.dart';
import 'package:momo_wallet/screens/send_money_screen.dart';
import 'package:momo_wallet/widgets/balance_card.dart';
import 'package:momo_wallet/widgets/filter_chips.dart';
import 'package:momo_wallet/widgets/stats_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      description: 'Initial balance',
      amount: 10000,
      type: TransactionType.inMoney,
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '2',
      description: 'Airtime purchase',
      amount: 1000,
      type: TransactionType.outMoney,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  String _filter = 'All';

  int get _balance => calculateBalance(_transactions);

  int get _totalIn => _transactions
      .where((t) => t.type == TransactionType.inMoney)
      .fold(0, (sum, t) => sum + t.amount);

  int get _totalOut => _transactions
      .where((t) => t.type == TransactionType.outMoney)
      .fold(0, (sum, t) => sum + t.amount);

  int get _lowestBalance {
    int current = 0;
    int lowest = 10000;
    for (final tx in _transactions) {
      if (tx.type == TransactionType.inMoney) {
        current += tx.amount;
      } else {
        current -= tx.amount;
      }
      if (current < lowest) lowest = current;
    }
    return lowest;
  }

  List<Transaction> get _filteredTransactions {
    final list = _transactions.reversed.toList(); // Newest first
    if (_filter == 'IN') {
      return list.where((t) => t.type == TransactionType.inMoney).toList();
    } else if (_filter == 'OUT') {
      return list.where((t) => t.type == TransactionType.outMoney).toList();
    }
    return list;
  }

  void _sendMoney() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SendMoneyScreen(currentBalance: _balance),
      ),
    );

    if (result != null) {
      setState(() {
        _transactions.add(Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Sent to ${result['phone']}',
          amount: result['amount'] as int,
          type: TransactionType.outMoney,
          date: DateTime.now(),
        ));
      });
    }
  }

  void _cashOut() async {
    final amount = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => CashOutScreen(currentBalance: _balance),
      ),
    );

    if (amount != null) {
      setState(() {
        _transactions.add(Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Cash out',
          amount: amount,
          type: TransactionType.outMoney,
          date: DateTime.now(),
        ));
      });
    }
  }

  void _deleteTransaction(Transaction tx) {
    if (!canDeleteTransaction(_transactions, tx)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: Balance would drop below 0 in history'),
        ),
      );
      return;
    }

    final index = _transactions.indexOf(tx);
    setState(() {
      _transactions.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tx.description} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _transactions.insert(index, tx);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMo Wallet'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            BalanceCard(balance: _balance),
            const SizedBox(height: 12),
            StatsCard(
              totalIn: _totalIn,
              totalOut: _totalOut,
              lowestBalance: _lowestBalance,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sendMoney,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _cashOut,
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Cash Out'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilterChips(
              selectedFilter: _filter,
              onFilterChanged: (f) => setState(() => _filter = f),
            ),
            const Divider(),
            Expanded(
              child: displayed.isEmpty
                  ? const Center(child: Text('No transactions'))
                  : ListView.builder(
                      itemCount: displayed.length,
                      itemBuilder: (context, index) {
                        final tx = displayed[index];
                        final isIn = tx.type == TransactionType.inMoney;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIn ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              isIn ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIn ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIn ? '+' : '-'}${tx.amount} RWF',
                                style: TextStyle(
                                  color: isIn ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deleteTransaction(tx),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:momo_wallet/screens/wallet_screen.dart';

void main() {
  runApp(const MoMoApp());
}

class MoMoApp extends StatelessWidget {
  const MoMoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoMo Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const WalletScreen(),
    );
  }
}
```

- [ ] **Step 3: Update test/widget_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/main.dart';

void main() {
  testWidgets('MoMo Wallet initial render test', (WidgetTester tester) async {
    await tester.pumpWidget(const MoMoApp());

    expect(find.text('MoMo Wallet'), findsOneWidget);
    expect(find.text('9,000 RWF'), findsOneWidget); // 10000 - 1000
    expect(find.text('Initial balance'), findsOneWidget);
    expect(find.text('Airtime purchase'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run flutter analyze and flutter test**

Run: `flutter analyze`
Expected: No issues found!

Run: `flutter test`
Expected: All tests passed!

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: complete MoMo Wallet app implementation and tests"
```
