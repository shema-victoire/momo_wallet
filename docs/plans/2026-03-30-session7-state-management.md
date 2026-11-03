# Session 7 State Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor MoMo Wallet into the 4-layer Provider State Management architecture (Models, Repositories, State, Screens) with central `WalletState` brain and computed filters.

**Architecture:** Provider pattern with `ChangeNotifier` (`WalletState`), isolated repository (`TxnRepository`), decoupled models (`MoMoTransaction`), and UI screens (`WalletScreen`, `SendMoneyScreen`, `CashOutScreen`, `AuthGate`, `LoginScreen`).

**Tech Stack:** Flutter, Dart, Provider, Firebase Auth, Cloud Firestore.

---

### Task 1: Add `provider` Package and Organize Project Folder Structure

**Files:**
- Modify: `pubspec.yaml`
- Reorganize files into:
  - `lib/models/transaction.dart`
  - `lib/repositories/`
  - `lib/state/`
  - `lib/screens/`
  - `lib/widgets/`

- [ ] **Step 1: Add provider dependency**

Run: `flutter pub add provider`
Expected: `provider` added to `pubspec.yaml`

- [ ] **Step 2: Verify pubspec and directory structure**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add provider package for Session 7 state management"
```

---

### Task 2: Create `TxnRepository` (Layer 2)

**Files:**
- Create: `lib/repositories/txn_repository.dart`
- Create: `test/repositories/txn_repository_test.dart`

- [ ] **Step 1: Create `lib/repositories/txn_repository.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:momo_wallet/models/transaction.dart';

class TxnRepository {
  final String uid;

  TxnRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _transactions =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions');

