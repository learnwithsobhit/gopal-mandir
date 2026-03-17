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

  GalleryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      category: json['category'],
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
  final int? quantity;
  final String? fulfillment; // pickup | delivery
  final String? address;
  final String? notes;

  UpdatePrasadOrderRequest({
    this.quantity,
    this.fulfillment,
    this.address,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'fulfillment': fulfillment,
        'address': address,
        'notes': notes,
      };
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
