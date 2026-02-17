import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final Ref _ref;

  NotificationService(this._ref);

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationEntity(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      data: data,
    );

    try {
      await _ref.read(addNotificationUseCaseProvider)(userId, notification);
    } catch (e) {
      // Log error but don't crash the app
      print('Failed to send notification: $e');
    }
  }

  Future<void> notifyVisitRequestCreated({
    required String ownerId,
    required String propertyTitle,
    required String tenantName,
  }) async {
    await sendNotification(
      userId: ownerId,
      title: 'New Visit Request',
      body: '$tenantName wants to visit "$propertyTitle".',
      type: 'booking',
      data: {'click_action': 'OWNER_REQUESTS'},
    );
  }

  Future<void> notifyVisitRequestStatusChanged({
    required String tenantId,
    required String propertyTitle,
    required String status,
  }) async {
    final statusText = status == 'approved' ? 'approved' : 'rejected';
    await sendNotification(
      userId: tenantId,
      title: 'Visit Request Update',
      body: 'Your request for "$propertyTitle" has been $statusText.',
      type: status == 'approved' ? 'success' : 'alert',
      data: {'click_action': 'MY_VISITS'},
    );
  }

  Future<void> notifyPaymentSuccess({
    required String tenantId,
    required String propertyTitle,
    required double amount,
  }) async {
    await sendNotification(
      userId: tenantId,
      title: 'Payment Successful',
      body: 'Received \$$amount for "$propertyTitle".',
      type: 'success',
      data: {'click_action': 'RENT_PAYMENTS'},
    );
  }

  Future<void> notifyPaymentFailure({
    required String tenantId,
    required String propertyTitle,
  }) async {
    await sendNotification(
      userId: tenantId,
      title: 'Payment Failed',
      body: 'Payment for "$propertyTitle" could not be processed.',
      type: 'error',
      data: {'click_action': 'RENT_PAYMENTS'},
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
