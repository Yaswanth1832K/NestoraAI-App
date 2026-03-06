import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/core/theme/theme_provider.dart';

import 'package:house_rental/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/l10n/generated/app_localizations.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/providers/firebase_provider.dart';
import 'package:house_rental/features/listings/data/models/listing_model.dart';
import 'package:house_rental/features/listings/domain/utils/demo_listings_data.dart';
import 'package:house_rental/features/listings/presentation/providers/paginated_listings_notifier.dart';

final notificationsProvider = StateProvider<bool>((ref) => true);

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSnapshot = ref.watch(currentUserProvider);
    final user = userSnapshot.value;
    final isOwnerAsync = ref.watch(isOwnerProvider);
    final isOwner = isOwnerAsync.value ?? false;
    
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (context.canPop()) ...[
                        GlassContainer.standard(
                          context: context,
                          borderRadius: 40,
                          padding: EdgeInsets.zero,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_rounded, size: 24, color: textColor),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Text(
                        AppLocalizations.of(context)!.profileTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: textColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  GlassContainer.standard(
                    context: context,
                    borderRadius: 40,
                    padding: EdgeInsets.zero,
                    child: IconButton(
                      icon: Icon(Icons.notifications_none_rounded, size: 24, color: textColor),
                      onPressed: () => context.push(AppRouter.notifications),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Profile Header Card
              userSnapshot.when(
                data: (userData) => GlassContainer.standard(
                  context: context,
                  padding: const EdgeInsets.all(20),
                  borderRadius: 24,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          backgroundImage: userData?.photoUrl != null
                              ? NetworkImage(userData!.photoUrl!)
                              : null,
                          child: userData?.photoUrl == null
                              ? Icon(Icons.person_rounded, size: 35, color: subTextColor)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  userData?.displayName ?? "Guest",
                                  style: TextStyle(
                                    fontSize: 20, 
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (userData != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 10, color: Colors.white),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userData?.email ?? "Sign in for full access",
                              style: TextStyle(
                                color: subTextColor, 
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right_rounded, color: subTextColor),
                        onPressed: () => context.push(AppRouter.editProfile),
                      ),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
              
              const SizedBox(height: 16),

              // ROLE-SPECIFIC SECTION
              if (isOwner)
                ProfileSection(
                  title: "Hosting",
                  isDark: isDark,
                  children: [
                    ProfileMenuItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      onTap: () => context.push(AppRouter.ownerDashboard),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.home_work_rounded,
                      title: AppLocalizations.of(context)!.myListings,
                      onTap: () => context.push(AppRouter.myProperties),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.event_note_rounded,
                      title: AppLocalizations.of(context)!.visitRequests,
                      onTap: () => context.push(AppRouter.ownerRequests),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.payments_rounded,
                      title: AppLocalizations.of(context)!.paymentsAndPayouts,
                      onTap: () => context.push(AppRouter.paymentMethods),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      title: "Property Management",
                      onTap: () => context.push(AppRouter.myProperties),
                      isDark: isDark,
                      showDivider: false,
                    ),
                  ],
                )
              else
                ProfileSection(
                  title: "Renting",
                  isDark: isDark,
                  children: [
                    ProfileMenuItem(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Recommendations',
                      onTap: () => context.push(AppRouter.aiRecommendations),
                      isDark: isDark,
                      iconColor: AppColors.primary,
                    ),
                    ProfileMenuItem(
                      icon: Icons.favorite_rounded,
                      title: AppLocalizations.of(context)!.savedProperties,
                      onTap: () => context.push(AppRouter.favorites),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.tune_rounded,
                      title: AppLocalizations.of(context)!.rentalPreferences,
                      onTap: () => context.push(AppRouter.rentalPreferences),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.calendar_today_rounded,
                      title: "Booking History",
                      onTap: () => context.push(AppRouter.myVisits),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.card_giftcard_outlined,
                      title: "My Rewards & Coupons",
                      onTap: () => context.push(AppRouter.rewards),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: "Rent Payments",
                      onTap: () => context.push(AppRouter.rentPayments),
                      isDark: isDark,
                    ),
                    ProfileMenuItem(
                      icon: Icons.home_rounded,
                      title: "Become a Host",
                      onTap: () => _handleBecomeHost(context, ref, user?.uid),
                      isDark: isDark,
                      iconColor: AppColors.primary,
                      showDivider: false,
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // COMMON SETTINGS SECTION
              ProfileSection(
                title: AppLocalizations.of(context)!.accountSettings, 
                isDark: isDark,
                children: [
                  ProfileMenuItem(
                    icon: Icons.person_rounded,
                    title: AppLocalizations.of(context)!.personalInformation,
                    onTap: () => context.push(AppRouter.editProfile),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.security_rounded,
                    title: AppLocalizations.of(context)!.loginAndSecurity,
                    onTap: () => context.push(AppRouter.loginSecurity),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.notifications_rounded,
                    title: AppLocalizations.of(context)!.notifications,
                    onTap: () => context.push(AppRouter.notifications),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.message_rounded,
                    title: AppLocalizations.of(context)!.messageSettings,
                    onTap: () => context.push(AppRouter.messageSettings),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    title: AppLocalizations.of(context)!.darkMode,
                    onTap: () {
                      ref.read(themeProvider.notifier).setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                    },
                    isDark: isDark,
                    showDivider: false,
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isDark,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).setTheme(value ? ThemeMode.dark : ThemeMode.light);
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // DEVELOPER TOOLS (Restoring properties)
              ProfileSection(
                title: "Developer Tools",
                isDark: isDark,
                children: [
                  ProfileMenuItem(
                    icon: Icons.auto_fix_high_rounded,
                    title: "Seed Demo Listings",
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Seed Database"),
                          content: const Text("This will generate 20+ houses across different locations and save them to Firestore. This will restore the properties you generated earlier. Continue?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding properties... please wait.')));
                        try {
                          final firestore = ref.read(firestoreProvider);
                          // Use the helper we know exists
                          final cities = ["Mumbai", "Bangalore", "Hyderabad", "Chennai", "Delhi", "Goa", "Kochi", "Coimbatore", "Vijayawada", "Dindigul", "Madurai", "Trichy"];
                          int count = 0;
                          final userData = ref.read(currentUserProvider).value;
                          for (var city in cities) {
                            final demos = DemoListingsData.generateDemoListings(city, 2, ownerId: userData?.uid);
                            for (var d in demos) {
                              await firestore.collection('listings').doc(d.id).set(ListingModel.fromEntity(d).toJson());
                              count++;
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully seeded $count properties!')));
                          // Refresh listings
                          ref.invalidate(paginatedListingsProvider);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seeding failed: $e')));
                        }
                      }
                    },
                    isDark: isDark,
                    iconColor: Colors.purpleAccent,
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // SUPPORT & LEGAL SECTION
              ProfileSection(
                title: AppLocalizations.of(context)!.support,
                isDark: isDark,
                children: [
                  ProfileMenuItem(
                    icon: Icons.help_rounded,
                    title: AppLocalizations.of(context)!.helpCenter,
                    onTap: () => context.push(AppRouter.helpCenter),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.language_rounded,
                    title: AppLocalizations.of(context)!.languageAndRegion,
                    onTap: () => context.push(AppRouter.languageRegion),
                    isDark: isDark,
                  ),
                  ProfileMenuItem(
                    icon: Icons.privacy_tip_rounded,
                    title: AppLocalizations.of(context)!.privacyPolicy,
                    onTap: () => context.push(AppRouter.privacyPolicy),
                    isDark: isDark,
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Auth Buttons
              if (user != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
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
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push(AppRouter.login),
                    child: const Text(
                      "Log In / Sign Up",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
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

  /*
   * Phase 7: Post-Merge Stability Fixes [x]
   * - [x] Fix compilation errors (L10n, Imports, Const expressions)
   * - [x] Verify build with `flutter analyze`
   */
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