import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/features/listings/presentation/pages/post_property_page.dart';
import 'package:house_rental/core/router/splash_screen.dart';
import 'package:house_rental/features/visit_requests/presentation/pages/owner_requests_page.dart';
import 'package:house_rental/features/visit_requests/presentation/pages/my_visits_page.dart';
import 'package:house_rental/core/navigation/main_navigation.dart';
import 'package:house_rental/features/chat/presentation/pages/inbox_page.dart';
import 'package:house_rental/features/map/presentation/pages/map_page.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:house_rental/features/auth/presentation/pages/auth_page.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/router/router_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_rental/main.dart';

/// Application routing configuration using Riverpod.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRouter.splash,
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      
      final location = state.matchedLocation;
      final user = authState.value;
      if (user != null) {
        debugPrint('👤 Current User UID: ${user.uid}');
      }
      debugPrint('🔀 Router Redirect: location=$location, isLoading=${authState.isLoading}, hasUser=${user != null}');

      if (authState.isLoading) {
        return null; // Stay on splash while loading
      }

      final isSplash = location == AppRouter.splash;
      final isAuth = location == AppRouter.login;

      // 1. If on Splash, decide where to go based on auth
      if (isSplash) {
        if (user == null) {
          debugPrint('🏠 Redirecting to LOGIN from Splash');
          return AppRouter.login;
        }
        debugPrint('🏠 Redirecting to HOME from Splash');
        return AppRouter.home;
      }

      // 2. If NOT logged in and NOT on Auth page, force Login
      if (user == null && !isAuth) {
        debugPrint('🏠 Unauthorized access: Force to LOGIN');
        return AppRouter.login;
      }

      // 3. If logged in and trying to access Auth page, go Home
      if (user != null && isAuth) {
        debugPrint('🏠 Already logged in: Redirect home');
        return AppRouter.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRouter.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRouter.login,
        builder: (context, state) => const AuthPage(),
      ),
      // THE NEW CORE APP SHELL
      GoRoute(
        path: AppRouter.home,
        builder: (context, state) => const MainNavigation(),
      ),
      GoRoute(
        path: AppRouter.postProperty,
        builder: (context, state) => const PostPropertyPage(),
      ),
      GoRoute(
        path: AppRouter.listingDetails,
        builder: (context, state) {
          final listing = state.extra as ListingEntity;
          return ListingDetailsPage(listing: listing);
        },
      ),
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          final chatRoomId = extras['chatRoomId'] as String;
          final title = extras['title'] as String;
          return ChatPage(chatRoomId: chatRoomId, title: title);
        },
      ),
      GoRoute(
        path: AppRouter.chat,
        builder: (context, state) => const InboxPage(),
      ),
      GoRoute(
        path: AppRouter.map,
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: AppRouter.ownerRequests,
        builder: (context, state) => const OwnerRequestsPage(),
      ),
      GoRoute(
        path: AppRouter.myVisits,
        builder: (context, state) => const MyVisitsPage(),
      ),
    ],
  );
});

final class AppRouter {
  AppRouter._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/'; 
  static const String search = '/search';
  static const String postProperty = '/post-property';
  static const String listingDetails = '/listing';
  static const String favorites = '/favorites';
  static const String chat = '/chat';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String ownerRequests = '/owner-requests';
  static const String myVisits = '/my-visits';
}
