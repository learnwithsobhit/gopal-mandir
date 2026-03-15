import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // ──────────────────────────────────────────────
  // 🔧 DEPLOYMENT: After deploying Rust backend to Railway,
  //    replace the baseUrl below with your Railway URL.
  //    Example: 'https://gopal-mandir-api-production.up.railway.app'
  // ──────────────────────────────────────────────
  // static const String baseUrl = 'https://YOUR_RAILWAY_URL'; // Production
  static const String baseUrl = 'http://localhost:8080'; // Local dev

  Future<List<AartiSchedule>> getAartiSchedule() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/aarti'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => AartiSchedule.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching aarti: $e');
    }
    return _defaultAartiSchedule();
  }

  Future<List<Event>> getEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/events'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => Event.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    return _defaultEvents();
  }

  Future<List<GalleryItem>> getGallery() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/gallery'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => GalleryItem.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching gallery: $e');
    }
    return [];
  }

  Future<List<PrasadItem>> getPrasadItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/prasad'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => PrasadItem.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching prasad: $e');
    }
    return _defaultPrasadItems();
  }

  Future<List<SevaItem>> getSevaItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/seva'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => SevaItem.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching seva: $e');
    }
    return _defaultSevaItems();
  }

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/announcements'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => Announcement.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching announcements: $e');
    }
    return _defaultAnnouncements();
  }

  Future<DailyQuote> getDailyQuote() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/daily-quote'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DailyQuote.fromJson(json['data']);
      }
    } catch (e) {
      print('Error fetching quote: $e');
    }
    return _defaultDailyQuote();
  }

  Future<TempleInfo> getTempleInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/temple-info'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TempleInfo.fromJson(json['data']);
      }
    } catch (e) {
      print('Error fetching temple info: $e');
    }
    return _defaultTempleInfo();
  }

  // ── Fallback data when API is unavailable ──

  List<AartiSchedule> _defaultAartiSchedule() => [
    AartiSchedule(id: 1, name: 'Mangla Aarti', time: '05:00 AM', description: 'Morning awakening aarti', isSpecial: false),
    AartiSchedule(id: 2, name: 'Shringar Aarti', time: '07:30 AM', description: 'Decoration aarti', isSpecial: false),
    AartiSchedule(id: 3, name: 'Rajbhog Aarti', time: '11:30 AM', description: 'Mid-day offering', isSpecial: false),
    AartiSchedule(id: 4, name: 'Sandhya Aarti', time: '06:30 PM', description: 'Evening aarti', isSpecial: true),
    AartiSchedule(id: 5, name: 'Shayan Aarti', time: '08:30 PM', description: 'Night rest aarti', isSpecial: false),
  ];

  List<Event> _defaultEvents() => [
    Event(id: 1, title: 'Holi Mahotsav', date: '2026-03-20', description: 'Grand Holi celebration', isFeatured: true),
    Event(id: 2, title: 'Janmashtami', date: '2026-08-25', description: 'Krishna Janmotsav', isFeatured: true),
  ];

  List<PrasadItem> _defaultPrasadItems() => [
    PrasadItem(id: 1, name: 'Peda Prasad', description: 'Traditional Mathura peda', price: 251, available: true),
    PrasadItem(id: 2, name: 'Panchamrit', description: 'Sacred panchamrit', price: 151, available: true),
  ];

  List<SevaItem> _defaultSevaItems() => [
    SevaItem(id: 1, name: 'Abhishek Seva', description: 'Sacred bathing of Gopal Ji', price: 1100, category: 'Daily Seva', available: true),
    SevaItem(id: 2, name: 'Deep Daan', description: 'Light a ghee lamp', price: 501, category: 'Daily Seva', available: true),
  ];

  List<Announcement> _defaultAnnouncements() => [
    Announcement(id: 1, title: 'Welcome', message: 'Jai Gopal! Welcome to Gopal Mandir App.', date: '2026-03-15', isUrgent: false),
  ];

  DailyQuote _defaultDailyQuote() => DailyQuote(
    shlok: 'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।',
    translation: 'You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions.',
    source: 'Bhagavad Gita 2.47',
  );

  TempleInfo _defaultTempleInfo() => TempleInfo(
    name: 'Shri Gopal Mandir',
    address: 'Gopal Mandir Road',
    city: 'Vrindavan, UP',
    phone: '+91 98765 43210',
    email: 'info@shrigopalmandir.org',
    website: 'https://shrigopalmandir.org',
    openingTime: '04:30 AM',
    closingTime: '09:00 PM',
    latitude: 27.5839,
    longitude: 77.6964,
  );
}
