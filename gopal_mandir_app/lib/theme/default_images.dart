/// Default local Gopal Ji images used as fallback when
/// network/CDN images are unavailable.
class DefaultImages {
  DefaultImages._();

  static const String darshan1 = 'assets/images/gopal_darshan_1.jpg';
  static const String darshan2 = 'assets/images/gopal_darshan_2.jpg';
  static const String darshan3 = 'assets/images/gopal_darshan_3.jpg';
  static const String darshan4 = 'assets/images/gopal_darshan_4.jpg';

  /// All available default images for round-robin use
  static const List<String> all = [darshan1, darshan2, darshan3, darshan4];

  /// Get a default image by index (cycles through available images)
  static String byIndex(int index) => all[index % all.length];
}
