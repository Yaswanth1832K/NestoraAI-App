import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/theme/theme_provider.dart';
import 'package:house_rental/features/auth/domain/usecases/update_user_role_usecase.dart';
import 'package:house_rental/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final notificationsProvider = StateProvider<bool>((ref) => true);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;
    final isOwnerAsync = ref.watch(isOwnerProvider);
    final isOwner = isOwnerAsync.value ?? false;
    
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.profileTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, size: 28, color: textColor),
                    onPressed: () => context.push(AppRouter.notifications),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Profile Header Card
              GlassContainer.standard(
                isDark: isDark,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: user?.photoURL != null 
                          ? NetworkImage(user!.photoURL!) 
                          : null,
                      child: user?.photoURL == null 
                          ? const Icon(Icons.person, size: 36, color: Colors.grey) 
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? "Guest",
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? "Sign in to view profile",
                            style: TextStyle(
                              color: subTextColor, 
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: textColor),
                      onPressed: () => context.push(AppRouter.editProfile),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // ROLE-SPECIFIC SECTION
              if (isOwner)
                ProfileSection(
                  title: "Hosting",
                  isDark: isDark,
                  children: [
                    ProfileMenuItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                      onTap: () => context.push(AppRouter.ownerDashboard),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.home_work_outlined,
                      title: AppLocalizations.of(context)!.myListings,
                      onTap: () => context.push(AppRouter.myProperties),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.event_note_outlined,
                      title: AppLocalizations.of(context)!.visitRequests,
                      onTap: () => context.push(AppRouter.ownerRequests),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.payments_outlined,
                      title: AppLocalizations.of(context)!.paymentsAndPayouts,
                      onTap: () => context.push(AppRouter.paymentMethods),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: "Property Management",
                      onTap: () => context.push(AppRouter.myProperties),
                      isDark: isDark,
                    ),
                  ],
                )
              else
                ProfileSection(
                  title: "Renting", // Fixed label for Renter
                  isDark: isDark,
                  children: [
                    ProfileMenuItem(
                      icon: Icons.auto_awesome,
                      title: 'AI Recommendations',
                      onTap: () => context.push(AppRouter.aiRecommendations),
                      isDark: isDark,
                      iconColor: Colors.purple,
                    ),
                    ProfileMenuItem(
                      icon: Icons.favorite_border,
                      title: AppLocalizations.of(context)!.savedProperties,
                      onTap: () => context.push(AppRouter.favorites),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.tune,
                      title: AppLocalizations.of(context)!.rentalPreferences,
                      onTap: () => context.push(AppRouter.rentalPreferences),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.calendar_today_outlined,
                      title: "Booking / Visit History",
                      onTap: () => context.push(AppRouter.myVisits),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Rent Payments",
                      onTap: () => context.push(AppRouter.rentPayments),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.home_filled,
                      title: "Become a Host",
                      onTap: () => _handleBecomeHost(context, ref, user?.uid),
                      isDark: isDark,
                      iconColor: const Color(0xFFFF385C),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // COMMON SETTINGS SECTION
              ProfileSection(
                title: AppLocalizations.of(context)!.accountSettings, 
                isDark: isDark,
                children: [
                  ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: AppLocalizations.of(context)!.personalInformation,
                    onTap: () => context.push(AppRouter.editProfile),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.security_outlined,
                    title: AppLocalizations.of(context)!.loginAndSecurity,
                    onTap: () => context.push(AppRouter.loginSecurity),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.notifications_none_outlined,
                    title: AppLocalizations.of(context)!.notifications,
                    onTap: () => context.push(AppRouter.notifications),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.message_outlined,
                    title: AppLocalizations.of(context)!.messageSettings,
                    onTap: () => context.push(AppRouter.messageSettings),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    title: AppLocalizations.of(context)!.darkMode,
                    onTap: () {
                      ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                    },
                    isDark: isDark,
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).setTheme(value ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: const Color(0xFFFF385C),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SUPPORT & LEGAL SECTION
              ProfileSection(
                title: AppLocalizations.of(context)!.support,
                isDark: isDark,
                children: [
                  ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: AppLocalizations.of(context)!.helpCenter,
                    onTap: () => context.push(AppRouter.helpCenter),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.language,
                    title: AppLocalizations.of(context)!.languageAndRegion,
                    onTap: () => context.push(AppRouter.languageRegion),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: AppLocalizations.of(context)!.privacyPolicy,
                    onTap: () => context.push(AppRouter.privacyPolicy),
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Logout Button
              if (user != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF385C),
                      side: const BorderSide(color: Color(0xFFFF385C)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleLogout(context, ref),
                    child: Text(
                      AppLocalizations.of(context)!.logOut,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final signOutResult = await ref.read(signOutUseCaseProvider).call();
    signOutResult.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${failure.message}")),
      ),
      (_) {
        // Redirection is handled by GoRouter refreshListenable
      },
    );
  }

  Future<void> _handleBecomeHost(BuildContext context, WidgetRef ref, String? uid) async {
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Become a Host"),
        content: const Text("Are you sure you want to become a host? This will enable you to list your properties."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref.read(updateUserRoleUseCaseProvider).call(uid, 'owner');
      result.fold(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update role: ${failure.message}")),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You are now a host!")),
          );
        },
      );
    }
  }
}