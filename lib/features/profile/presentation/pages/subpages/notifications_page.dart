import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications"), centerTitle: false),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification.isRead;

              // Determine icon and color based on type
              IconData icon;
              Color color;
              
              switch (notification.type) {
                case 'booking':
                  icon = Icons.calendar_today;
                  color = Colors.blue;
                  break;
                case 'success':
                  icon = Icons.check_circle;
                  color = Colors.green;
                  break;
                case 'alert':
                  icon = Icons.info;
                  color = Colors.orange;
                  break;
                case 'system':
                default:
                  icon = Icons.notifications;
                  color = AppColors.primary;
              }

              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    ref.read(notificationRepositoryProvider).deleteNotification(user.uid, notification.id);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isRead 
                      ? Border.all(color: Colors.transparent)
                      : Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isRead) {
                        final user = ref.read(authStateProvider).value;
                        if (user != null) {
                          ref.read(markNotificationReadUseCaseProvider)(
                             user.uid,
                             notification.id
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          final isPermissionError = err.toString().contains('permission-denied');
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPermissionError ? Icons.lock_outline : Icons.error_outline, 
                    size: 64, 
                    color: Colors.red.shade300
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPermissionError 
                      ? 'Access restricted. Please ensure you are logged in correctly.' 
                      : 'Something went wrong while loading notifications.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(userNotificationsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }
}
