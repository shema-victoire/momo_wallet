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
