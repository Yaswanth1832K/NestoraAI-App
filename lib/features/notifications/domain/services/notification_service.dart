import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initialize() async {
    try {
      // 1. Request permissions with proper handling
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Notifications permission denied by user.');
        return; // Don't proceed if denied
      }

      // 2. Initialize local notifications
      final androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosSettings = const DarwinInitializationSettings();
      final initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          print('Notification tapped: ${details.payload}');
          // Navigation logic handled via onMessageOpenedApp in main.dart
        },
      );

      // 3. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message received: ${message.notification?.title}');
        _showLocalNotification(message);
        
        if (message.notification != null) {
          _saveToHistory(
            title: message.notification!.title ?? 'Notification',
            body: message.notification!.body ?? '',
            data: message.data,
          );
        }
      });

      // 4. Listen to auth state changes to sync token
      _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
        final user = next.value;
        if (user != null) {
          _fcm.getToken().then((token) {
            if (token != null) _syncToken(token);
          });
        }
      });

      // 5. Get initial FCM Token
      final token = await _fcm.getToken();
      if (token != null) {
        print('FCM Token generated: $token');
        _syncToken(token);
      }

      // 6. Listen to token refresh
      _fcm.onTokenRefresh.listen(_syncToken);
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  Future<void> _syncToken(String token) async {
    final userId = _getCurrentUserId();
    if (userId != null) {
      try {
        await _ref.read(updateFcmTokenUseCaseProvider)(token);
      } catch (e) {
        print('Failed to sync FCM token: $e');
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'nestora_main_channel',
      'Nestora Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    final iosDetails = DarwinNotificationDetails();
    final platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: message.data.toString(),
    );
  }

  Future<void> _saveToHistory({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final user = _getCurrentUserId();
    if (user == null) return;

    final notification = NotificationEntity(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: data?['type'] ?? 'system',
      isRead: false,
      data: data,
    );
    
    await _ref.read(addNotificationUseCaseProvider)(user, notification);
  }

  String? _getCurrentUserId() {
    final authState = _ref.read(authStateProvider);
    return authState.value?.uid;
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    final currentUserId = _getCurrentUserId();
    
    // 1. Save to history if it's for the current user
    if (userId == currentUserId) {
      await _saveToHistory(title: title, body: body, data: {...?data, 'type': type});
      
      // 2. Show local notification (simulating a received push)
      final androidDetails = AndroidNotificationDetails(
        'nestora_main_channel',
        'Nestora Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      final platformDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
      
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        platformDetails,
        payload: data?.toString(),
      );
    } else {
      // In a real app, this would be an API call to the backend to send a push to another user.
      // For this project, we've already set up the backend (main.py) to trigger FCM.
      print('📢 Notification meant for another user ($userId): $title');
    }
  }

  // --- Convenience Methods ---

  Future<void> notifyVisitRequestCreated({
    required String ownerId,
    required String propertyTitle,
    required String tenantName,
  }) async {
    await _saveToHistory(
      title: 'New Visit Request',
      body: '$tenantName wants to visit "$propertyTitle".',
      data: {'type': 'booking', 'click_action': 'OWNER_REQUESTS'},
    );
  }

  Future<void> notifyVisitRequestStatusChanged({
    required String tenantId,
    required String propertyTitle,
    required String status,
  }) async {
    final statusText = status == 'approved' ? 'approved' : 'rejected';
    await _saveToHistory(
      title: 'Visit Request Update',
      body: 'Your request for "$propertyTitle" has been $statusText.',
      data: {'type': status == 'approved' ? 'success' : 'alert', 'click_action': 'MY_VISITS'},
    );
  }

  Future<void> notifyPaymentSuccess({
    required String tenantId,
    required String propertyTitle,
    required double amount,
  }) async {
    await _saveToHistory(
      title: 'Payment Successful',
      body: 'Received ₹$amount for "$propertyTitle".',
      data: {'type': 'success', 'click_action': 'RENT_PAYMENTS'},
    );
  }

  Future<void> notifyPaymentFailure({
    required String tenantId,
    required String propertyTitle,
  }) async {
    await _saveToHistory(
      title: 'Payment Failed',
      body: 'Payment for "$propertyTitle" could not be processed.',
      data: {'type': 'error', 'click_action': 'RENT_PAYMENTS'},
    );
  }

  Future<void> notifyPriceChange({
    required String propertyTitle,
    required double oldPrice,
    required double newPrice,
  }) async {
    final direction = newPrice < oldPrice ? 'dropped' : 'increased';
    await _saveToHistory(
      title: 'Price Update Alert',
      body: 'Price for "$propertyTitle" has $direction from ₹${oldPrice.toStringAsFixed(0)} to ₹${newPrice.toStringAsFixed(0)}.',
      data: {'type': 'alert', 'click_action': 'SAVED_PROPERTIES'},
    );
  }

  Future<void> notifyNewPropertyMatch({
    required String propertyTitle,
    required String city,
  }) async {
    await _saveToHistory(
      title: 'New Property Match',
      body: 'A new property "$propertyTitle" match your preferences in $city.',
      data: {'type': 'alert', 'click_action': 'SEARCH'},
    );
  }

  Future<void> notifyEmergencyRequestConfirmed({
    required String serviceName,
    required String arrivalTime,
  }) async {
    await _saveToHistory(
      title: 'Emergency Service Confirmed',
      body: 'Your request for $serviceName is confirmed. Arrival in $arrivalTime.',
      data: {'type': 'alert', 'click_action': 'HOME'},
    );
  }

  Future<void> notifyLeaseAgreementGenerated({
    required String tenantName,
  }) async {
    await _saveToHistory(
      title: 'Lease Agreement Generated',
      body: 'Your rental agreement for $tenantName is ready to download.',
      data: {'type': 'success', 'click_action': 'RENT_PAYMENTS'},
    );
  }

  Future<void> notifyVisitScheduled({
    required String propertyTitle,
    required String date,
  }) async {
    await _saveToHistory(
      title: 'Visit Scheduled',
      body: 'Your visit for "$propertyTitle" is scheduled for $date.',
      data: {'type': 'success', 'click_action': 'MY_VISITS'},
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
