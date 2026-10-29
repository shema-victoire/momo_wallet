import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final int totalIn;
  final int totalOut;
  final int lowestBalance;

  const StatsCard({
    super.key,
    required this.totalIn,
    required this.totalOut,
    required this.lowestBalance,
  });

  String _format(int val) {
    return val.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Total IN', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('+${_format(totalIn)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                const Text('Total OUT', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('-${_format(totalOut)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                const Text('Lowest Bal.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(_format(lowestBalance), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
