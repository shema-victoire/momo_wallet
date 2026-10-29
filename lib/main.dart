import 'package:flutter/material.dart';
import 'package:momo_wallet/screens/wallet_screen.dart';

void main() {
  runApp(const MoMoApp());
}

class MoMoApp extends StatelessWidget {
  const MoMoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoMo Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const WalletScreen(),
    );
  }
}
