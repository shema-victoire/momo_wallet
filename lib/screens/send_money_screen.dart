import 'package:flutter/material.dart';

class SendMoneyScreen extends StatefulWidget {
  final int currentBalance;

  const SendMoneyScreen({super.key, required this.currentBalance});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;

  void _submit() {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = int.tryParse(amountText);

    if (phone.length != 10 || (!phone.startsWith('078') && !phone.startsWith('079'))) {
      setState(() {
        _error = 'Phone number must be 10 digits starting with 078 or 079';
      });
      return;
    }

    if (amount == null || amount < 100) {
      setState(() {
        _error = 'Amount must be at least 100 RWF';
      });
      return;
    }

    if (amount > widget.currentBalance) {
      setState(() {
        _error = 'Insufficient balance';
      });
      return;
    }

    Navigator.pop(context, {
      'phone': phone,
      'amount': amount,
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Recipient Phone Number (078... / 079...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('Send Money'),
            ),
          ],
        ),
      ),
    );
  }
}