  Stream<List<MoMoTransaction>> watchAll() {
    return _transactions
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MoMoTransaction.fromMap(doc.data()))
            .toList());
  }

  Future<void> add(MoMoTransaction tx) async {
    await _transactions.doc(tx.id).set(tx.toMap());
  }

  Future<void> delete(String id) async {
    await _transactions.doc(id).delete();
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/repositories/txn_repository.dart
git commit -m "feat: add TxnRepository for Firestore database operations"
```

---

### Task 3: Create `WalletState` (Layer 3 — The Brain)

**Files:**
- Create: `lib/state/wallet_state.dart`
- Modify: `test/models/transaction_test.dart`

- [ ] **Step 1: Create `lib/state/wallet_state.dart`**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:momo_wallet/models/transaction.dart';
import 'package:momo_wallet/repositories/txn_repository.dart';

class WalletState extends ChangeNotifier {
  final TxnRepository _repo;
  StreamSubscription<List<MoMoTransaction>>? _subscription;

  List<MoMoTransaction> _transactions = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL'; // 'ALL', 'IN', 'OUT'

  WalletState(this._repo) {
    _subscription = _repo.watchAll().listen(
      (list) {
        _transactions = list;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = 'Could not load your transactions.';
        notifyListeners();
      },
    );
  }

  List<MoMoTransaction> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;
  String get filter => _filter;

  // Computed state getters (Habit 2)
  int get balance => calculateBalance(_transactions);

  int get totalIn => _transactions
      .where((t) => t.type == TransactionType.inMoney)
      .fold<int>(0, (int sum, t) => sum + t.amount);

  int get totalOut => _transactions
      .where((t) => t.type == TransactionType.outMoney)
      .fold<int>(0, (int sum, t) => sum + t.amount);

  int get lowestBalance {
    int lowest = 10000;
    int current = 0;
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

  List<MoMoTransaction> get visible {
    final reversed = _transactions.reversed.toList();
    if (_filter == 'IN') {
      return reversed.where((t) => t.type == TransactionType.inMoney).toList();
    } else if (_filter == 'OUT') {
      return reversed.where((t) => t.type == TransactionType.outMoney).toList();
    }
    return reversed;
  }

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  Future<void> add(MoMoTransaction tx) => _repo.add(tx);

  Future<bool> remove(MoMoTransaction tx) async {
    if (!canDeleteTransaction(_transactions, tx)) {
      return false;
    }
    await _repo.delete(tx.id);
    return true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/state/wallet_state.dart
git commit -m "feat: add WalletState ChangeNotifier brain with computed balance and filters"
```

---

### Task 4: Wire Provider in `AuthGate` & Refactor `WalletScreen`

**Files:**
- Modify: `lib/auth_gate.dart`
- Modify: `lib/screens/wallet_screen.dart`

- [ ] **Step 1: Update `lib/auth_gate.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:momo_wallet/repositories/txn_repository.dart';
import 'package:momo_wallet/screens/wallet_screen.dart';
import 'package:momo_wallet/login_screen.dart';
import 'package:momo_wallet/state/wallet_state.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return ChangeNotifierProvider<WalletState>(
            create: (_) => WalletState(TxnRepository(user.uid)),
            child: const WalletScreen(),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
```

- [ ] **Step 2: Refactor `lib/screens/wallet_screen.dart`**

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:momo_wallet/models/transaction.dart';
import 'package:momo_wallet/screens/cash_out_screen.dart';
import 'package:momo_wallet/screens/send_money_screen.dart';
import 'package:momo_wallet/state/wallet_state.dart';
import 'package:momo_wallet/widgets/balance_card.dart';
import 'package:momo_wallet/widgets/filter_chips.dart';
import 'package:momo_wallet/widgets/stats_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _sendMoney(BuildContext context, WalletState wallet) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<WalletState>.value(
          value: wallet,
          child: SendMoneyScreen(currentBalance: wallet.balance),
        ),
      ),
    );

    if (result != null) {
      final tx = MoMoTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: 'Sent to ${result['phone']}',
        amount: result['amount'] as int,
        type: TransactionType.outMoney,
        date: DateTime.now(),
      );
      await wallet.add(tx);
    }
  }

  void _cashOut(BuildContext context, WalletState wallet) async {
    final amount = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<WalletState>.value(
          value: wallet,
          child: CashOutScreen(currentBalance: wallet.balance),
        ),
      ),
    );

    if (amount != null) {
      final tx = MoMoTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: 'Cash out',
        amount: amount,
        type: TransactionType.outMoney,
        date: DateTime.now(),
      );
      await wallet.add(tx);
    }
  }

  void _deleteTransaction(BuildContext context, WalletState wallet, MoMoTransaction tx) async {
    final success = await wallet.remove(tx);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: Balance would drop below 0 in history'),
        ),
      );
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tx.description} deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              await wallet.add(tx);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMo Wallet'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: wallet.loading
          ? const Center(child: CircularProgressIndicator())
          : wallet.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(wallet.error!, textAlign: TextAlign.center),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      BalanceCard(balance: wallet.balance),
                      const SizedBox(height: 12),
                      StatsCard(
                        totalIn: wallet.totalIn,
                        totalOut: wallet.totalOut,
                        lowestBalance: wallet.lowestBalance,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _sendMoney(context, wallet),
                              icon: const Icon(Icons.send),
                              label: const Text('Send'),
                              style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _cashOut(context, wallet),
                              icon: const Icon(Icons.account_balance_wallet),
                              label: const Text('Cash Out'),
                              style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilterChips(
                        selectedFilter: wallet.filter == 'ALL'
                            ? 'All'
                            : wallet.filter == 'IN'
                                ? 'IN'
                                : 'OUT',
                        onFilterChanged: (f) => wallet.setFilter(f.toUpperCase()),
                      ),
                      const Divider(),
                      Expanded(
                        child: wallet.visible.isEmpty
                            ? const Center(child: Text('No transactions'))
                            : ListView.builder(
                                itemCount: wallet.visible.length,
                                itemBuilder: (context, index) {
                                  final tx = wallet.visible[index];
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
                                          onPressed: () => _deleteTransaction(context, wallet, tx),
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

- [ ] **Step 3: Run flutter analyze and flutter test**

Run: `flutter analyze`
Expected: No issues found!

Run: `flutter test`
Expected: All tests pass!

- [ ] **Step 4: Commit and Push**

```bash
git add .
git commit -m "refactor: complete Session 7 state management with Provider"
git push origin main
```
