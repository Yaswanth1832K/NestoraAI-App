import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.read(firestoreProvider));
});

final _rawUserNotificationsProvider = StreamProvider<List<NotificationEntity>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(notificationRepositoryProvider).getNotifications(user.uid);
});

final _locallyReadNotificationsProvider = StateProvider<Set<String>>((ref) => {});

final userNotificationsProvider = Provider<AsyncValue<List<NotificationEntity>>>((ref) {
  final rawAsync = ref.watch(_rawUserNotificationsProvider);
  final locallyRead = ref.watch(_locallyReadNotificationsProvider);

  return rawAsync.whenData((notifications) {
    return notifications.map((n) {
      if (locallyRead.contains(n.id)) {
        return NotificationEntity(
          id: n.id,
          title: n.title,
          body: n.body,
          timestamp: n.timestamp,
          type: n.type,
          isRead: true,
          data: n.data,
        );
      }
      return n;
    }).toList();
  });
});

final addNotificationUseCaseProvider = Provider((ref) {
  return (String userId, NotificationEntity notification) {
    return ref.read(notificationRepositoryProvider).addNotification(userId, notification);
  };
});

final markNotificationReadUseCaseProvider = Provider((ref) {
  return (String userId, String notificationId) async {
    ref.read(_locallyReadNotificationsProvider.notifier).update((set) => {...set, notificationId});
    return ref.read(notificationRepositoryProvider).markAsRead(userId, notificationId);
  };
});

