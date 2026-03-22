class AartiSchedule {
  final int id;
  final String name;
  final String time;
  final String description;
  final bool isSpecial;

  AartiSchedule({
    required this.id,
    required this.name,
    required this.time,
    required this.description,
    required this.isSpecial,
  });

  factory AartiSchedule.fromJson(Map<String, dynamic> json) {
    return AartiSchedule(
      id: json['id'],
      name: json['name'],
      time: json['time'],
      description: json['description'],
      isSpecial: json['is_special'],
    );
  }
}

class Event {
  final int id;
  final String title;
  final String date;
  final String description;
  final String? imageUrl;
  final bool isFeatured;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    this.imageUrl,
    required this.isFeatured,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      date: json['date'],
      description: json['description'],
      imageUrl: json['image_url'],
      isFeatured: json['is_featured'],
    );
  }
}

class GalleryItem {
  final int id;
  final String title;
  final String imageUrl;
  final String category;
  final String videoUrl;
  final String mediaType;

  GalleryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    this.videoUrl = '',
    this.mediaType = 'image',
  });

  bool get isVideo => mediaType.toLowerCase() == 'video' && videoUrl.trim().isNotEmpty;

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'] ?? '',
      category: json['category'],
      videoUrl: (json['video_url'] ?? '').toString(),
      mediaType: (json['media_type'] ?? 'image').toString(),
    );
  }
}

class PrasadItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool available;

  PrasadItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.available,
  });

  factory PrasadItem.fromJson(Map<String, dynamic> json) {
    return PrasadItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      available: json['available'],
    );
  }
}

class SevaItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool available;

  SevaItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.available,
  });

  factory SevaItem.fromJson(Map<String, dynamic> json) {
    return SevaItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      available: json['available'],
    );
  }
}

class Announcement {
  final int id;
  final String title;
  final String message;
  final String date;
  final bool isUrgent;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.isUrgent,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      date: json['date'],
      isUrgent: json['is_urgent'],
    );
  }
}

class DailyQuote {
  final String shlok;
  final String translation;
  final String source;

  DailyQuote({
    required this.shlok,
    required this.translation,
    required this.source,
  });

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      shlok: json['shlok'],
      translation: json['translation'],
      source: json['source'],
    );
  }
}

class HinduPanchang {
  final int id;
  final String forDate;
  final String content;
  final String createdAt;

  HinduPanchang({
    required this.id,
    required this.forDate,
    required this.content,
    required this.createdAt,
  });

