/// Curated dial codes for admin / owner phone entry (E.164 composition on client).
class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.iso2,
    required this.dialDigits,
  });

  final String name;
  final String iso2;
  /// ITU country calling code without '+' (e.g. "91").
  final String dialDigits;

  /// Short label for compact dropdowns.
  String get menuLabel => '$iso2 +$dialDigits';
}

class CountryDialCodes {
  CountryDialCodes._();

  static const CountryDialCode india = CountryDialCode(
    name: 'India',
    iso2: 'IN',
    dialDigits: '91',
  );

  /// India first; add more as needed. For a full list, consider a package later.
  static const List<CountryDialCode> common = [
    india,
    CountryDialCode(name: 'United States', iso2: 'US', dialDigits: '1'),
    CountryDialCode(name: 'United Kingdom', iso2: 'GB', dialDigits: '44'),
    CountryDialCode(name: 'Canada', iso2: 'CA', dialDigits: '1'),
    CountryDialCode(name: 'Australia', iso2: 'AU', dialDigits: '61'),
    CountryDialCode(name: 'United Arab Emirates', iso2: 'AE', dialDigits: '971'),
    CountryDialCode(name: 'Saudi Arabia', iso2: 'SA', dialDigits: '966'),
    CountryDialCode(name: 'Singapore', iso2: 'SG', dialDigits: '65'),
    CountryDialCode(name: 'Nepal', iso2: 'NP', dialDigits: '977'),
    CountryDialCode(name: 'Bangladesh', iso2: 'BD', dialDigits: '880'),
    CountryDialCode(name: 'Pakistan', iso2: 'PK', dialDigits: '92'),
    CountryDialCode(name: 'Sri Lanka', iso2: 'LK', dialDigits: '94'),
    CountryDialCode(name: 'Germany', iso2: 'DE', dialDigits: '49'),
    CountryDialCode(name: 'France', iso2: 'FR', dialDigits: '33'),
    CountryDialCode(name: 'Japan', iso2: 'JP', dialDigits: '81'),
  ];

  static CountryDialCode get defaultCountry => india;
}
