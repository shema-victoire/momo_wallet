import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:momo_wallet/repositories/txn_repository.dart';
import 'package:momo_wallet/screens/wallet_screen.dart';
import 'package:momo_wallet/login_screen.dart';
import 'package:momo_wallet/state/wallet_state.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return ChangeNotifierProvider<WalletState>(
            create: (_) => WalletState(TxnRepository(user.uid)),
            child: const WalletScreen(),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
