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
