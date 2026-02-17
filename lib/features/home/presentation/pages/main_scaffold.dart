import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    
    int getSelectedIndex() {
      if (location.startsWith(AppRouter.favorites)) return 1;
      if (location.startsWith(AppRouter.trips)) return 2;
      if (location.startsWith(AppRouter.inbox)) return 3;
      if (location.startsWith(AppRouter.profile)) return 4;
      // Default to Explore (Home)
      if (location == AppRouter.home || location.startsWith(AppRouter.search)) return 0;
      return 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: getSelectedIndex(),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRouter.home); // Explore
              break;
            case 1:
              context.go(AppRouter.favorites); // Wishlists
              break;
            case 2:
              context.go(AppRouter.trips); // Trips
              break;
            case 3:
              context.go(AppRouter.inbox); // Inbox
              break;
            case 4:
              context.go(AppRouter.profile); // Profile
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Wishlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_takeoff), // Or a logo icon if available
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
