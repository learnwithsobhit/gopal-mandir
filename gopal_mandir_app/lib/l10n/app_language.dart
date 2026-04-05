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
  String get appTitle => isHindi ? 'श्री गोपाल वैष्णव पीठ गोपाल मंदिर' : 'Shri Gopal Vaishnav Pith Shri Gopal Mandir';
  String get navHome => isHindi ? 'होम' : 'Home';
  String get navSeva => isHindi ? 'सेवा' : 'Seva';
  String get navLive => isHindi ? 'लाइव' : 'Live';
  String get navEvents => isHindi ? 'कार्यक्रम' : 'Events';
  String get navMore => isHindi ? 'अधिक' : 'More';

  // ── Home ──
  String get templeName => isHindi ? 'श्री गोपाल वैष्णव पीठ गोपाल मंदिर' : 'Shri Gopal Vaishnav Pith Shri Gopal Mandir';
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
  String get galleryScreenTitle => isHindi ? 'चित्र व ध्वनि गैलरी' : 'Photo & audio gallery';
  String get galleryAudioUrlMissing =>
      isHindi ? 'ऑडियो लिंक उपलब्ध नहीं है' : 'Audio URL missing';
  String get galleryInvalidAudioUrl =>
      isHindi ? 'अमान्य ऑडियो लिंक' : 'Invalid audio URL';
  String get galleryCouldNotLoadAudio =>
      isHindi ? 'ऑडियो लोड नहीं हो सका' : 'Could not load audio';
  String get quickLiveDarshan => isHindi ? 'लाइव\nदर्शन' : 'Live\nDarshan';
  String get liveDarshanScreenTitle => isHindi ? 'लाइव दर्शन' : 'Live Darshan';
  String get liveDarshanComingSoonHeadline =>
      isHindi ? 'लाइव दर्शन शीघ्र उपलब्ध' : 'Live darshan coming soon';
  String get liveDarshanSoonBadge => isHindi ? 'शीघ्र उपलब्ध' : 'Coming soon';
  String get liveDarshanLiveBadge => 'LIVE';
  String get liveDarshanDefaultDescription => isHindi
      ? 'लाइव दर्शन जल्द उपलब्ध होगा। आप कहीं से भी श्री गोपाल जी के दर्शन कर सकेंगे।'
      : 'Live darshan streaming will be available soon. You will be able to watch Shri Gopal Ji\'s darshan from anywhere.';
  String get liveDarshanStaffHint => isHindi
      ? 'मंदिर स्टाफ: ऐडमिन में लाइव दर्शन खोलकर https स्ट्रीम URL दर्ज करें और लाइव चालू करें।'
      : 'Temple staff: open Admin → Live Darshan, paste an https stream URL, and turn on Live.';
  String get liveDarshanWatchLive => isHindi ? 'लाइव देखें' : 'Watch live';
  String get liveDarshanOpenExternally => isHindi ? 'ब्राउज़र में खोलें' : 'Open in browser';
  String get liveDarshanCannotOpenStream =>
      isHindi ? 'स्ट्रीम नहीं खोल सके' : 'Cannot open stream';
  String get liveDarshanLoadError =>
      isHindi ? 'लाइव दर्शन लोड नहीं हो सका। पुनः प्रयास करें।' : 'Could not load live darshan. Try again.';
  String get liveDarshanRetry => isHindi ? 'पुनः प्रयास' : 'Retry';
  String get liveDarshanJaiGopal => isHindi ? 'जय गोपाल' : 'Jai Gopal';
  String get quickPanchang => isHindi ? 'पंचांग' : 'Panchang';
  String get quickDailyUpasana => isHindi ? 'दैनिक\nउपासना' : 'Daily\nUpasana';
  String get quickPoojaAppointment => isHindi ? 'पूजा\nबुकिंग' : 'Book\nPooja';
  String get dailyUpasanaTitle => isHindi ? 'दैनिक उपासना' : 'Daily Upasana';
  String get dailyUpasanaEmpty =>
      isHindi ? 'कोई उपासना सामग्री उपलब्ध नहीं है' : 'No upasana items available';
  String get dailyUpasanaTopicGeneral =>
      isHindi ? 'सामान्य' : 'General';
  String get dailyUpasanaSearchTopicsHint =>
      isHindi ? 'विषय खोजें…' : 'Search topics…';
  String get dailyUpasanaChapters =>
      isHindi ? 'अध्याय' : 'Chapters';
  String get dailyUpasanaContinueReading =>
      isHindi ? 'पढ़ना जारी रखें' : 'Continue reading';
  String get dailyUpasanaPrevious =>
      isHindi ? 'पिछला' : 'Previous';
  String get dailyUpasanaNext =>
      isHindi ? 'अगला' : 'Next';

  String dailyUpasanaTopicEntryCount(int n) =>
      isHindi ? '$n प्रविष्टियाँ' : '$n entries';

  // ── Pooja appointment ──
  String get poojaAppointmentTitle => isHindi ? 'गुरु/बाबा पूजा बुकिंग' : 'Guru/Baba pooja booking';
  String get poojaAppointmentSubtitle =>
      isHindi ? 'अनुष्ठान के लिए समय निर्धारित करें' : 'Schedule a ceremony with Guru Ji or Baba Ji';
  String get poojaMenuTitle => isHindi ? 'पूजा बुकिंग' : 'Pooja booking';
  String get poojaMenuSub =>
      isHindi ? 'गृह प्रवेश, विवाह, हवन आदि' : 'Griha pravesh, marriage, hawan & more';
  String get poojaOffering => isHindi ? 'अनुष्ठान चुनें' : 'Select ceremony';
  String get poojaPackage => isHindi ? 'पैकेज' : 'Package';
  String get poojaOfficiant => isHindi ? 'किसके साथ' : 'Officiant';
  String get poojaGuru => isHindi ? 'गुरु जी' : 'Guru Ji';
  String get poojaBaba => isHindi ? 'बाबा जी' : 'Baba Ji';
  String get poojaDateSlot => isHindi ? 'तारीख और समय स्लॉट' : 'Date & time slot';
  String get poojaPickDate => isHindi ? 'तारीख चुनें' : 'Pick a date';
  String get poojaVenue => isHindi ? 'स्थान' : 'Venue';
  String get poojaVenueTemple => isHindi ? 'मंदिर में' : 'At temple';
  String get poojaVenueHome => isHindi ? 'घर पर (गृह प्रवेश आदि)' : 'At your home';
  String get poojaEstimated => isHindi ? 'अनुमानित शुल्क' : 'Estimated fee';
  String get poojaYourName => isHindi ? 'आपका नाम' : 'Your name';
  String get poojaNameRequired => isHindi ? 'नाम आवश्यक है' : 'Name is required';
  String get poojaSubmit => isHindi ? 'बुकिंग भेजें' : 'Submit booking';
  String get poojaSelectOffering => isHindi ? 'कृपया अनुष्ठान चुनें' : 'Please select a ceremony';
  String get poojaDateSlotRequired =>
      isHindi ? 'तारीख और स्लॉट चुनें' : 'Please choose date and slot';
  String get poojaAddressRequired => isHindi ? 'घर का पता दर्ज करें' : 'Enter home address';
  String get poojaNoSlots =>
      isHindi ? 'इस अवधि में कोई खाली स्लॉट नहीं। मंदिर से संपर्क करें।' : 'No free slots in this range. Please call the temple.';
  String get poojaNoOfferings =>
      isHindi ? 'अभी कोई सेवा सूचीबद्ध नहीं।' : 'No ceremonies listed yet.';
  String get poojaBookedTitle => isHindi ? 'अनुरोध भेजा गया' : 'Request sent';
  String get poojaRefCopied => isHindi ? 'संदर्भ नंबर कॉपी हो गया' : 'Reference copied';
  String get poojaCopyRef => isHindi ? 'संदर्भ कॉपी करें' : 'Copy reference';
  String get tabPoojaBookings => isHindi ? 'पूजा' : 'Pooja';
  String get noPoojaBookings => isHindi ? 'कोई पूजा बुकिंग नहीं' : 'No pooja bookings found';
  String get poojaReschedule => isHindi ? 'समय बदलें' : 'Reschedule';
  String get poojaPayOnline => isHindi ? 'ऑनलाइन भुगतान' : 'Pay online';
  String get editPoojaTitle => isHindi ? 'पूजा बुकिंग बदलें' : 'Reschedule pooja booking';

  // ── More screen ──
  String get more => isHindi ? 'अधिक' : 'More';
  String get aboutTemple => isHindi ? 'मंदिर के बारे में' : 'About Temple';
  String get aboutTempleSub => isHindi ? 'इतिहास और जानकारी' : 'History and information';
  String get aboutTempleEmpty =>
      isHindi ? 'जानकारी जल्द जोड़ी जाएगी।' : 'Information will be added soon.';
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
  String get myBookingsSub =>
      isHindi ? 'प्रसाद, सेवा और पूजा बुकिंग देखें' : 'View prasad, seva & pooja bookings';
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
  String get create => isHindi ? 'बनाएं' : 'Create';
  String get created => isHindi ? 'बनाया गया' : 'Created';
  String get updated => isHindi ? 'अपडेट किया गया' : 'Updated';
  String get delete => isHindi ? 'हटाएं' : 'Delete';
  String get saving => isHindi ? 'सेव हो रहा है...' : 'Saving...';
  String get updateFailed => isHindi ? 'अपडेट विफल' : 'Update failed';
  String get createFailed => isHindi ? 'बनाना विफल' : 'Create failed';
  String get dailyUpasanaAdminListTitle =>
      isHindi ? 'दैनिक उपासना (एडमिन)' : 'Daily Upasana (admin)';
  String get dailyUpasanaAdminEmpty =>
      isHindi ? 'कोई दैनिक उपासना प्रविष्टि नहीं' : 'No daily upasana entries';
  String get dailyUpasanaAdminDeleteTitle =>
      isHindi ? 'प्रविष्टि हटाएं?' : 'Delete item?';
  String get dailyUpasanaAdminRequired =>
      isHindi ? 'शीर्षक और सामग्री आवश्यक हैं' : 'Title and content are required';
  String get dailyUpasanaAdminEdit =>
      isHindi ? 'दैनिक उपासना संपादित करें' : 'Edit Daily Upasana';
  String get dailyUpasanaAdminNew =>
      isHindi ? 'नई दैनिक उपासना' : 'New Daily Upasana';
  String get dailyUpasanaAdminTitle => isHindi ? 'शीर्षक' : 'Title';
  String get dailyUpasanaAdminCategory =>
      isHindi ? 'श्रेणी (वैकल्पिक)' : 'Category (optional)';
  String get dailyUpasanaAdminSort => isHindi ? 'क्रम' : 'Sort order';
  String get dailyUpasanaAdminPublished => isHindi ? 'प्रकाशित' : 'Published';
  String get dailyUpasanaAdminPublishedSub =>
      isHindi ? 'यूज़र्स को दिखाई देगा' : 'Visible to users';
  String get dailyUpasanaAdminDraftSub =>
      isHindi ? 'केवल ड्राफ्ट' : 'Draft only';
  String get dailyUpasanaAdminContent => isHindi ? 'सामग्री' : 'Content';
  String get dailyUpasanaAdminContentHint => isHindi
      ? 'हिंदी/English दोनों एक साथ लिखें (उदाहरण: श्लोक + translation)'
      : 'Enter Hindi/English mixed content if needed';
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
