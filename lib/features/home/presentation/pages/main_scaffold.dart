import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/core/navigation/nestora_bottom_nav.dart';

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
      extendBody: true,
      body: child,
      bottomNavigationBar: NestoraBottomNav(
        currentIndex: getSelectedIndex(),
        isDark: Theme.of(context).brightness == Brightness.dark,
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
      ),
    );
  }
}