  factory HinduPanchang.fromJson(Map<String, dynamic> json) {
    return HinduPanchang(
      id: json['id'],
      forDate: (json['for_date'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class TempleInfo {
  final String name;
  final String address;
  final String city;
  final String phone;
  final String email;
  final String website;
  final String openingTime;
  final String closingTime;
  final double latitude;
  final double longitude;
  final String? mapsUrl;

  TempleInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.email,
    required this.website,
    required this.openingTime,
    required this.closingTime,
    required this.latitude,
    required this.longitude,
    this.mapsUrl,
  });

  factory TempleInfo.fromJson(Map<String, dynamic> json) {
    return TempleInfo(
      name: json['name'],
      address: json['address'],
      city: json['city'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      openingTime: json['opening_time'],
      closingTime: json['closing_time'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      mapsUrl: json['maps_url']?.toString(),
    );
  }
}

class MemberProfile {
  final String id;
  final String phone;
  final String name;
  final String email;
  final String status;
  final String? createdAt;

  MemberProfile({
    required this.id,
    required this.phone,
    required this.name,
    required this.email,
    required this.status,
    this.createdAt,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    return MemberProfile(
      id: (json['id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class VolunteerRequest {
  final String name;
  final String phone;
  final String? email;
  final String? area;
  final String? availability;
  final String? message;

  VolunteerRequest({
    required this.name,
    required this.phone,
    this.email,
    this.area,
    this.availability,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
        'area': area,
        'availability': availability,
        'message': message,
      };
}

class VolunteerView {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String area;
  final String availability;
  final String message;
  final String status;
  final String createdAt;

  VolunteerView({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.area,
    required this.availability,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory VolunteerView.fromJson(Map<String, dynamic> json) {
    return VolunteerView(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: json['email']?.toString(),
      area: (json['area'] ?? '').toString(),
      availability: (json['availability'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class FeedbackRequestModel {
  final String? name;
  final String? email;
  final String? phone;
  final int rating;
  final String message;
  final String source;

  FeedbackRequestModel({
    this.name,
    this.email,
    this.phone,
    required this.rating,
    required this.message,
    this.source = 'app',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'rating': rating,
        'message': message,
        'source': source,
      };
}

class FeedbackSubmissionResult {
  final bool success;
  final String message;
  final String referenceId;

  FeedbackSubmissionResult({
    required this.success,
    required this.message,
    required this.referenceId,
  });

  factory FeedbackSubmissionResult.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmissionResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
    );
  }
}

class AdminFeedbackView {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final int rating;
  final String message;
  final String source;
  final String status;
  final String priority;
  final String? ownerAdminId;
  final String? ownerName;
  final String referenceId;
  final String createdAt;
  final String updatedAt;
  final int responseCount;

  AdminFeedbackView({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.rating,
    required this.message,
    required this.source,
    required this.status,
    required this.priority,
    this.ownerAdminId,
    this.ownerName,
    required this.referenceId,
    required this.createdAt,
    required this.updatedAt,
    required this.responseCount,
  });

  factory AdminFeedbackView.fromJson(Map<String, dynamic> json) {
    return AdminFeedbackView(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      message: (json['message'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      priority: (json['priority'] ?? '').toString(),
      ownerAdminId: json['owner_admin_id']?.toString(),
      ownerName: json['owner_name']?.toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      responseCount: (json['response_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class FeedbackThreadItem {
  final int id;
  final int feedbackId;
  final String authorType;
  final String? authorAdminId;
  final String? authorName;
  final String message;
  final bool isPublic;
  final String createdAt;

  FeedbackThreadItem({
    required this.id,
    required this.feedbackId,
    required this.authorType,
    this.authorAdminId,
    this.authorName,
    required this.message,
    required this.isPublic,
    required this.createdAt,
  });

  factory FeedbackThreadItem.fromJson(Map<String, dynamic> json) {
    return FeedbackThreadItem(
      id: json['id'] as int,
      feedbackId: json['feedback_id'] as int,
      authorType: (json['author_type'] ?? '').toString(),
      authorAdminId: json['author_admin_id']?.toString(),
      authorName: json['author_name']?.toString(),
      message: (json['message'] ?? '').toString(),
      isPublic: json['is_public'] == true,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class AdminFeedbackAnalytics {
  final int total;
  final int newCount;
  final int inProgressCount;
  final int resolvedCount;
  final double avgRating;
  final int rating1;
  final int rating2;
  final int rating3;
  final int rating4;
  final int rating5;
  final List<FeedbackTrendPoint> trend;

  AdminFeedbackAnalytics({
    required this.total,
    required this.newCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.avgRating,
    required this.rating1,
    required this.rating2,
    required this.rating3,
    required this.rating4,
    required this.rating5,
    required this.trend,
  });

  factory AdminFeedbackAnalytics.fromJson(Map<String, dynamic> json) {
    final trendData = (json['trend'] as List<dynamic>? ?? [])
        .map((e) => FeedbackTrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return AdminFeedbackAnalytics(
      total: (json['total'] as num?)?.toInt() ?? 0,
      newCount: (json['new_count'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['in_progress_count'] as num?)?.toInt() ?? 0,
      resolvedCount: (json['resolved_count'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      rating1: (json['rating_1'] as num?)?.toInt() ?? 0,
      rating2: (json['rating_2'] as num?)?.toInt() ?? 0,
      rating3: (json['rating_3'] as num?)?.toInt() ?? 0,
      rating4: (json['rating_4'] as num?)?.toInt() ?? 0,
      rating5: (json['rating_5'] as num?)?.toInt() ?? 0,
      trend: trendData,
    );
  }
}

class FeedbackTrendPoint {
  final String day;
  final int count;

  FeedbackTrendPoint({required this.day, required this.count});

  factory FeedbackTrendPoint.fromJson(Map<String, dynamic> json) {
    return FeedbackTrendPoint(
      day: (json['day'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DonationRequest {
  final String name;
  final double amount;
  final String purpose;
  final String phone;
  final String email;

  DonationRequest({
    required this.name,
    required this.amount,
    required this.purpose,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'purpose': purpose,
        'phone': phone,
        'email': email,
      };
}

class DonationResponse {
  final bool success;
  final String message;
  final String referenceId;

  DonationResponse({
    required this.success,
    required this.message,
    required this.referenceId,
  });

  factory DonationResponse.fromJson(Map<String, dynamic> json) {
    return DonationResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
    );
  }
}

/// Response from `POST /api/donation/checkout` or event donate checkout (Razorpay order).
class DonationCheckoutResponse {
  final bool success;
  final String keyId;
  final String orderId;
  final int amount;
  final String currency;
  final String referenceId;
  final String? error;

  DonationCheckoutResponse({
    required this.success,
    this.keyId = '',
    this.orderId = '',
    this.amount = 0,
    this.currency = 'INR',
    this.referenceId = '',
    this.error,
  });

  factory DonationCheckoutResponse.fromJson(Map<String, dynamic> json) {
    return DonationCheckoutResponse(
      success: json['success'] == true,
      keyId: (json['key_id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'INR').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      error: json['error']?.toString(),
    );
  }
}

class PrasadOrderRequest {
  final int prasadItemId;
  final int quantity;
  final String fulfillment; // pickup | delivery
  final String name;
  final String phone;
  final String? address;
  final String? notes;

  PrasadOrderRequest({
    required this.prasadItemId,
    required this.quantity,
    required this.fulfillment,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'prasad_item_id': prasadItemId,
        'quantity': quantity,
        'fulfillment': fulfillment,
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
      };
}

class PrasadOrderResponse {
  final bool success;
  final String message;
  final String referenceId;

  PrasadOrderResponse({
    required this.success,
    required this.message,
    required this.referenceId,
  });

  factory PrasadOrderResponse.fromJson(Map<String, dynamic> json) {
    return PrasadOrderResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
    );
  }
}

class SevaBookingRequest {
  final int sevaItemId;
  final String name;
  final String phone;
  final String? preferredDate;
  final String? notes;

  SevaBookingRequest({
    required this.sevaItemId,
    required this.name,
    required this.phone,
    this.preferredDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'seva_item_id': sevaItemId,
        'name': name,
        'phone': phone,
        'preferred_date': preferredDate,
        'notes': notes,
      };
}

class SevaBookingResponse {
  final bool success;
  final String message;
  final String referenceId;

  SevaBookingResponse({
    required this.success,
    required this.message,
    required this.referenceId,
  });

  factory SevaBookingResponse.fromJson(Map<String, dynamic> json) {
    return SevaBookingResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
    );
  }
}

class PrasadOrderView {
  final int id;
  final String referenceId;
  final String status;
  final String createdAt;
  final String fulfillment;
  final int quantity;
  final double totalAmount;
  final String name;
  final String phone;
  final String? address;
  final String? notes;
  final int prasadItemId;
  final String prasadName;

  PrasadOrderView({
    required this.id,
    required this.referenceId,
    required this.status,
    required this.createdAt,
    required this.fulfillment,
    required this.quantity,
    required this.totalAmount,
    required this.name,
    required this.phone,
    this.address,
    this.notes,
    required this.prasadItemId,
    required this.prasadName,
  });

  factory PrasadOrderView.fromJson(Map<String, dynamic> json) {
    return PrasadOrderView(
      id: json['id'],
      referenceId: (json['reference_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      fulfillment: (json['fulfillment'] ?? '').toString(),
      quantity: json['quantity'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      address: json['address']?.toString(),
      notes: json['notes']?.toString(),
      prasadItemId: json['prasad_item_id'],
      prasadName: (json['prasad_name'] ?? '').toString(),
    );
  }
}

class UpdatePrasadOrderRequest {
  /// Must match the order phone on the server.
  final String phone;
  final int? quantity;
  final String? fulfillment; // pickup | delivery
  final String? address;
  final String? notes;

  UpdatePrasadOrderRequest({
    required this.phone,
    this.quantity,
    this.fulfillment,
    this.address,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'quantity': quantity,
        'fulfillment': fulfillment,
        'address': address,
        'notes': notes,
      };
}

// ── Admin / Live darshan API ──

class AdminProfile {
  final String id;
  final String phone;
  final String name;
  final String status;

  AdminProfile({
    required this.id,
    required this.phone,
    required this.name,
    required this.status,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: (json['id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class AdminPresignResult {
  final String uploadUrl;
  final String publicUrl;
  final String key;

  AdminPresignResult({
    required this.uploadUrl,
    required this.publicUrl,
    required this.key,
  });

  factory AdminPresignResult.fromJson(Map<String, dynamic> json) {
    return AdminPresignResult(
      uploadUrl: (json['upload_url'] ?? '').toString(),
      publicUrl: (json['public_url'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
    );
  }
}

class LiveDarshanConfig {
  final int id;
  final String title;
  final String streamUrl;
  final bool isLive;
  final String description;

  LiveDarshanConfig({
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.isLive,
    required this.description,
  });

  factory LiveDarshanConfig.fromJson(Map<String, dynamic> json) {
    return LiveDarshanConfig(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      streamUrl: (json['stream_url'] ?? '').toString(),
      isLive: json['is_live'] == true,
      description: (json['description'] ?? '').toString(),
    );
  }
}

class SevaBookingView {
  final int id;
  final String referenceId;
  final String status;
  final String createdAt;
  final String name;
  final String phone;
  final String? preferredDate;
  final String? notes;
  final int sevaItemId;
  final String sevaName;
  final String sevaCategory;
  final double sevaPrice;

  SevaBookingView({
    required this.id,
    required this.referenceId,
    required this.status,
    required this.createdAt,
    required this.name,
    required this.phone,
    this.preferredDate,
    this.notes,
    required this.sevaItemId,
    required this.sevaName,
    required this.sevaCategory,
    required this.sevaPrice,
  });

  factory SevaBookingView.fromJson(Map<String, dynamic> json) {
    return SevaBookingView(
      id: json['id'],
      referenceId: (json['reference_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      preferredDate: json['preferred_date']?.toString(),
      notes: json['notes']?.toString(),
      sevaItemId: json['seva_item_id'],
      sevaName: (json['seva_name'] ?? '').toString(),
      sevaCategory: (json['seva_category'] ?? '').toString(),
      sevaPrice: (json['seva_price'] as num).toDouble(),
    );
  }
}

class UpdateSevaBookingRequest {
  final String? preferredDate;
  final String? notes;

  UpdateSevaBookingRequest({
    this.preferredDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'preferred_date': preferredDate,
        'notes': notes,
      };
}

class SimpleActionResponse {
  final bool success;
  final String message;

  SimpleActionResponse({
    required this.success,
    required this.message,
  });

  factory SimpleActionResponse.fromJson(Map<String, dynamic> json) {
    return SimpleActionResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}

class EventParticipationRequest {
  final String name;
  final String phone;
  final String? notes;

  EventParticipationRequest({
    required this.name,
    required this.phone,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'notes': notes,
      };
}

class EventParticipationResponse {
  final bool success;
  final String message;

  EventParticipationResponse({
    required this.success,
    required this.message,
  });

  factory EventParticipationResponse.fromJson(Map<String, dynamic> json) {
    return EventParticipationResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}

class EventComment {
  final int id;
  final int eventId;
  final String name;
  final String comment;
  final String createdAt;

  EventComment({
    required this.id,
    required this.eventId,
    required this.name,
    required this.comment,
    required this.createdAt,
  });

  factory EventComment.fromJson(Map<String, dynamic> json) {
    return EventComment(
      id: json['id'],
      eventId: json['event_id'],
      name: (json['name'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class EventParticipationView {
  final int id;
  final int eventId;
  final String eventTitle;
  final String name;
  final String phone;
  final String? notes;
  final String createdAt;

  EventParticipationView({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.name,
    required this.phone,
    this.notes,
    required this.createdAt,
  });

  factory EventParticipationView.fromJson(Map<String, dynamic> json) {
    return EventParticipationView(
      id: json['id'],
      eventId: json['event_id'],
      eventTitle: (json['event_title'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      notes: json['notes']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class EventDonationRequest {
  final int eventId;
  final String name;
  final double amount;
  final String? phone;
  final String? email;
  final String? message;

  EventDonationRequest({
    required this.eventId,
    required this.name,
    required this.amount,
    this.phone,
    this.email,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (message != null) 'message': message,
      };
}

class EventDonationView {
  final int id;
  final int eventId;
  final String eventTitle;
  final String name;
  final double amount;
  final String? phone;
  final String? email;
  final String? message;
  final String referenceId;
  final String paymentStatus;
  final String? gateway;
  final String? gatewayOrderId;
  final String? gatewayPaymentId;
  final String createdAt;

  EventDonationView({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.name,
    required this.amount,
    this.phone,
    this.email,
    this.message,
    required this.referenceId,
    this.paymentStatus = 'paid',
    this.gateway,
    this.gatewayOrderId,
    this.gatewayPaymentId,
    required this.createdAt,
  });

  factory EventDonationView.fromJson(Map<String, dynamic> json) {
    return EventDonationView(
      id: json['id'],
      eventId: json['event_id'],
      eventTitle: (json['event_title'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      message: json['message']?.toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? 'paid').toString(),
      gateway: json['gateway']?.toString(),
      gatewayOrderId: json['gateway_order_id']?.toString(),
      gatewayPaymentId: json['gateway_payment_id']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class GalleryComment {
  final int id;
  final int galleryId;
  final String name;
  final String comment;
  final String createdAt;

  GalleryComment({
    required this.id,
    required this.galleryId,
    required this.name,
    required this.comment,
    required this.createdAt,
  });

  factory GalleryComment.fromJson(Map<String, dynamic> json) {
    return GalleryComment(
      id: json['id'],
      galleryId: json['gallery_id'],
      name: (json['name'] ?? '').toString(),
      comment: (json['comment'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class NewCommentRequest {
  final String name;
  final String comment;

  NewCommentRequest({
    required this.name,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'comment': comment,
      };
}
