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
