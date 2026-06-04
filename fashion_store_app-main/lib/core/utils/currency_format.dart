/// Global currency formatting for UI.
///
/// Firestore stores numeric values; we apply a consistent symbol + formatting here.
abstract final class CurrencyFormat {
  /// Change this once to affect the whole app.
  static const String symbol = 'Rs.';

  /// Typical for `$` display. If you prefer whole units, set to 0.
  static const int decimalDigits = 2;

  /// Format a numeric amount with grouping separators and a global symbol.
  static String format(double amount) {
    final negative = amount.isNegative;
    final abs = amount.abs();

    final fixed = abs.toStringAsFixed(decimalDigits);
    final parts = fixed.split('.');
    final intPart = parts.first;
    final fracPart = parts.length > 1 ? parts.last : '';

    final grouped = _groupThousands(intPart);
    final sign = negative ? '-' : '';
    final decimals = decimalDigits == 0 ? '' : '.$fracPart';

    return '$symbol $sign$grouped$decimals';
  }

  static String _groupThousands(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

