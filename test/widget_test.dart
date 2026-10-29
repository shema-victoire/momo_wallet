import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('MoMo Wallet'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
