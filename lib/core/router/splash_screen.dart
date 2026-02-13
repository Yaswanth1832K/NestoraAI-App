import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/constants/app_constants.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/router/app_router.dart';

/// Minimal splash screen showing app title and Firebase connection status.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(firebaseConnectionProvider);
    final authState = ref.watch(authStateProvider);

    // Reactive transition: When authState is ready, move to the next screen
    // This serves as a fallback/reinforcement for the GoRouter redirect
    if (authState.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final user = authState.value;
          if (user == null) {
            debugPrint('🚀 SplashScreen: Redirecting to LOGIN');
            context.go(AppRouter.login);
          } else {
            debugPrint('🚀 SplashScreen: Redirecting to HOME');
            context.go(AppRouter.home);
          }
        }
      });
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32),
              connectionAsync.when(
                data: (connected) => _StatusChip(
                  label: connected ? 'Firebase: Connected' : 'Firebase: Disconnected',
                  isSuccess: connected,
                ),
                loading: () => const _StatusChip(label: 'Connecting...', isSuccess: false),
                error: (e, st) => const _StatusChip(
                  label: 'Firebase: Error',
                  isSuccess: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isSuccess});

  final String label;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSuccess
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSuccess
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onErrorContainer,
            ),
      ),
    );
  }
}
