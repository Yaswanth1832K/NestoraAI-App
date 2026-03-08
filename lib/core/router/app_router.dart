import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:animations/animations.dart';

import 'package:house_rental/features/trips/presentation/pages/trips_page.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_inbox_page.dart';
import 'package:house_rental/features/roommate/presentation/pages/roommate_feed_screen.dart';
import 'package:house_rental/features/roommate/presentation/pages/roommate_profile_screen.dart';
import 'package:house_rental/features/profile/presentation/pages/profile_page.dart';
import 'package:house_rental/features/profile/presentation/pages/login_security_page.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/listings/presentation/pages/listing_details_page.dart';
import 'package:house_rental/features/listings/presentation/pages/post_property_page.dart';
import 'package:house_rental/features/bookings/presentation/pages/payment_screen.dart';
import 'package:house_rental/features/bookings/presentation/pages/payment_success_page.dart';
import 'package:house_rental/features/bookings/presentation/pages/reward_wheel_screen.dart';
import 'package:house_rental/features/bookings/presentation/pages/booking_details_page.dart';
import 'package:house_rental/core/router/splash_screen.dart';
import 'package:house_rental/features/visit_requests/presentation/pages/owner_requests_page.dart';
import 'package:house_rental/features/visit_requests/presentation/pages/my_visits_page.dart';
import 'package:house_rental/features/owner/presentation/owner_dashboard_page.dart';
import 'package:house_rental/features/home/presentation/pages/service_booking_page.dart'; // [NEW]
import 'package:house_rental/features/owner/presentation/property_requests_screen.dart';
import 'package:house_rental/features/search/presentation/pages/search_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/edit_profile_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/rental_preferences_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/payment_methods_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/help_center_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/safety_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/report_issue_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/language_region_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/privacy_policy_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/message_settings_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/notifications_page.dart';
import 'package:house_rental/features/rent_payments/presentation/pages/rent_payments_page.dart';
import 'package:house_rental/features/rent_payments/presentation/pages/rental_agreements_page.dart';
import 'package:house_rental/features/rent_payments/presentation/pages/home_loans_page.dart';
import 'package:house_rental/features/favorites/presentation/pages/favorites_page.dart';
import 'package:house_rental/features/ai_services/presentation/recommendations_view.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/rewards_page.dart';
import 'package:house_rental/features/profile/presentation/pages/subpages/coupons_page.dart';
import 'package:house_rental/core/navigation/main_navigation.dart';

