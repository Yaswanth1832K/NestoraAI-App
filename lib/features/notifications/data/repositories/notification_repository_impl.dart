import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental/features/notifications/data/models/notification_model.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl(this._firestore);

  @override
  Stream<List<NotificationEntity>> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
      // Sort in memory to avoid index requirements
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }

  @override
  Future<void> addNotification(String userId, NotificationEntity notification) async {
    final model = NotificationModel(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      timestamp: notification.timestamp,
      type: notification.type,
      isRead: notification.isRead,
      data: notification.data,
    );
    
    // Use set with merge to create or update
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(model.id)
        .set(model.toFirestore());
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }
}
