import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:house_rental/app.dart';
import 'package:house_rental/firebase_options.dart';
import 'package:house_rental/features/rent_payments/data/services/stripe_service.dart';
import 'package:house_rental/features/notifications/domain/services/notification_service.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Stripe SDK
  StripeService.init();

  // Offline resilience: cache listings when network fails (mobile: default true)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize FCM & Local Notifications via Provider
  final container = ProviderContainer();
  await container.read(notificationServiceProvider).initialize();

  // Handle background/terminated notifications when app is opened via tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data.containsKey('chatId')) {
      final chatId = message.data['chatId'];
      rootNavigatorKey.currentContext?.push('/chat/$chatId');
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HouseRentalApp(),
    ),
  );
}
