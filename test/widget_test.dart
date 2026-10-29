import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/main.dart';

void main() {
  testWidgets('MoMo Wallet initial render test', (WidgetTester tester) async {
    await tester.pumpWidget(const MoMoApp());

    expect(find.text('MoMo Wallet'), findsOneWidget);
    expect(find.text('9,000 RWF'), findsOneWidget);
    expect(find.text('Initial balance'), findsOneWidget);
    expect(find.text('Airtime purchase'), findsOneWidget);
  });
}
