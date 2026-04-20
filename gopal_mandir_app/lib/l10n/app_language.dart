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

  /// Bottom-nav label for the merged hub screen. Short enough to fit under
  /// a Material [NavigationBar] destination without clipping.
  String get navSevaAndOfferings => isHindi ? 'सेवा' : 'Seva';

  /// Full title for the merged hub screen's AppBar and home-grid label.
  String get sevaAndOfferingsTitle =>
      isHindi ? 'सेवा एवं भेंट' : 'Seva & Offerings';

  /// Compact home-grid label (the home tiles prefer 2-line text for balance
  /// with neighbours like "Book\nPrasad").
  String get quickSevaAndOfferings =>
      isHindi ? 'सेवा एवं\nभेंट' : 'Seva &\nOfferings';

  // ── Temple Info + Succession (home tiles + dedicated screens) ──

  /// Home-grid label for the existing AboutTempleScreen.
  String get quickTempleInfo => isHindi ? 'मंदिर\nजानकारी' : 'Temple\nInfo';

  /// Home-grid label for the new SuccessionsScreen (guru lineage).
  String get quickSuccession => isHindi ? 'परम्परा' : 'Succession';

  /// AppBar title for the SuccessionsScreen.
  String get successionsScreenTitle => isHindi ? 'परम्परा' : 'Succession';

  /// Shown when the successions list is empty on the public screen.
  String get successionsEmpty => isHindi
      ? 'अभी परम्परा जानकारी उपलब्ध नहीं है'
      : 'Succession details not available yet';

  String get successionReadMore => isHindi ? 'और पढ़ें' : 'Read more';
  String get successionReadLess => isHindi ? 'कम पढ़ें' : 'Read less';

  // Admin strings for Succession management.
  String get adminSuccessions => isHindi ? 'परम्परा प्रबंधन' : 'Successions';
  String get adminSuccessionsSub =>
      isHindi ? 'गुरु / महन्त परम्परा जोड़ें, संपादित करें' : 'Add, edit or delete lineage entries';
  String get adminSuccessionNew => isHindi ? 'नई प्रविष्टि' : 'New succession';
  String get adminSuccessionEdit => isHindi ? 'प्रविष्टि संपादित करें' : 'Edit succession';
  String get fieldPosition => isHindi ? 'क्रम' : 'Position';
  String get fieldTitle => isHindi ? 'उपाधि' : 'Title';
  String get fieldTenure => isHindi ? 'कार्यकाल' : 'Tenure';
  String get fieldTenureStart => isHindi ? 'आरम्भ तिथि' : 'Start date';
  String get fieldTenureEnd => isHindi ? 'समाप्ति तिथि' : 'End date';
  String get fieldBio => isHindi ? 'परिचय' : 'Biography';
  String get fieldQuote => isHindi ? 'उद्धरण / श्लोक' : 'Quote';
  String get fieldPhoto => isHindi ? 'चित्र' : 'Photo';
  String get successionTenureRange => isHindi ? 'कार्यकाल' : 'Tenure';
  String get successionNoPhoto =>
      isHindi ? 'चित्र उपलब्ध नहीं' : 'No photo available';
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
  String get quickAskAstrologer => isHindi ? 'ज्योतिष\nसलाह' : 'Ask\nAstrologer';
  String get quickCommunityQA => isHindi ? 'समुदाय\nप्रश्न' : 'Community\nQ&A';
  String get seoHeading => isHindi ? 'गोपाल मंदिर, गोपाल जी और मथुरा भक्ति' : 'Gopal Mandir, Gopal Ji and Mathura Bhakti';
  String get seoIntro => isHindi
      ? 'श्री गोपाल मंदिर ऐप में भक्तों के लिए दर्शन, आरती समय, सेवा, उत्सव और आध्यात्मिक अपडेट हिंदी व English में उपलब्ध हैं।'
      : 'Shri Gopal Mandir app helps devotees access darshan, aarti timings, seva, festivals, and spiritual updates in Hindi and English.';
  String get seoMathuraTitle => isHindi ? 'गोपाल जी मथुरा भाव' : 'Gopal Ji Mathura Intent';
  String get seoMathuraBody => isHindi
      ? 'जो भक्त गोपाल जी मथुरा, मथुरा मंदिर या श्री गोपाल जी की भक्ति खोजते हैं, उनके लिए यह मंच नियमित धार्मिक जानकारी और कार्यक्रम अपडेट देता है।'
      : 'For people searching Gopal Ji Mathura, Mathura mandir, or Shri Gopal Ji devotion, this platform provides regular spiritual content and event updates.';
  String get seoLinksTitle => isHindi ? 'भक्ति पेज देखें' : 'Explore Devotion Pages';
  String get seoLinkMandir => isHindi ? 'गोपाल मंदिर पेज' : 'Gopal Mandir page';
  String get seoLinkLaddu => isHindi ? 'लड्डू गोपाल पेज' : 'Laddu Gopal page';
  String get seoLinkMathura => isHindi ? 'गोपाल जी मथुरा पेज' : 'Gopal Ji Mathura page';
  String get festivalsLabel => isHindi ? 'उत्सव' : 'Festivals';
  String get muteLabel => isHindi ? 'म्यूट' : 'Mute';
  String get unmuteLabel => isHindi ? 'अनम्यूट' : 'Unmute';
  String get tapToEnter => isHindi ? 'प्रवेश हेतु टैप करें' : 'Tap to enter';
  String get liveDarshanLabel => isHindi ? 'लाइव दर्शन' : 'Live Darshan';
  String get bannerTodayDarshan => isHindi
      ? 'श्री गोपाल वैष्णव पीठ गोपाल मंदिर — आज का दर्शन'
      : 'Shri Gopal Vaishnav Pith Shri Gopal Mandir — Today\'s Darshan';
  String get eventsTitle => isHindi ? 'उत्सव एवं कार्यक्रम' : 'Events and Programs';
  String get retryLabel => isHindi ? 'पुनः प्रयास करें' : 'Retry';
  String get featuredLabel => isHindi ? 'विशेष' : 'Featured';
  String get joinLabel => isHindi ? 'जुड़ें' : 'Join';
  String get donateLabel => isHindi ? 'दान' : 'Donate';
  String get unavailableLabel => isHindi ? 'उपलब्ध नहीं' : 'Unavailable';
  String get bookSevaCta => isHindi ? 'सेवा बुक करें' : 'Book Seva';
  String get bookLabel => isHindi ? 'बुक करें' : 'Book';
  String commentsFor(String title) => isHindi ? '$title के लिए टिप्पणियां' : 'Comments for $title';
  String joinFor(String title) => isHindi ? '$title में शामिल हों' : 'Join $title';
  String get noCommentsYet => isHindi ? 'अभी कोई टिप्पणी नहीं। पहली टिप्पणी करें!' : 'No comments yet. Be the first!';
  String get yourComment => isHindi ? 'आपकी टिप्पणी' : 'Your Comment';
  String get postComment => isHindi ? 'टिप्पणी पोस्ट करें' : 'Post Comment';
  String get failedToAddComment => isHindi ? 'टिप्पणी जोड़ने में विफल' : 'Failed to add comment';
  String get allLabel => isHindi ? 'सभी' : 'All';
  String get pleaseEnterNameAndComment => isHindi ? 'कृपया नाम और टिप्पणी दर्ज करें' : 'Please enter name and comment';
  String get pleaseEnterNameAndPhone => isHindi ? 'कृपया नाम और फोन दर्ज करें' : 'Please enter name and phone';
  String get confirmJoin => isHindi ? 'शामिल होना पुष्टि करें' : 'Confirm Join';
  String get notesOptionalLabel => isHindi ? 'नोट्स (वैकल्पिक)' : 'Notes (optional)';
  String get donateForEvent => isHindi ? 'इस कार्यक्रम के लिए दान' : 'Donate for this event';
  String get selectAmount => isHindi ? 'राशि चुनें (₹)' : 'Select Amount (₹)';
  String get purpose => isHindi ? 'उद्देश्य' : 'Purpose';
  String get donationSubtitle => isHindi
      ? 'आपका योगदान मंदिर सेवा और समुदाय कल्याण में सहायक है'
      : 'Your contribution supports temple seva and community welfare';
  String get otherLabel => isHindi ? 'अन्य' : 'Other';
  String get amountMin100Label => isHindi ? 'राशि (₹, न्यूनतम 100)' : 'Amount (₹, min 100)';
  String get enterAmount => isHindi ? 'राशि दर्ज करें' : 'Enter an amount';
  String get enterValidNumber => isHindi ? 'मान्य संख्या दर्ज करें' : 'Enter a valid number';
  String get minimumDonation100 => isHindi ? 'न्यूनतम दान ₹100 है' : 'Minimum donation is ₹100';
  String get maximumDonationLimit => isHindi ? 'अधिकतम राशि ₹5,00,000 है' : 'Maximum amount is ₹5,00,000';
  String get yourNameLabel => isHindi ? 'आपका नाम' : 'Your Name';
  String get nameOptional => isHindi ? 'नाम (वैकल्पिक)' : 'Name (optional)';
  String get phoneNumberLabel => isHindi ? 'फोन नंबर' : 'Phone Number';
  String get emailOptionalLabel => isHindi ? 'ईमेल (वैकल्पिक)' : 'Email (optional)';
  String get messageOptionalLabel => isHindi ? 'संदेश (वैकल्पिक)' : 'Message (optional)';
  String get pleaseEnterName => isHindi ? 'कृपया नाम दर्ज करें' : 'Please enter your name';
  String get nameTooShort => isHindi ? 'नाम बहुत छोटा है' : 'Name is too short';
  String get pleaseEnterPhone => isHindi ? 'कृपया फोन नंबर दर्ज करें' : 'Please enter phone number';
  String get enterValidPhone => isHindi ? 'मान्य फोन नंबर दर्ज करें' : 'Enter a valid phone number';
  String get enterValidEmail => isHindi ? 'मान्य ईमेल दर्ज करें' : 'Enter a valid email';
  String donateWithAmount(String amount) => isHindi ? '₹$amount दान करें' : 'Donate ₹$amount';
  String get secureTrusted => isHindi ? 'सुरक्षित और विश्वसनीय' : 'Secure & Trusted';
  String get enterValidAmountMin100 => isHindi ? 'मान्य राशि दर्ज करें (न्यूनतम ₹100)।' : 'Enter a valid amount (minimum ₹100).';
  String get paymentStartFailed => isHindi ? 'भुगतान शुरू नहीं हो सका। बाद में पुनः प्रयास करें।' : 'Could not start payment. Try again later.';
  String errorWithDetail(String msg) => isHindi ? 'त्रुटि: $msg' : 'Error: $msg';
  String referenceSaved(String ref) => isHindi
      ? 'संदर्भ सहेजा गया: $ref — टीम फॉलोअप करेगी।'
      : 'Reference saved: $ref — team can follow up.';
  String get onlineDonationMobileOnly => isHindi
      ? 'ऑनलाइन दान Android या iOS पर चलता है। भुगतान हेतु फोन पर ऐप खोलें।'
      : 'Online donation runs on Android or iOS. Open the app on your phone to pay.';
  String get paymentCancelled => isHindi ? 'भुगतान रद्द कर दिया गया।' : 'Payment was cancelled.';
  String get thankYouTitle => isHindi ? 'धन्यवाद!' : 'Thank you!';
  String donationReceived(String amount) => isHindi
      ? 'धन्यवाद! आपका ₹$amount दान प्राप्त हुआ। जय गोपाल!'
      : 'Thank you! Your donation of ₹$amount was received. Jai Gopal!';
  String eventDonationReceived(String amount) => isHindi
      ? 'धन्यवाद! इस कार्यक्रम के लिए आपका ₹$amount दान प्राप्त हुआ। जय गोपाल!'
      : 'Thank you! Your donation of ₹$amount for this event was received. Jai Gopal!';
  String get paymentCompletedAwaitingConfirm => isHindi
      ? 'धन्यवाद! आपका भुगतान पूरा हुआ। पुष्टि थोड़ी देर में आ सकती है। जय गोपाल!'
      : 'Thank you! Your payment completed. Confirmation may arrive in a moment. Jai Gopal!';
  String referenceId(String ref) => isHindi ? 'संदर्भ आईडी: $ref' : 'Reference ID: $ref';
  String get okLabel => isHindi ? 'ठीक है' : 'OK';
  String get bookingConfirmed => isHindi ? 'बुकिंग पुष्टि' : 'Booking Confirmed';
  String get onlineMinOrder100 => isHindi
      ? 'ऑनलाइन भुगतान के लिए कुल राशि कम से कम ₹100 होनी चाहिए।'
      : 'Online payment requires a minimum order total of ₹100.';
  String get prasadBookingTitle => isHindi ? 'प्रसाद बुक करें' : 'Book Prasad';
  String get quantityTitle => isHindi ? 'मात्रा' : 'Quantity';
  String subtotalAmount(String amount) => isHindi ? 'उप-योग: ₹$amount' : 'Subtotal: ₹$amount';
  String deliveryAmount(String amount) => isHindi ? 'डिलीवरी (10%): ₹$amount' : 'Delivery (10%): ₹$amount';
  String totalAmount(String amount) => isHindi ? 'कुल: ₹$amount' : 'Total: ₹$amount';
  String get min100IncreaseQty => isHindi
      ? 'ऑनलाइन भुगतान हेतु न्यूनतम ₹100 — मात्रा बढ़ाएं।'
      : 'Minimum ₹100 for online payment — increase quantity.';
  String get fulfillmentLabel => isHindi ? 'प्राप्ति प्रकार' : 'Fulfillment';
  String get paymentLabel => isHindi ? 'भुगतान' : 'Payment';
  String get payAtTemple => isHindi ? 'मंदिर में भुगतान' : 'Pay at temple';
  String get payOnline => isHindi ? 'ऑनलाइन भुगतान' : 'Pay online';
  String get deliveryAddress => isHindi ? 'डिलीवरी पता' : 'Delivery Address';
  String get enterDeliveryAddress => isHindi ? 'कृपया डिलीवरी पता दर्ज करें' : 'Please enter delivery address';
  String get addressTooShort => isHindi ? 'पता बहुत छोटा है' : 'Address is too short';
  String payAmount(String amount) => isHindi ? '₹$amount भुगतान करें' : 'Pay ₹$amount';
  String bookAndPayAtTemple(String amount) =>
      isHindi ? 'बुक करें • ₹$amount मंदिर में भुगतान' : 'Book • Pay ₹$amount at temple';
  String prasadBookedToast(String name) => isHindi ? '🙏 $name प्रसाद बुक हुआ! जय गोपाल!' : '🙏 $name booked! Jai Gopal!';
  String get sevaBookingTitle => isHindi ? 'सेवा बुक करें' : 'Book Seva';
  String get sevaBookingDialogTitle => isHindi ? 'सेवा बुकिंग' : 'Seva Booking';
  String sevaBookedToast(String name) => isHindi ? '🙏 $name सेवा बुक हुई! जय गोपाल!' : '🙏 $name seva booked! Jai Gopal!';
  String get sevaBelow100Info => isHindi
      ? 'यह सेवा ₹100 से कम है — आपकी बुकिंग बिना ऑनलाइन भुगतान के जमा होगी।'
      : 'This seva is listed under ₹100 — your booking is submitted without online payment.';
  String get yourDetails => isHindi ? 'आपका विवरण' : 'Your Details';
  String get fullName => isHindi ? 'पूरा नाम' : 'Full Name';
  String get validPhoneShort => isHindi ? 'कृपया मान्य फोन दर्ज करें' : 'Please enter a valid phone';
  String get confirmSevaBooking => isHindi ? 'सेवा बुकिंग पुष्टि करें' : 'Confirm Seva Booking';
  String get payAndBookSeva => isHindi ? 'भुगतान करें और सेवा बुक करें' : 'Pay & book seva';
  String get paymentReceivedSeva => isHindi
      ? 'भुगतान प्राप्त हुआ। आपकी सेवा बुकिंग पुष्टि है। जय गोपाल!'
      : 'Payment received. Your seva booking is confirmed. Jai Gopal!';
  String get paymentCompletedSeva => isHindi
      ? 'भुगतान पूरा हुआ। पुष्टि थोड़ी देर में आएगी। जय गोपाल!'
      : 'Payment completed. Confirmation may take a moment. Jai Gopal!';
  String get paymentReceivedPrasad => isHindi
      ? 'भुगतान प्राप्त हुआ। आपकी प्रसाद बुकिंग पुष्टि है। जय गोपाल!'
      : 'Payment received. Your prasad order is confirmed. Jai Gopal!';
  String get paymentCompletedPrasad => isHindi
      ? 'भुगतान पूरा हुआ। पुष्टि थोड़ी देर में आएगी। जय गोपाल!'
      : 'Payment completed. Confirmation may take a moment. Jai Gopal!';
  String get membershipTitle => isHindi ? 'सदस्यता' : 'Membership';
  String get membershipJoin => isHindi ? 'सदस्य बनें' : 'Join as a member';
  String get sendOtp => isHindi ? 'OTP भेजें' : 'Send OTP';
  String get enterOtp => isHindi ? 'OTP दर्ज करें' : 'Enter OTP';
  String get verifyJoin => isHindi ? 'सत्यापित करें और जुड़ें' : 'Verify & Join';
  String get logoutLabel => isHindi ? 'लॉगआउट' : 'Logout';
  String get yourMembership => isHindi ? 'आपकी सदस्यता' : 'Your membership';
  String get phoneLabel => isHindi ? 'फोन' : 'Phone';
  String get nameLabel => isHindi ? 'नाम' : 'Name';
  String get emailLabel => isHindi ? 'ईमेल' : 'Email';
  String get statusLabel => isHindi ? 'स्थिति' : 'Status';
  String get membershipSessionLoadError => isHindi
      ? 'सदस्यता सत्र लोड नहीं हो सका। कृपया पुनः प्रयास करें।'
      : 'Could not load membership session. Please try again.';
  String get sessionExpiredRequestOtp => isHindi
      ? 'सत्र समाप्त हो गया। कृपया फिर से OTP मांगें।'
      : 'Session expired. Please request OTP again.';
  String membershipLoadError(String msg) => isHindi
      ? 'सदस्यता सत्र लोड नहीं हो सका: $msg'
      : 'Could not load membership session: $msg';
  String get failedToSendOtp => isHindi ? 'OTP भेजने में विफल' : 'Failed to send OTP';
  String get enterPhoneAndOtp => isHindi ? 'कृपया फोन और OTP दर्ज करें' : 'Please enter phone and OTP';
  String get otpVerificationFailed => isHindi ? 'OTP सत्यापन विफल' : 'OTP verification failed';
  String devOtpValue(String otp) => isHindi ? 'डेव OTP: $otp' : 'Dev OTP: $otp';
  String get videoUrlMissing => isHindi ? 'वीडियो URL उपलब्ध नहीं है' : 'Video URL missing';
  String get invalidVideoUrl => isHindi ? 'अमान्य वीडियो URL' : 'Invalid video URL';
  String get cannotOpenVideoUrl => isHindi ? 'वीडियो URL नहीं खुल सका' : 'Cannot open video URL';
  String get adminLoginTitle => isHindi ? 'मंदिर स्टाफ लॉगिन' : 'Temple staff login';
  String get adminSecretCodeMode => isHindi ? 'सीक्रेट कोड' : 'Secret code';
  String get adminPhoneOtpMode => isHindi ? 'फोन OTP' : 'Phone OTP';
  String get adminSecretHint => isHindi
      ? 'ओनर द्वारा जनरेट किया गया सीक्रेट कोड लॉगिन। कोड एक बार उपयोगी है और समाप्त हो जाता है।'
      : 'Owner-generated secret code login. Code is single-use and expires.';
  String get adminOtpHint => isHindi
      ? 'एडमिन एक्सेस केवल पंजीकृत मंदिर फोन के लिए है। OTP केवल अधिकृत नंबर पर भेजा जाता है।'
      : 'Admin access is restricted to registered temple phones. OTP is sent only for authorized numbers.';
  String get adminDisplayNameOptional => isHindi
      ? 'डिस्प्ले नाम (वैकल्पिक, पहली लॉगिन)'
      : 'Display name (optional, first login)';
  String get adminSecretCode => isHindi ? 'सीक्रेट कोड' : 'Secret code';
  String get adminLoginWithSecret => isHindi ? 'सीक्रेट कोड से लॉगिन' : 'Login with secret code';
  String get adminRequestOtp => isHindi ? 'OTP मांगें' : 'Request OTP';
  String get adminVerifySignIn => isHindi ? 'सत्यापित करें और लॉगिन' : 'Verify & sign in';
  String get adminInvalidOtp => isHindi ? 'अमान्य OTP' : 'Invalid OTP';
  String get adminInvalidSecret => isHindi ? 'अमान्य सीक्रेट कोड' : 'Invalid secret code';
  String get adminTooManyOtpRequests => isHindi ? 'बहुत अधिक OTP अनुरोध।' : 'Too many OTP requests.';
  String adminTryAgainIn(String wait) => isHindi ? '$wait में पुनः प्रयास करें।' : 'Try again in $wait.';
  String attemptsUsed(int used, int limit) => isHindi ? '($used/$limit प्रयास उपयोग)' : '($used/$limit attempts used)';
  String get adminOtpSendFailed => isHindi
      ? 'OTP भेजा नहीं जा सका। यह नंबर एडमिन के रूप में पंजीकृत नहीं हो सकता।'
      : 'Could not send OTP. This number may not be registered as admin.';
  String get adminHomeTitle => isHindi ? 'एडमिन' : 'Admin';
  String get adminOwnerAccess => isHindi ? 'ओनर एक्सेस' : 'Owner access';
  String get adminOwnerAccessSub => isHindi ? 'सीक्रेट कोड बनाएं और एडमिन अधिकार प्रबंधित करें' : 'Generate secret codes and manage admin rights';
  String get adminRecentActivity => isHindi ? 'हाल की गतिविधि' : 'Recent activity';
  String get adminRecentActivitySub => isHindi ? 'प्रसाद, सेवा, दान, सदस्य आदि के अपडेट' : 'Cross-module updates — prasad, seva, donations, members, and more';
  String get adminGallery => isHindi ? 'गैलरी' : 'Gallery';
  String get adminGallerySub => isHindi ? 'छवियां और वीडियो अपलोड व प्रबंधन' : 'Upload & manage images and videos';
  String get adminLiveDarshan => isHindi ? 'लाइव दर्शन' : 'Live Darshan';
  String get adminLiveDarshanSub => isHindi ? 'स्ट्रीम URL और लाइव स्थिति' : 'Stream URL and on-air flag';
  String get adminPrasadOrders => isHindi ? 'प्रसाद ऑर्डर' : 'Prasad orders';
  String get adminPrasadOrdersSub => isHindi ? 'ऑर्डर स्थिति फिल्टर और अपडेट करें' : 'Filter and update order status';
  String get adminPanchang => isHindi ? 'पंचांग' : 'Panchang';
  String get adminPanchangSub => isHindi ? 'दैनिक हिंदू पंचांग जोड़ें/संपादित करें' : 'Add & edit daily Hindu Panchang';
  String get adminFestivals => isHindi ? 'उत्सव' : 'Festivals';
  String get adminFestivalsSub => isHindi ? 'तारीख-आधारित उत्सव/कार्यक्रम CRUD' : 'Date-wise festivals/events CRUD';
  String get adminSevaItems => isHindi ? 'सेवा आइटम' : 'Seva Items';
  String get adminSevaItemsSub => isHindi ? 'सेवा ऑफर जोड़ें, संपादित करें, हटाएं' : 'Add, edit & remove seva offerings';
  String get adminSevaBookings => isHindi ? 'सेवा बुकिंग' : 'Seva Bookings';
  String get adminSevaBookingsSub => isHindi ? 'सेवा बुकिंग स्थिति देखें/अपडेट करें' : 'View & update seva booking status';
  String get adminPoojaOfferings => isHindi ? 'पूजा ऑफरिंग' : 'Pooja offerings';
  String get adminPoojaOfferingsSub => isHindi ? 'अनुष्ठान और पैकेज' : 'Ceremonies & packages';
  String get adminPoojaAvailability => isHindi ? 'पूजा उपलब्धता' : 'Pooja availability';
  String get adminPoojaAvailabilitySub => isHindi ? 'गुरु जी/बाबा जी स्लॉट और दैनिक सीमा' : 'Guru Ji & Baba Ji — slots and daily limits';
  String get adminPoojaBookings => isHindi ? 'पूजा बुकिंग' : 'Pooja bookings';
  String get adminPoojaBookingsSub => isHindi ? 'अनुरोध, भुगतान मोड, ऑफलाइन भुगतान प्रबंधन' : 'Confirm requests, payment mode, offline paid';
  String get adminEvents => isHindi ? 'कार्यक्रम' : 'Events';
  String get adminEventsSub => isHindi ? 'मंदिर कार्यक्रम जोड़ें, संपादित करें, हटाएं' : 'Add, edit & remove temple events';
  String get adminEventParticipations => isHindi ? 'कार्यक्रम सहभागिता' : 'Event Participations';
  String get adminEventParticipationsSub => isHindi ? 'किसने कार्यक्रम जॉइन किया देखें' : 'View who joined each event';
  String get adminEventDonations => isHindi ? 'कार्यक्रम दान' : 'Event Donations';
  String get adminEventDonationsSub => isHindi ? 'सभी कार्यक्रम दान देखें' : 'View all event donations';
  String get adminGeneralDonations => isHindi ? 'सामान्य दान' : 'General Donations';
  String get adminGeneralDonationsSub => isHindi ? 'भुगतान स्थिति, विफलताएं और दाता संपर्क' : 'Payment status, failures, and donor contact';
  String get adminAartiSchedule => isHindi ? 'आरती समय' : 'Aarti Schedule';
  String get adminAartiScheduleSub => isHindi ? 'आरती समय जोड़ें, संपादित करें, हटाएं' : 'Add, edit & remove aarti timings';
  String get adminDainikShlok => isHindi ? 'दैनिक श्लोक' : 'Dainik Shlok';
  String get adminDainikShlokSub => isHindi ? 'होम स्क्रीन दैनिक श्लोक अपडेट करें' : 'Update home screen daily shlok content';
  String get adminAboutTemple => isHindi ? 'मंदिर के बारे में' : 'About Temple';
  String get adminAboutTempleSub => isHindi ? 'More → About Temple की जानकारी' : 'History and info on More → About Temple';
  String get adminDailyUpasana => isHindi ? 'दैनिक उपासना' : 'Daily Upasana';
  String get adminDailyUpasanaSub => isHindi ? 'दैनिक उपासना पाठ बनाएं और प्रबंधित करें' : 'Create and manage daily upasana readings';
  String get adminMembers => isHindi ? 'सदस्य' : 'Members';
  String get adminMembersSub => isHindi ? 'मंदिर सदस्यों को देखें और प्रबंधित करें' : 'View & manage temple members';
  String get adminVolunteerRequests => isHindi ? 'स्वयंसेवक अनुरोध' : 'Volunteer Requests';
  String get adminVolunteerRequestsSub => isHindi ? 'स्वयंसेवक आवेदन की समीक्षा और प्रबंधन' : 'Review & manage volunteer applications';
  String get adminFeedbackQueue => isHindi ? 'फीडबैक कतार' : 'Feedback Queue';
  String get adminFeedbackQueueSub => isHindi ? 'यूजर फीडबैक की ट्रायेज और प्रतिक्रिया' : 'Triage and respond to user feedback';
  String get adminFeedbackAnalytics => isHindi ? 'फीडबैक विश्लेषण' : 'Feedback Analytics';
  String get adminFeedbackAnalyticsSub => isHindi ? 'रेटिंग, ट्रेंड और क्लोजर मीट्रिक्स' : 'Ratings, trends and closure metrics';
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
  String get askAstrologer => isHindi ? 'ज्योतिषी से पूछें' : 'Ask an Astrologer';
  String get askAstrologerSub => isHindi
      ? 'कुंडली, मुहूर्त, हस्तरेखा और आध्यात्मिक प्रश्न'
      : 'Kundali, muhurat, palmistry & spiritual queries';
  String get communityQA => isHindi ? 'समुदाय प्रश्नोत्तर' : 'Community Q&A';
  String get communityQASub => isHindi
      ? 'भक्तों से प्रश्न पूछें और उत्तर पाएँ'
      : 'Ask and discover answers from our community';
  String get adminAstroConsult => isHindi ? 'ज्योतिष अनुरोध' : 'Astro Consultations';
  String get adminAstroConsultSub => isHindi
      ? 'ज्योतिष/मुहूर्त अनुरोधों का प्रबंधन'
      : 'Manage astrology & muhurat requests';
  String get adminCommunityQA => isHindi ? 'समुदाय मॉडरेशन' : 'Community Moderation';
  String get adminCommunityQASub => isHindi
      ? 'प्रश्न, उत्तर और टिप्पणियाँ प्रबंधित करें'
      : 'Manage posts, answers and comments';
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
