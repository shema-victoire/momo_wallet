bool isValidCashOutAmount(int amount) {
  return amount > 0 && amount % 100 == 0;
}

Map<int, int> calculateNoteBreakdown(int amount) {
  final denominations = [5000, 2000, 1000, 500, 100];
  final Map<int, int> result = {};
  int remaining = amount;

  for (final note in denominations) {
    final count = remaining ~/ note;
    if (count > 0) {
      result[note] = count;
      remaining %= note;
    }
  }

  return result;
}

String formatNoteBreakdown(Map<int, int> breakdown) {
  if (breakdown.isEmpty) return '0 RWF';
  final parts = <String>[];
  breakdown.forEach((note, count) {
    final noteFormatted = note.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    parts.add('$noteFormatted × $count');
  });
  return parts.join(' · ');
}
