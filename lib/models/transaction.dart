enum TransactionType { inMoney, outMoney }

class MoMoTransaction {
  final String id;
  final String description;
  final int amount;
  final TransactionType type;
  final DateTime date;

  MoMoTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type == TransactionType.inMoney ? 'in' : 'out',
      'date': date.toIso8601String(),
    };
  }

  factory MoMoTransaction.fromMap(Map<String, dynamic> map) {
    return MoMoTransaction(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      type: map['type'] == 'in' ? TransactionType.inMoney : TransactionType.outMoney,
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
    );
  }
}

int calculateBalance(List<MoMoTransaction> transactions) {
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

bool canDeleteTransaction(List<MoMoTransaction> transactions, MoMoTransaction txToDelete) {
  final remaining = transactions.where((t) => t.id != txToDelete.id).toList();

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
