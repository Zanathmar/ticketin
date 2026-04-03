import '../../../events/data/models/event_model.dart';

class RegistrationModel {
  final int id;
  final int eventId;
  final int userId;
  final String ticketNonce;
  final bool isInside;
  final DateTime? lastCheckin;
  final DateTime? lastCheckout;
  final String? createdAt;
  final EventModel? event;

  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.ticketNonce,
    required this.isInside,
    this.lastCheckin,
    this.lastCheckout,
    this.createdAt,
    this.event,
  });

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'],
      ticketNonce: json['ticket_nonce'],
      isInside: json['is_inside'] == true || json['is_inside'] == 1,
      lastCheckin: json['last_checkin'] != null
          ? DateTime.parse(json['last_checkin'])
          : null,
      lastCheckout: json['last_checkout'] != null
          ? DateTime.parse(json['last_checkout'])
          : null,
      createdAt: json['created_at'],
      event: json['event'] != null ? EventModel.fromJson(json['event']) : null,
    );
  }

  String get statusLabel {
    if (isInside) return 'Inside';
    if (lastCheckout != null) return 'Checked Out';
    return 'Registered';
  }
}

class QrCodeResponse {
  final String qrData;
  final RegistrationModel registration;

  const QrCodeResponse({required this.qrData, required this.registration});

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) {
    return QrCodeResponse(
      qrData: json['qr_data'],
      registration: RegistrationModel.fromJson(json['registration']),
    );
  }
}

class CheckInResponse {
  final String message;
  final RegistrationModel registration;

  const CheckInResponse({required this.message, required this.registration});

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      message: json['message'],
      registration: RegistrationModel.fromJson(json['registration']),
    );
  }
}
