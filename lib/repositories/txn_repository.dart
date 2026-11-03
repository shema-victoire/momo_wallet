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
