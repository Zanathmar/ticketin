class VenueModel {
  final int id;
  final String name;
  final String address;
  final String city;
  final String? state;
  final String country;
  final String? postalCode;
  final String? coordinates;

  const VenueModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.state,
    required this.country,
    this.postalCode,
    this.coordinates,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      coordinates: json['coordinates'],
    );
  }

  String get fullAddress {
    final parts = [address, city, if (state != null) state!, country];
    return parts.join(', ');
  }
}

class OrganizerModel {
  final int id;
  final String name;
  final String email;

  const OrganizerModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory OrganizerModel.fromJson(Map<String, dynamic> json) {
    return OrganizerModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class EventModel {
  final int id;
  final int organizerId;
  final int venueId;
  final String title;
  final String? description;
  final String status;
  final int capacity;
  final int currentAttendees;
  final DateTime startTime;
  final DateTime endTime;
  final String? imageUrl;
  final VenueModel? venue;
  final OrganizerModel? organizer;
  final String? createdAt;

  const EventModel({
    required this.id,
    required this.organizerId,
    required this.venueId,
    required this.title,
    this.description,
    required this.status,
    required this.capacity,
    required this.currentAttendees,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    this.venue,
    this.organizer,
    this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      organizerId: json['organizer_id'],
      venueId: json['venue_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'active',
      capacity: json['capacity'],
      currentAttendees: json['current_attendees'] ?? 0,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      imageUrl: json['image_url'],
      venue: json['venue'] != null ? VenueModel.fromJson(json['venue']) : null,
      organizer: json['organizer'] != null
          ? OrganizerModel.fromJson(json['organizer'])
          : null,
      createdAt: json['created_at'],
    );
  }

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isFull => currentAttendees >= capacity;

  double get capacityPercent =>
      capacity > 0 ? (currentAttendees / capacity).clamp(0.0, 1.0) : 0.0;

  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing =>
      startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());
}
