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
