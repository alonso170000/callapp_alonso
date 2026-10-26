class PhoneNumber {
  const PhoneNumber._();

  static const minDigits = 7;
  static const maxDigits = 15;

  static String digits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  static String normalize(String raw) {
    final trimmed = raw.trim();
    final value = digits(trimmed);
    if (value.isEmpty) return '';
    return trimmed.startsWith('+') ? '+$value' : value;
  }

  static bool isDialable(String raw) {
    final count = digits(raw).length;
    return count >= minDigits && count <= maxDigits;
  }

  static Uri telUri(String raw) => Uri(scheme: 'tel', path: normalize(raw));
}
