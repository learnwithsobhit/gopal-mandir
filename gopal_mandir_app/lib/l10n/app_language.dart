/// App language: Hindi (hi) or English (en).
enum AppLanguage {
  hi,
  en,
}

/// All localised strings. Use [AppLocaleScope.of(context).strings] to access.
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  bool get isHindi => lang == AppLanguage.hi;

  // ── Main / Nav ──
  String get appTitle => isHindi ? 'श्री गोपाल मंदिर' : 'Shri Gopal Mandir';
  String get navHome => isHindi ? 'होम' : 'Home';
  String get navSeva => isHindi ? 'सेवा' : 'Seva';
  String get navLive => isHindi ? 'लाइव' : 'Live';
  String get navEvents => isHindi ? 'कार्यक्रम' : 'Events';
  String get navMore => isHindi ? 'अधिक' : 'More';

  // ── Home ──
  String get templeName => isHindi ? 'श्री गोपाल मंदिर' : 'Shri Gopal Mandir';
  String get todayInTemple => isHindi ? 'आज मंदिर में' : 'Today at Temple';
  String get upcomingEvents => isHindi ? 'आगामी उत्सव' : 'Upcoming Events';
  String get dailyShlok => isHindi ? 'दैनिक श्लोक' : 'Daily Shlok';
  String get panchangTitle => isHindi ? 'हिंदू पंचांग' : 'Hindu Panchang';
  String get quickDarshan => isHindi ? 'दर्शन' : 'Darshan';
  String get quickAartiTimings => isHindi ? 'आरती\nसमय' : 'Aarti\nTimings';
  String get quickDonate => isHindi ? 'दान' : 'Donate';
  String get quickBookPrasad => isHindi ? 'प्रसाद\nबुक करें' : 'Book\nPrasad';
  String get quickEvents => isHindi ? 'कार्यक्रम' : 'Events';
  String get quickSeva => isHindi ? 'सेवा' : 'Seva';
  String get quickGallery => isHindi ? 'गैलरी' : 'Gallery';
  String get quickLiveDarshan => isHindi ? 'लाइव\nदर्शन' : 'Live\nDarshan';
  String get quickPanchang => isHindi ? 'पंचांग' : 'Panchang';

  // ── More screen ──
  String get more => isHindi ? 'अधिक' : 'More';
  String get aboutTemple => isHindi ? 'मंदिर के बारे में' : 'About Temple';
  String get aboutTempleSub => isHindi ? 'इतिहास और जानकारी' : 'History and information';
  String get locationMap => isHindi ? 'लोकेशन और मैप' : 'Location & Map';
  String get contactUs => isHindi ? 'संपर्क करें' : 'Contact Us';
  String get email => isHindi ? 'ईमेल' : 'Email';
  String get emailSub => isHindi ? 'संदेश भेजें' : 'Send message';
  String get volunteer => isHindi ? 'स्वयंसेवक' : 'Volunteer';
  String get volunteerSub => isHindi ? 'सेवक टीम में शामिल हों' : 'Join our sevak team';
  String get membership => isHindi ? 'सदस्यता' : 'Membership';
  String get membershipSub => isHindi ? 'सदस्य बनें' : 'Become a member';
  String get shareApp => isHindi ? 'ऐप शेयर करें' : 'Share App';
  String get shareAppSub => isHindi ? 'भक्ति फैलाएं' : 'Spread the devotion';

  // ── Share App bottom sheet ──
  String get shareWhatsAppLabel => isHindi ? 'व्हाट्सऐप' : 'WhatsApp';
  String get shareWhatsAppSub => isHindi ? 'WhatsApp पर साझा करें' : 'Share to WhatsApp';
  String get shareFacebookLabel => isHindi ? 'फेसबुक' : 'Facebook';
  String get shareFacebookSub => isHindi ? 'Facebook पर साझा करें' : 'Share to Facebook';
  String get shareXLabel => 'X';
  String get shareXSub => isHindi ? 'X (Twitter) पर साझा करें' : 'Share on X (Twitter)';
  String get shareTelegramLabel => isHindi ? 'टेलीग्राम' : 'Telegram';
  String get shareTelegramSub => isHindi ? 'Telegram पर साझा करें' : 'Share to Telegram';
  String get shareCopyLinkLabel => isHindi ? 'लिंक कॉपी करें' : 'Copy link';
  String get shareCopyLinkSub => isHindi ? 'ऐप का URL कॉपी करें' : 'Copy the app URL';
  String get shareLinkCopied => isHindi ? 'लिंक कॉपी हो गया' : 'Link copied';
  String get shareLinkOpenError => isHindi ? 'शेयर लिंक नहीं खुल सका। कृपया पुनः प्रयास करें।' : 'Could not open share link. Please try again.';

  String get rateUs => isHindi ? 'रेटिंग दें' : 'Rate Us';
  String get rateUsSub => isHindi ? 'आपकी राय मायने रखती है' : 'Your feedback matters';
  String get settings => isHindi ? 'सेटिंग्स' : 'Settings';
  String get settingsSub => isHindi ? 'ऐप प्राथमिकताएं' : 'App preferences';
  String get myBookings => isHindi ? 'मेरी बुकिंग' : 'My Bookings';
  String get myBookingsSub => isHindi ? 'प्रसाद/सेवा बुकिंग देखें और प्रबंधित करें' : 'View & manage prasad/seva bookings';
  String get viewOnMap => isHindi ? 'मैप पर देखें' : 'View on map';
  String get callTempleOffice => isHindi ? 'मंदिर ऑफिस पर कॉल करें' : 'Call temple office';
  String get comingSoon => isHindi ? 'जल्द आ रहा है! 🙏' : 'Coming soon! 🙏';

  // ── Bookings screen ──
  String get prasad => isHindi ? 'प्रसाद' : 'Prasad';
  String get seva => isHindi ? 'सेवा' : 'Seva';
  String get phoneNumber => isHindi ? 'फ़ोन नंबर' : 'Phone number';
  String get viewLoad => isHindi ? 'देखें' : 'Load';
  String get errorPhoneRequired => isHindi ? 'बुकिंग देखने के लिए फ़ोन नंबर दर्ज करें' : 'Enter your phone number to view bookings';
  String get errorLoadFailed => isHindi ? 'बुकिंग लोड नहीं हो सकीं। कृपया पुनः प्रयास करें।' : 'Failed to load bookings. Please try again.';
  String get noPrasadBookings => isHindi ? 'प्रसाद की कोई बुकिंग नहीं मिली' : 'No prasad bookings found';
  String get noSevaBookings => isHindi ? 'सेवा की कोई बुकिंग नहीं मिली' : 'No seva bookings found';
  String get update => isHindi ? 'संशोधित करें' : 'Update';
  String get cancel => isHindi ? 'रद्द करें' : 'Cancel';
  String get cancelBooking => isHindi ? 'बुकिंग रद्द करें?' : 'Cancel booking?';
  String get no => isHindi ? 'नहीं' : 'No';
  String get ref => isHindi ? 'संदर्भ' : 'Ref';
  String get quantity => isHindi ? 'मात्रा' : 'Qty';
  String get total => isHindi ? 'कुल' : 'Total';
  String get address => isHindi ? 'पता' : 'Address';
  String get preferred => isHindi ? 'पसंदीदा' : 'Preferred';
  String get close => isHindi ? 'बंद करें' : 'Close';
  String get save => isHindi ? 'सहेजें' : 'Save';
  String get optional => isHindi ? 'वैकल्पिक' : 'optional';
  String get quantityLabel => isHindi ? 'मात्रा' : 'Quantity';
  String get addressDelivery => isHindi ? 'पता (डिलीवरी के लिए)' : 'Address (for delivery)';
  String get notesOptional => isHindi ? 'नोट (वैकल्पिक)' : 'Notes (optional)';
  String get preferredDateOptional => isHindi ? 'पसंदीदा तारीख (वैकल्पिक)' : 'Preferred date (optional)';
  String get editPrasadTitle => isHindi ? 'प्रसाद बुकिंग संशोधित करें' : 'Update Prasad booking';
  String get editSevaTitle => isHindi ? 'सेवा बुकिंग संशोधित करें' : 'Update Seva booking';
  String get pickup => isHindi ? 'पिकअप' : 'Pickup';
  String get delivery => isHindi ? 'डिलीवरी' : 'Delivery';

  // ── Language toggle labels (for the switch on home) ──
  String get langHindi => 'हि';
  String get langEnglish => 'EN';

  // ── Settings screen ──
  String get settingsAppearance => isHindi ? 'दिखावट' : 'Appearance';
  String get settingsTheme => isHindi ? 'थीम' : 'Theme';
  String get settingsThemeLight => isHindi ? 'लाइट' : 'Light';
  String get settingsThemeDark => isHindi ? 'डार्क' : 'Dark';
  String get settingsThemeSystem => isHindi ? 'सिस्टम' : 'System';
  String get settingsFontSize => isHindi ? 'फ़ॉन्ट साइज़' : 'Font Size';
  String get settingsFontSmall => isHindi ? 'छोटा' : 'Small';
  String get settingsFontNormal => isHindi ? 'सामान्य' : 'Normal';
  String get settingsFontLarge => isHindi ? 'बड़ा' : 'Large';
  String get settingsFontExtraLarge => isHindi ? 'बहुत बड़ा' : 'Extra Large';
  String get settingsLanguage => isHindi ? 'भाषा' : 'Language';
  String get settingsLanguageHindi => isHindi ? 'हिन्दी' : 'Hindi';
  String get settingsLanguageEnglish => isHindi ? 'अंग्रेज़ी' : 'English';
  String get settingsNotifications => isHindi ? 'सूचनाएं' : 'Notifications';
  String get settingsNotificationsSub => isHindi ? 'पुश सूचना प्राथमिकताएं' : 'Push notification preferences';
  String get settingsNotificationsComingSoon => isHindi ? 'पुश सूचनाएं जल्द आ रही हैं' : 'Push notifications coming soon';
  String get settingsLegal => isHindi ? 'कानूनी' : 'Legal';
  String get settingsPrivacy => isHindi ? 'गोपनीयता नीति' : 'Privacy Policy';
  String get settingsTerms => isHindi ? 'सेवा की शर्तें' : 'Terms of Service';
  String get settingsAbout => isHindi ? 'जानकारी' : 'About';
  String get settingsVersion => isHindi ? 'संस्करण' : 'Version';
  String get settingsDeveloper => isHindi ? 'विकासकर्ता' : 'Developer';

  // ── Panchang screen ──
  String get panchangNotFound => isHindi
      ? 'आज का पंचांग उपलब्ध नहीं है।'
      : 'Today''s Panchang is not available.';
  String get panchangError =>
      isHindi ? 'पंचांग लोड करने में त्रुटि हुई।' : 'Failed to load Panchang.';
}
