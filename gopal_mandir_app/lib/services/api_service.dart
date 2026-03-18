import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // ──────────────────────────────────────────────
  // 🔧 DEPLOYMENT: After deploying Rust backend to Railway,
  //    replace the baseUrl below with your Railway URL.
  //    Example: 'https://gopal-mandir-api-production.up.railway.app'
  // ──────────────────────────────────────────────
  static const String baseUrl = 'https://gopal-mandir-production.up.railway.app'; // Production
  // static const String baseUrl = 'http://localhost:8080'; // Local dev

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
    final response = await http.get(Uri.parse('$baseUrl/api/events'));
    if (response.statusCode != 200) {
      throw Exception('Events API returned ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>?;
    if (json == null) throw Exception('Invalid events response');
    // Backend returns { "success": true, "data": [...] }
    final data = json['data'];
    if (data == null) return [];
    final List list = data is List ? data : (data is Map ? [data] : []);
    return list.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EventParticipationResponse> joinEvent(
    int eventId,
    EventParticipationRequest req,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/join'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 200) {
        return EventParticipationResponse.fromJson(jsonDecode(response.body));
      }
      String msg = 'Unable to join event';
      try {
        msg = (jsonDecode(response.body)['error'] ?? msg).toString();
      } catch (_) {}
      return EventParticipationResponse(success: false, message: msg);
    } catch (e) {
      print('Error joining event: $e');
      return EventParticipationResponse(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<List<GalleryItem>> getGallery() async {
    return getGalleryPage(1);
  }

  Future<List<GalleryItem>> getGalleryPage(int page, {int perPage = 20}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/gallery').replace(
        queryParameters: {'page': '$page', 'per_page': '$perPage'},
      );
      final response = await http.get(uri);
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

  // ──────────────────────────────────────────────
  // Membership (free) + phone OTP (dev-mode)
  // ──────────────────────────────────────────────

  Future<String?> requestMembershipOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/membership/request-otp'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['success'] == true) {
          return (json['otp'] ?? '').toString();
        }
      }
    } catch (e) {
      print('Error requesting membership OTP: $e');
    }
    return null;
  }

  Future<({String? token, MemberProfile? member, String? error})> verifyMembershipOtp({
    required String phone,
    required String otp,
    String? name,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/membership/verify-otp'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          'name': (name ?? '').trim().isEmpty ? null : name,
          'email': (email ?? '').trim().isEmpty ? null : email,
        }),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200 && json != null && json['success'] == true) {
        final token = (json['token'] ?? '').toString();
        final memberJson = json['member'];
        if (token.isEmpty || memberJson is! Map) {
          return (token: null, member: null, error: 'Invalid server response');
        }
        final member = MemberProfile.fromJson(memberJson.cast<String, dynamic>());
        return (token: token, member: member, error: null);
      }
      final msg = (json?['error'] ?? json?['message'] ?? 'Verification failed').toString();
      return (token: null, member: null, error: '(${response.statusCode}) $msg');
    } catch (e) {
      print('Error verifying membership OTP: $e');
    }
    return (token: null, member: null, error: 'Network error. Please try again.');
  }

  Future<MemberProfile?> getMembershipMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/membership/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final memberJson = json?['member'];
        if (json?['success'] == true && memberJson is Map) {
          return MemberProfile.fromJson(memberJson.cast<String, dynamic>());
        }
      }
    } catch (e) {
      print('Error loading membership profile: $e');
    }
    return null;
  }

  Future<bool> logoutMembership(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/membership/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error logging out membership: $e');
    }
    return false;
  }

  Future<({bool success, String message})> submitVolunteerRequest(VolunteerRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/volunteer'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200 && json != null && json['success'] == true) {
        return (success: true, message: (json['message'] ?? 'Submitted').toString());
      }
      final msg = (json?['error'] ?? json?['message'] ?? 'Failed').toString();
      return (success: false, message: '(${response.statusCode}) $msg');
    } catch (e) {
      print('Error submitting volunteer request: $e');
      return (success: false, message: 'Network error. Please try again.');
    }
  }

  /// Returns new like count on success, null on failure.
  Future<int?> likeEvent(int eventId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/like'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(null),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['count'] != null) {
          return (json['count'] as num).toInt();
        }
        return null;
      }
    } catch (e) {
      print('Error liking event: $e');
    }
    return null;
  }

  Future<int> getEventLikes(int eventId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/events/$eventId/likes/count'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['count'] as num).toInt();
      }
    } catch (e) {
      print('Error fetching event likes: $e');
    }
    return 0;
  }

  Future<List<EventComment>> getEventComments(int eventId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/events/$eventId/comments'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List data = json['data'];
        return data.map((e) => EventComment.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching event comments: $e');
    }
    return [];
  }

  /// Returns new comment count on success, null on failure.
  Future<int?> addEventComment(int eventId, NewCommentRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/$eventId/comments'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['count'] != null) {
          return (json['count'] as num).toInt();
        }
        return null;
      }
    } catch (e) {
      print('Error adding event comment: $e');
    }
    return null;
  }

  /// Returns new like count on success, null on failure.
  Future<int?> likeGallery(int galleryId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gallery/$galleryId/like'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(null),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['count'] != null) {
          return (json['count'] as num).toInt();
        }
        return null;
      }
    } catch (e) {
      print('Error liking gallery item: $e');
    }
    return null;
  }

  Future<int> getGalleryLikes(int galleryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/gallery/$galleryId/likes/count'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['count'] as num).toInt();
      }
    } catch (e) {
      print('Error fetching gallery likes: $e');
    }
    return 0;
  }

  Future<List<GalleryComment>> getGalleryComments(int galleryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/gallery/$galleryId/comments'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List data = json['data'];
        return data.map((e) => GalleryComment.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching gallery comments: $e');
    }
    return [];
  }

  /// Returns new comment count on success, null on failure.
  Future<int?> addGalleryComment(int galleryId, NewCommentRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gallery/$galleryId/comments'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['count'] != null) {
          return (json['count'] as num).toInt();
        }
        return null;
      }
    } catch (e) {
      print('Error adding gallery comment: $e');
    }
    return null;
  }

  Future<SevaBookingResponse> submitSevaBooking(SevaBookingRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/seva/booking'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 200) {
        return SevaBookingResponse.fromJson(jsonDecode(response.body));
      }
      String msg = 'Seva booking failed';
      try {
        msg = (jsonDecode(response.body)['error'] ?? msg).toString();
      } catch (_) {}
      return SevaBookingResponse(success: false, message: msg, referenceId: '');
    } catch (e) {
      print('Error submitting seva booking: $e');
      return SevaBookingResponse(
        success: false,
        message: 'Network error. Please try again.',
        referenceId: '',
      );
    }
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

  Future<HinduPanchang?> getPanchangForDate(DateTime date) async {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final queryDate = '$y-$m-$d';
    try {
      final uri = Uri.parse('$baseUrl/api/panchang').replace(
        queryParameters: {'date': queryDate},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return HinduPanchang.fromJson(json['data'] as Map<String, dynamic>);
      }
      if (response.statusCode == 404) {
        return null;
      }
    } catch (e) {
      print('Error fetching panchang: $e');
    }
    return null;
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

  Future<DonationResponse> submitDonation(DonationRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/donation'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return DonationResponse.fromJson(json);
      }

      return DonationResponse(
        success: false,
        message: 'Donation failed. Please try again.',
        referenceId: '',
      );
    } catch (e) {
      print('Error submitting donation: $e');
      return DonationResponse(
        success: false,
        message: 'Network error. Please try again.',
        referenceId: '',
      );
    }
  }

  Future<PrasadOrderResponse> submitPrasadOrder(PrasadOrderRequest req) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/prasad/order'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return PrasadOrderResponse.fromJson(json);
      }

      String msg = 'Booking failed. Please try again.';
      try {
        final json = jsonDecode(response.body);
        msg = (json['error'] ?? msg).toString();
      } catch (_) {}

      return PrasadOrderResponse(success: false, message: msg, referenceId: '');
    } catch (e) {
      print('Error submitting prasad order: $e');
      return PrasadOrderResponse(
        success: false,
        message: 'Network error. Please try again.',
        referenceId: '',
      );
    }
  }

  Future<List<PrasadOrderView>> getPrasadOrdersByPhone(String phone) async {
    try {
      final uri = Uri.parse('$baseUrl/api/prasad/orders').replace(
        queryParameters: {'phone': phone},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => PrasadOrderView.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching prasad orders: $e');
    }
    return [];
  }

  Future<SimpleActionResponse> cancelPrasadOrder(String referenceId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/prasad/order/$referenceId/cancel'));
      if (response.statusCode == 200) {
        return SimpleActionResponse.fromJson(jsonDecode(response.body));
      }
      String msg = 'Cancel failed';
      try {
        msg = (jsonDecode(response.body)['error'] ?? msg).toString();
      } catch (_) {}
      return SimpleActionResponse(success: false, message: msg);
    } catch (e) {
      print('Error cancelling prasad order: $e');
      return SimpleActionResponse(success: false, message: 'Network error');
    }
  }

  Future<SimpleActionResponse> updatePrasadOrder(
    String referenceId,
    UpdatePrasadOrderRequest req,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/prasad/order/$referenceId'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 200) {
        return SimpleActionResponse.fromJson(jsonDecode(response.body));
      }
      String msg = 'Update failed';
      try {
        msg = (jsonDecode(response.body)['error'] ?? msg).toString();
      } catch (_) {}
      return SimpleActionResponse(success: false, message: msg);
    } catch (e) {
      print('Error updating prasad order: $e');
      return SimpleActionResponse(success: false, message: 'Network error');
    }
  }

  Future<List<SevaBookingView>> getSevaBookingsByPhone(String phone) async {
    try {
      final uri = Uri.parse('$baseUrl/api/seva/bookings').replace(
        queryParameters: {'phone': phone},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'];
        return data.map((e) => SevaBookingView.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error fetching seva bookings: $e');
    }
    return [];
  }

  Future<SimpleActionResponse> cancelSevaBooking(String referenceId) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/seva/booking/$referenceId/cancel'));
      if (response.statusCode == 200) {
        return SimpleActionResponse.fromJson(jsonDecode(response.body));
      }
      String msg = 'Cancel failed';
      try {
        msg = (jsonDecode(response.body)['error'] ?? msg).toString();
      } catch (_) {}
      return SimpleActionResponse(success: false, message: msg);
    } catch (e) {
      print('Error cancelling seva booking: $e');
      return SimpleActionResponse(success: false, message: 'Network error');
    }
  }

  Future<SimpleActionResponse> updateSevaBooking(
    String referenceId,
    UpdateSevaBookingRequest req,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/seva/booking/$referenceId'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(req.toJson()),
      );
      if (response.statusCode == 200) {
        return SimpleActionResponse.fromJson(jsonDecode(response.body));
      }
      String msg = 'Update failed';
      try {
        msg = (jsonDecode(response.body)['error'] ?? msg).toString();
      } catch (_) {}
      return SimpleActionResponse(success: false, message: msg);
    } catch (e) {
      print('Error updating seva booking: $e');
      return SimpleActionResponse(success: false, message: 'Network error');
    }
  }

  // ── Fallback data when API is unavailable ──

  List<AartiSchedule> _defaultAartiSchedule() => [
    AartiSchedule(id: 1, name: 'Mangla Aarti', time: '05:00 AM', description: 'Morning awakening aarti', isSpecial: false),
    AartiSchedule(id: 2, name: 'Shringar Aarti', time: '07:30 AM', description: 'Decoration aarti', isSpecial: false),
    AartiSchedule(id: 3, name: 'Rajbhog Aarti', time: '11:30 AM', description: 'Mid-day offering', isSpecial: false),
    AartiSchedule(id: 4, name: 'Sandhya Aarti', time: '06:30 PM', description: 'Evening aarti', isSpecial: true),
    AartiSchedule(id: 5, name: 'Shayan Aarti', time: '08:30 PM', description: 'Night rest aarti', isSpecial: false),
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
