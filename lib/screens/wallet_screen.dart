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
    final list = _transactions.reversed.toList();
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