// import 'package:house_rental/features/chat/presentation/pages/inbox_page.dart'; // Removed old import to avoid conflict
import 'package:flutter/material.dart';
import 'package:house_rental/features/home/presentation/pages/home_page.dart';
import 'package:house_rental/features/chat/presentation/pages/chat_page.dart';
import 'package:house_rental/features/owner/presentation/owner_properties_screen.dart';
import 'package:house_rental/features/auth/presentation/pages/auth_page.dart';
import 'package:house_rental/features/map/presentation/pages/map_page.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/router/router_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_rental/main.dart';
import 'package:house_rental/features/smart_tools/presentation/pages/emergency_help_page.dart';
import 'package:house_rental/features/smart_tools/presentation/pages/lease_generator_page.dart';
import 'package:house_rental/features/smart_tools/presentation/pages/ar_measurement_page.dart';
import 'package:house_rental/features/smart_tools/presentation/pages/virtual_furniture_page.dart';
import 'package:house_rental/features/smart_tools/presentation/pages/move_in_cost_page.dart';

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
        return null; // Stay where we are until loading is done
      }

      final isSplash = location == AppRouter.splash;
      final isAuth = location == AppRouter.login;

      // 1. If not logged in, allow Home and Profile, else force Login
      if (user == null) {
        final isHome = location == AppRouter.home;
        final isProfile = location == AppRouter.profile;
        if (!isAuth && !isSplash && !isHome && !isProfile) {
          debugPrint('🏠 Unauthorized access to $location: Force to LOGIN');
          return AppRouter.login;
        }
        return null; // Stay on Login, Splash, Home, or Profile
      }

      // 2. If logged in and on Auth/Splash page, go Home
      if (isAuth || isSplash) {
        debugPrint('🏠 Already logged in: Redirect home from $location');
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
        builder: (context, state) {
          final existingListing = state.extra as ListingEntity?;
          return PostPropertyPage(existingListing: existingListing);
        },
      ),
      GoRoute(
        path: AppRouter.listingDetails,
        pageBuilder: (context, state) {
          final listing = state.extra as ListingEntity?;
          // If listing is null (e.g. on web refresh), redirect home
          if (listing == null) {
            return const NoTransitionPage(child: MainNavigation());
          }
          return _fadeTransition(
            state: state,
            child: ListingDetailsPage(listing: listing),
          );
        },
      ),
      GoRoute(
        path: '/book/:id',
        builder: (context, state) {
          final listing = state.extra as ListingEntity?;
          if (listing == null) return const MainNavigation();
          return BookingDetailsPage(listing: listing);
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          if (extras == null) return const MainNavigation();
          
          final listing = extras['listing'] as ListingEntity?;
          final totalPayable = extras['totalPayable'] as double?;
          final moveInDate = extras['moveInDate'] as DateTime?;

          if (listing == null || totalPayable == null || moveInDate == null) {
            return const MainNavigation();
          }

          return PaymentScreen(
            listing: listing,
            totalPayable: totalPayable,
            moveInDate: moveInDate,
            appliedCouponId: extras['appliedCouponId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/payment-success',
        builder: (context, state) {
          final listing = state.extra as ListingEntity?;
          if (listing == null) return const MainNavigation();
          return PaymentSuccessPage(listing: listing);
        },
      ),
      GoRoute(
        path: '/reward-wheel',
        builder: (context, state) => const RewardWheelScreen(),
      ),
      GoRoute(
        path: '/chat-detail',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          if (extras == null) return const MainNavigation();
          
          final chatRoomId = extras['chatRoomId'] as String?;
          final title = extras['title'] as String?;
          
          if (chatRoomId == null || title == null) return const MainNavigation();
          
          return ChatPage(chatRoomId: chatRoomId, title: title);
        },
      ),
      GoRoute(
        path: AppRouter.chat,
        builder: (context, state) => const ChatInboxPage(),
      ),
      GoRoute(
        path: AppRouter.trips,
        builder: (context, state) => const TripsPage(),
      ),
      GoRoute(
        path: AppRouter.search,
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const SearchPage(),
        ),
      ),
      GoRoute(
        path: AppRouter.ownerRequests,
        builder: (context, state) => const OwnerRequestsPage(),
      ),
      GoRoute(
        path: AppRouter.inbox,
        builder: (context, state) => const ChatInboxPage(),
      ),
      GoRoute(
        path: AppRouter.profile,
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: AppRouter.map,
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: AppRouter.myVisits,
        builder: (context, state) => const MyVisitsPage(),
      ),
      GoRoute(
        path: AppRouter.loginSecurity,
        builder: (context, state) => const LoginSecurityPage(),
      ),
      GoRoute(
        path: AppRouter.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRouter.notifications,
        pageBuilder: (context, state) => _fadeTransition(
          state: state,
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: AppRouter.paymentMethods,
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        path: AppRouter.rentalPreferences,
        builder: (context, state) => const RentalPreferencesPage(),
      ),
      GoRoute(
        path: AppRouter.messageSettings,
        builder: (context, state) => const MessageSettingsPage(),
      ),
      GoRoute(
        path: AppRouter.helpCenter,
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: AppRouter.safety,
        builder: (context, state) => const SafetyPage(),
      ),
      GoRoute(
        path: AppRouter.reportIssue,
        builder: (context, state) => const ReportIssuePage(),
      ),
      GoRoute(
        path: AppRouter.languageRegion,
        builder: (context, state) => const LanguageRegionPage(),
      ),
      GoRoute(
        path: AppRouter.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRouter.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: AppRouter.ownerDashboard,
        builder: (context, state) => const OwnerDashboardPage(),
      ),
      GoRoute(
        path: AppRouter.serviceBooking,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ServiceBookingPage(
            serviceName: extra?['serviceName'] ?? 'Service',
            serviceIcon: extra?['serviceIcon'] ?? Icons.handyman,
          );
        },
      ),
      GoRoute(
        path: AppRouter.myProperties,
        builder: (context, state) => const OwnerPropertiesScreen(),
      ),
      GoRoute(
        path: AppRouter.propertyRequests,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          if (extras == null) return const MainNavigation();
          return PropertyRequestsScreen(
            listingId: extras['listingId'],
            title: extras['title'],
          );
        },
      ),
      GoRoute(
        path: AppRouter.rentPayments,
        builder: (context, state) => const RentPaymentsPage(),
      ),
      GoRoute(
        path: AppRouter.rentalAgreements,
        builder: (context, state) => const RentalAgreementsPage(),
      ),
      GoRoute(
        path: AppRouter.homeLoans,
        builder: (context, state) => const HomeLoansPage(),
      ),
      GoRoute(
        path: AppRouter.aiRecommendations,
        builder: (context, state) => const RecommendationsView(),
      ),
      GoRoute(
        path: AppRouter.roommateFeed,
        builder: (context, state) => const RoommateFeedScreen(),
      ),
      GoRoute(
        path: AppRouter.roommateProfile,
        builder: (context, state) => const RoommateProfileScreen(),
      ),
       GoRoute(
        path: AppRouter.rewards,
        builder: (context, state) => const CouponsPage(),
      ),
      GoRoute(
        path: AppRouter.emergencyHelp,
        builder: (context, state) => const EmergencyHelpPage(),
      ),
      GoRoute(
        path: AppRouter.leaseGenerator,
        builder: (context, state) => const LeaseGeneratorPage(),
      ),
      GoRoute(
        path: AppRouter.arMeasurement,
        builder: (context, state) => const ArMeasurementPage(),
      ),
      GoRoute(
        path: AppRouter.virtualFurniture,
        builder: (context, state) => const VirtualFurniturePage(),
      ),
      GoRoute(
        path: AppRouter.moveInCalculator,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return MoveInCostCalculatorPage(
            initialRent: extras?['rent'],
            initialDeposit: extras?['deposit'],
          );
        },
      ),
    ],
  );
});

