import 'package:flutter_test/flutter_test.dart';
import 'package:momo_wallet/utils/cash_out_calculator.dart';

void main() {
  test('Calculate exact note breakdown for 23,700 RWF', () {
    final breakdown = calculateNoteBreakdown(23700);

    expect(breakdown, {
      5000: 4,
      2000: 1,
      1000: 1,
      500: 1,
      100: 2,
    });

    expect(formatNoteBreakdown(breakdown), '5,000 × 4 · 2,000 × 1 · 1,000 × 1 · 500 × 1 · 100 × 2');
  });

  test('Refuse non-multiples of 100', () {
    expect(isValidCashOutAmount(250), false);
    expect(isValidCashOutAmount(1000), true);
  });
}
