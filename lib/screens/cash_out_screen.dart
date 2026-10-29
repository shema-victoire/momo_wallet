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
