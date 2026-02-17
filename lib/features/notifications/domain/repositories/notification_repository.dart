import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Stream<List<NotificationEntity>> getNotifications(String userId);
  Future<void> addNotification(String userId, NotificationEntity notification);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> deleteNotification(String userId, String notificationId);
}
