class BengaliFormatter {
  static const Map<String, String> _englishToBengaliDigits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static const List<String> _bengaliMonths = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর'
  ];

  /// Converts English numbers/digits in a string or number to Bengali digits.
  static String toBengaliDigits(dynamic input) {
    final str = input.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      final char = str[i];
      buffer.write(_englishToBengaliDigits[char] ?? char);
    }
    return buffer.toString();
  }

  /// Formats currency to Bengali (e.g. 35.0 -> "৳ ৩৫")
  static String formatPrice(num amount, {bool showDecimals = false}) {
    final formattedNum = showDecimals ? amount.toStringAsFixed(2) : amount.toStringAsFixed(0);
    return '৳ ${toBengaliDigits(formattedNum)}';
  }

  /// Formats date to Bengali (e.g. 2026-10-28 -> "২৮ অক্টোবর ২০২৬")
  static String formatDate(DateTime dateTime) {
    final day = toBengaliDigits(dateTime.day);
    final month = _bengaliMonths[dateTime.month - 1];
    final year = toBengaliDigits(dateTime.year);
    return '$day $month $year';
  }
}
