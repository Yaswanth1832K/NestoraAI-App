import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.read(firestoreProvider));
});

final userNotificationsProvider = StreamProvider<List<NotificationEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(notificationRepositoryProvider).getNotifications(user.uid);
});

final addNotificationUseCaseProvider = Provider((ref) {
  return (String userId, NotificationEntity notification) {
    return ref.read(notificationRepositoryProvider).addNotification(userId, notification);
  };
});

final markNotificationReadUseCaseProvider = Provider((ref) {
  return (String userId, String notificationId) {
    return ref.read(notificationRepositoryProvider).markAsRead(userId, notificationId);
  };
});