Page _fadeTransition({required GoRouterState state, required Widget child}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.scaled,
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      );
    },
  );
}

final class AppRouter {
  AppRouter._();

  static const String trips = '/trips';
  static const String inbox = '/inbox';
  static const String profile = '/profile';
  
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/'; 
  static const String search = '/search';
  static const String postProperty = '/post-property';
  static const String listingDetails = '/listing';
  static const String favorites = '/favorites';
  static const String chat = '/chat';
  static const String map = '/map';
  static const String ownerRequests = '/owner-requests';
  static const String myVisits = '/my-visits';
  static const String loginSecurity = '/login-security';
  static const String editProfile = '/edit-profile';
  static const String notifications = '/notifications';
  static const String paymentMethods = '/payment-methods';
  static const String rentalPreferences = '/rental-preferences';
  static const String messageSettings = '/message-settings';
  static const String helpCenter = '/help-center';
  static const String safety = '/safety';
  static const String reportIssue = '/report-issue';
  static const String languageRegion = '/language-region';
  static const String privacyPolicy = '/privacy-policy';
  static const String ownerDashboard = '/owner-dashboard';
  static const String serviceBooking = '/service-booking';
  static const String myProperties = '/my-properties';
  static const String propertyRequests = '/property-requests';
  static const String rentPayments = '/rent-payments';
  static const String rentalAgreements = '/rental-agreements';
  static const String homeLoans = '/home-loans';
  static const String aiRecommendations = '/ai-recommendations';
  static const String roommateFeed = '/roommate-feed';
  static const String roommateProfile = '/roommate-profile';
  static const String rewards = '/rewards';
  static const String emergencyHelp = '/emergency-help';
  static const String leaseGenerator = '/lease-generator';
  static const String arMeasurement = '/ar-measurement';
  static const String virtualFurniture = '/virtual-furniture';
  static const String moveInCalculator = '/move-in-calculator';
}
