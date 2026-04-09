/// Build E.164-style `+{cc}{national}` for API `normalize_phone`.
({String? e164, String? error}) tryComposeE164({
  required String dialDigits,
  required String nationalRaw,
}) {
  String digitsOnly(String s) {
    return s.split('').where((c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57).join();
  }

  var national = digitsOnly(nationalRaw);
  while (national.startsWith('0') && national.length > 1) {
    national = national.substring(1);
  }

  if (national.isEmpty) {
    return (e164: null, error: 'Please enter your mobile number');
  }
  if (national.length < 6 || national.length > 12) {
    return (e164: null, error: 'Enter a valid mobile number (6–12 digits)');
  }

  final dial = digitsOnly(dialDigits);
  if (dial.isEmpty || dial.length > 4) {
    return (e164: null, error: 'Invalid country code');
  }

  return (e164: '+$dial$national', error: null);
}
