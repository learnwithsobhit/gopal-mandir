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
    );
  }
}
