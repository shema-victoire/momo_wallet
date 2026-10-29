import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _filter = 'All';

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get _txCollection {
    if (_user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('transactions');
  }

  Future<void> _seedInitialDataIfNeeded(List<MoMoTransaction> currentTxs) async {
    if (currentTxs.isEmpty && _txCollection != null) {
      final initialTxs = [
        MoMoTransaction(
          id: '1',
          description: 'Initial deposit',
          amount: 10000,
          type: TransactionType.inMoney,
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        MoMoTransaction(
          id: '2',
          description: 'Airtime purchase',
          amount: 1000,
          type: TransactionType.outMoney,
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      for (final tx in initialTxs) {
        await _txCollection!.doc(tx.id).set(tx.toMap());
      }
    }
  }

  void _sendMoney(int currentBalance) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SendMoneyScreen(currentBalance: currentBalance),
      ),
    );

    if (result != null && _txCollection != null) {
      final tx = MoMoTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: 'Sent to ${result['phone']}',
        amount: result['amount'] as int,
        type: TransactionType.outMoney,
        date: DateTime.now(),
      );
      await _txCollection!.doc(tx.id).set(tx.toMap());
    }
  }

  void _cashOut(int currentBalance) async {
    final amount = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => CashOutScreen(currentBalance: currentBalance),
      ),
    );

    if (amount != null && _txCollection != null) {
      final tx = MoMoTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: 'Cash out',
        amount: amount,
        type: TransactionType.outMoney,
        date: DateTime.now(),
      );
      await _txCollection!.doc(tx.id).set(tx.toMap());
    }
  }

  void _deleteTransaction(List<MoMoTransaction> allTxs, MoMoTransaction tx) async {
    if (!canDeleteTransaction(allTxs, tx)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: Balance would drop below 0 in history'),
        ),
      );
      return;
    }

    if (_txCollection != null) {
      await _txCollection!.doc(tx.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tx.description} deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                await _txCollection!.doc(tx.id).set(tx.toMap());
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_txCollection == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _txCollection!.orderBy('date').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final transactions = docs.map((doc) => MoMoTransaction.fromMap(doc.data())).toList();

          if (transactions.isEmpty) {
            _seedInitialDataIfNeeded(transactions);
          }

          final balance = calculateBalance(transactions);
          final totalIn = transactions
              .where((t) => t.type == TransactionType.inMoney)
              .fold<int>(0, (int sum, t) => sum + t.amount);
          final totalOut = transactions
              .where((t) => t.type == TransactionType.outMoney)
              .fold<int>(0, (int sum, t) => sum + t.amount);

          int lowestBalance = 10000;
          int current = 0;
          for (final tx in transactions) {
            if (tx.type == TransactionType.inMoney) {
              current += tx.amount;
            } else {
              current -= tx.amount;
            }
            if (current < lowestBalance) lowestBalance = current;
          }

          final reversedList = transactions.reversed.toList();
          final displayed = _filter == 'IN'
              ? reversedList.where((t) => t.type == TransactionType.inMoney).toList()
              : _filter == 'OUT'
                  ? reversedList.where((t) => t.type == TransactionType.outMoney).toList()
                  : reversedList;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                BalanceCard(balance: balance),
                const SizedBox(height: 12),
                StatsCard(
                  totalIn: totalIn,
                  totalOut: totalOut,
                  lowestBalance: lowestBalance,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _sendMoney(balance),
                        icon: const Icon(Icons.send),
                        label: const Text('Send'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _cashOut(balance),
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
                                    onPressed: () => _deleteTransaction(transactions, tx),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
