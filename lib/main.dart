import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:house_rental/app.dart';
import 'package:house_rental/firebase_options.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline resilience: cache listings when network fails (mobile: default true)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize FCM
  final messaging = FirebaseMessaging.instance;
  
  // Request permissions (important for iOS/Web)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Handle background/terminated notifications when app is opened via tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data.containsKey('chatId')) {
      final chatId = message.data['chatId'];
      // Navigate to chat (requires rootNavigatorKey and proper route)
      rootNavigatorKey.currentContext?.push('/chat/$chatId');
    }
  });

  runApp(
    const ProviderScope(
      child: HouseRentalApp(),
    ),
  );
}
