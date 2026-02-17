import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.timestamp,
    required super.type,
    required super.isRead,
    super.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'system',
      isRead: data['isRead'] ?? false,
      data: data['data'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'isRead': isRead,
      'data': data,
    };
  }
}
