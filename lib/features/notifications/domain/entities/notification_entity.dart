import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type; // 'system', 'booking', 'alert'
  final bool isRead;
  final Map<String, dynamic>? data; // Extra data like bookingId

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.isRead,
    this.data,
  });

  @override
  List<Object?> get props => [id, title, body, timestamp, type, isRead, data];
}
