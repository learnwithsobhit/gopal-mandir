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

  // ──────────────────────────────────────────────
  // Public live darshan config
  // ──────────────────────────────────────────────

  Future<LiveDarshanConfig?> getLiveDarshanConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/live-darshan'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['success'] == true && json['data'] != null) {
          return LiveDarshanConfig.fromJson(json['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('Error fetching live darshan: $e');
    }
    return null;
  }

  // ──────────────────────────────────────────────
  // Admin (CRM) — Bearer token
  // ──────────────────────────────────────────────

  Map<String, String> _adminHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<
      ({
        String? otp,
        String? error,
        int? retryAfterSec,
        int? attemptsRemaining,
        int? attemptsUsed,
        int? attemptsLimit
      })> requestAdminOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/request-otp'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      int? asInt(dynamic v) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse(v?.toString() ?? '');
      }
      if (response.statusCode == 200) {
        if (json != null && json['success'] == true) {
          return (
            otp: (json['otp'] ?? '').toString(),
            error: null,
            retryAfterSec: null,
            attemptsRemaining: asInt(json['attempts_remaining']),
            attemptsUsed: asInt(json['attempts_used']),
            attemptsLimit: asInt(json['attempts_limit']),
          );
        }
      }
      return (
        otp: null,
        error: (json?['error'] ?? 'Unable to send OTP').toString(),
        retryAfterSec: asInt(json?['retry_after_sec']),
        attemptsRemaining: asInt(json?['attempts_remaining']),
        attemptsUsed: asInt(json?['attempts_used']),
        attemptsLimit: asInt(json?['attempts_limit']),
      );
    } catch (e) {
      print('admin request otp: $e');
      return (
        otp: null,
        error: 'Network error. Please try again.',
        retryAfterSec: null,
        attemptsRemaining: null,
        attemptsUsed: null,
        attemptsLimit: null,
      );
    }
  }

  Future<({String? token, AdminProfile? admin, String? error})> verifyAdminOtp({
    required String phone,
    required String otp,
    String? name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/verify-otp'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        }),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200 && json != null && json['success'] == true) {
        final token = (json['token'] ?? '').toString();
        final adminMap = json['admin'] as Map<String, dynamic>?;
        return (
          token: token.isEmpty ? null : token,
          admin: adminMap == null ? null : AdminProfile.fromJson(adminMap),
          error: null,
        );
      }
      final err = json?['error']?.toString() ?? 'Verification failed';
      return (token: null, admin: null, error: err);
    } catch (e) {
      print('admin verify otp: $e');
      return (token: null, admin: null, error: 'Network error');
    }
  }

  Future<AdminProfile?> adminMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/me'),
        headers: _adminHeaders(token),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final adminMap = json?['admin'] as Map<String, dynamic>?;
        if (adminMap != null) return AdminProfile.fromJson(adminMap);
      }
    } catch (e) {
      print('admin me: $e');
    }
    return null;
  }

  Future<({AdminProfile? admin, int? statusCode, String? error})> adminMeResult(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/me'),
        headers: _adminHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200) {
        final adminMap = json?['admin'] as Map<String, dynamic>?;
        if (adminMap != null) {
          return (
            admin: AdminProfile.fromJson(adminMap),
            statusCode: response.statusCode,
            error: null,
          );
        }
        return (
          admin: null,
          statusCode: response.statusCode,
          error: 'Invalid admin response',
        );
      }
      return (
        admin: null,
        statusCode: response.statusCode,
        error: (json?['error'] ?? 'Admin session check failed').toString(),
      );
    } catch (e) {
      print('admin me result: $e');
      return (admin: null, statusCode: null, error: 'Network error');
    }
  }

  Future<void> adminLogout(String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/admin/logout'),
        headers: _adminHeaders(token),
      );
    } catch (e) {
      print('admin logout: $e');
    }
  }

  Future<AdminPresignResult?> adminPresign(
    String token, {
    required String contentType,
    required String fileExt,
    String objectKeyPrefix = 'gallery',
    int? sizeBytes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/media/presign'),
        headers: _adminHeaders(token),
        body: jsonEncode({
          'content_type': contentType,
          'file_ext': fileExt,
          'object_key_prefix': objectKeyPrefix,
          if (sizeBytes != null) 'size_bytes': sizeBytes,
        }),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        if (json != null && json['success'] == true) {
          return AdminPresignResult.fromJson(json);
        }
      }
    } catch (e) {
      print('admin presign: $e');
    }
    return null;
  }

  Future<List<GalleryItem>> adminListGallery(
    String token, {
    int page = 1,
    int perPage = 50,
    String? category,
  }) async {
    try {
      final q = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        if (category != null && category.isNotEmpty) 'category': category,
      };
      final uri = Uri.parse('$baseUrl/api/admin/gallery').replace(queryParameters: q);
      final response = await http.get(uri, headers: _adminHeaders(token));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as List<dynamic>?;
        if (data != null) {
          return data.map((e) => GalleryItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('admin gallery list: $e');
    }
    return [];
  }

  Future<GalleryItem?> adminCreateGallery(String token, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/gallery'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return GalleryItem.fromJson(data);
      }
    } catch (e) {
      print('admin gallery create: $e');
    }
    return null;
  }

  Future<GalleryItem?> adminPatchGallery(String token, int id, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/gallery/$id'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return GalleryItem.fromJson(data);
      }
    } catch (e) {
      print('admin gallery patch: $e');
    }
    return null;
  }

  Future<bool> adminDeleteGallery(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/gallery/$id'),
        headers: _adminHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('admin gallery delete: $e');
    }
    return false;
  }

  Future<LiveDarshanConfig?> adminGetLiveDarshan(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/live-darshan'),
        headers: _adminHeaders(token),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return LiveDarshanConfig.fromJson(data);
      }
    } catch (e) {
      print('admin live darshan get: $e');
    }
    return null;
  }

  Future<LiveDarshanConfig?> adminPatchLiveDarshan(String token, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/live-darshan'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return LiveDarshanConfig.fromJson(data);
      }
    } catch (e) {
      print('admin live darshan patch: $e');
    }
    return null;
  }

  Future<List<PrasadOrderView>> adminListPrasadOrders(
    String token, {
    String? status,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final q = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        if (status != null && status.isNotEmpty) 'status': status,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      };
      final uri = Uri.parse('$baseUrl/api/admin/prasad/orders').replace(queryParameters: q);
      final response = await http.get(uri, headers: _adminHeaders(token));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as List<dynamic>?;
        if (data != null) {
          return data.map((e) => PrasadOrderView.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('admin prasad orders: $e');
    }
    return [];
  }

  Future<SimpleActionResponse> adminPatchPrasadOrderStatus(
    String token,
    String referenceId,
    String status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/prasad/order/${Uri.encodeComponent(referenceId)}'),
        headers: _adminHeaders(token),
        body: jsonEncode({'status': status}),
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
      print('admin prasad patch: $e');
      return SimpleActionResponse(success: false, message: 'Network error');
    }
  }

  // ──────────────────────────────────────────────
  // Admin Panchang CRUD
  // ──────────────────────────────────────────────

  Future<List<HinduPanchang>> adminListPanchang(
    String token, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final q = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      final uri = Uri.parse('$baseUrl/api/admin/panchang').replace(queryParameters: q);
      final response = await http.get(uri, headers: _adminHeaders(token));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as List<dynamic>?;
        if (data != null) {
          return data.map((e) => HinduPanchang.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('admin panchang list: $e');
    }
    return [];
  }

  Future<HinduPanchang?> adminCreatePanchang(
    String token, {
    required String forDate,
    required String content,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/panchang'),
        headers: _adminHeaders(token),
        body: jsonEncode({'for_date': forDate, 'content': content}),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return HinduPanchang.fromJson(data);
      }
    } catch (e) {
      print('admin panchang create: $e');
    }
    return null;
  }

  Future<HinduPanchang?> adminPatchPanchang(
    String token,
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/panchang/$id'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return HinduPanchang.fromJson(data);
      }
    } catch (e) {
      print('admin panchang patch: $e');
    }
    return null;
  }

  Future<bool> adminDeletePanchang(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/panchang/$id'),
        headers: _adminHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('admin panchang delete: $e');
    }
    return false;
  }

  // ──────────────────────────────────────────────
  // Admin Events CRUD
  // ──────────────────────────────────────────────

  Future<List<Event>> adminListEvents(
    String token, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final q = <String, String>{'page': '$page', 'per_page': '$perPage'};
      final uri = Uri.parse('$baseUrl/api/admin/events').replace(queryParameters: q);
      final response = await http.get(uri, headers: _adminHeaders(token));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as List<dynamic>?;
        if (data != null) {
          return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('admin events list: $e');
    }
    return [];
  }

  Future<Event?> adminCreateEvent(String token, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/events'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return Event.fromJson(data);
      }
    } catch (e) {
      print('admin event create: $e');
    }
    return null;
  }

  Future<Event?> adminPatchEvent(String token, int id, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/events/$id'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return Event.fromJson(data);
      }
    } catch (e) {
      print('admin event patch: $e');
    }
    return null;
  }

  Future<bool> adminDeleteEvent(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/events/$id'),
        headers: _adminHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('admin event delete: $e');
    }
    return false;
  }

  // ──────────────────────────────────────────────
  // Admin Event Participations
  // ──────────────────────────────────────────────

  Future<List<EventParticipationView>> adminListEventParticipations(
    String token, {
    int? eventId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final q = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        if (eventId != null) 'event_id': '$eventId',
      };
      final uri = Uri.parse('$baseUrl/api/admin/events/participations').replace(queryParameters: q);
      final response = await http.get(uri, headers: _adminHeaders(token));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as List<dynamic>?;
        if (data != null) {
          return data.map((e) => EventParticipationView.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('admin event participations list: $e');
    }
    return [];
  }

  // ──────────────────────────────────────────────
  // Admin Seva Items CRUD
  // ──────────────────────────────────────────────

  Future<List<SevaItem>> adminListSevaItems(
    String token, {
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final q = <String, String>{'page': '$page', 'per_page': '$perPage'};
      final uri = Uri.parse('$baseUrl/api/admin/seva/items').replace(queryParameters: q);
      final response = await http.get(uri, headers: _adminHeaders(token));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as List<dynamic>?;
        if (data != null) {
          return data.map((e) => SevaItem.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('admin seva items list: $e');
    }
    return [];
  }

  Future<SevaItem?> adminCreateSevaItem(String token, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/seva/items'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return SevaItem.fromJson(data);
      }
    } catch (e) {
      print('admin seva item create: $e');
    }
    return null;
  }

  Future<SevaItem?> adminPatchSevaItem(String token, int id, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/seva/items/$id'),
        headers: _adminHeaders(token),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as Map<String, dynamic>?;
        if (data != null) return SevaItem.fromJson(data);
      }
    } catch (e) {
      print('admin seva item patch: $e');
    }
    return null;
  }

  Future<bool> adminDeleteSevaItem(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/seva/items/$id'),
        headers: _adminHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('admin seva item delete: $e');
    }
    return false;
  }

  // ──────────────────────────────────────────────
  // Admin Seva Bookings
  // ──────────────────────────────────────────────

  Future<List<SevaBookingView>> adminListSevaBookings(
    String token, {
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final q = <String, String>{
        'limit': '$limit',
        'offset': '$offset',
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final uri = Uri.parse('$baseUrl/api/admin/seva/bookings').replace(queryParameters: q);
      final response = await http.get(uri, headers: _adminHeaders(token));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final data = json?['data'] as List<dynamic>?;
        if (data != null) {
          return data.map((e) => SevaBookingView.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      print('admin seva bookings list: $e');
    }
    return [];
  }

  Future<SimpleActionResponse> adminPatchSevaBookingStatus(
    String token,
    String referenceId,
    String status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/seva/booking/${Uri.encodeComponent(referenceId)}'),
        headers: _adminHeaders(token),
        body: jsonEncode({'status': status}),
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
      print('admin seva booking patch: $e');
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
