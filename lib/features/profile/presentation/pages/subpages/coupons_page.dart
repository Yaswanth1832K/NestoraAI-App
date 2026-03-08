import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/domain/entities/coupon_entity.dart';
import 'package:house_rental/features/listings/presentation/providers/coupon_providers.dart';
import 'package:intl/intl.dart';

class CouponsPage extends ConsumerStatefulWidget {
  const CouponsPage({super.key});

  @override
  ConsumerState<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends ConsumerState<CouponsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        ref.read(couponNotifierProvider.notifier).fetchUserCoupons(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final state = ref.watch(couponNotifierProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('My Coupons & Rewards', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'Used'),
              Tab(text: 'Expired'),
            ],
          ),
        ),
        body: state.when(
          data: (coupons) {
            final available = coupons.where((c) => !c.isUsed && !c.isExpired).toList();
            final used = coupons.where((c) => c.isUsed).toList();
            final expired = coupons.where((c) => !c.isUsed && c.isExpired).toList();

            return TabBarView(
              children: [
                _buildCouponsList(context, available, 'No coupons available', textColor, isDark),
                _buildCouponsList(context, used, 'No used coupons yet', textColor, isDark),
                _buildCouponsList(context, expired, 'No expired coupons', textColor, isDark),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildCouponsList(BuildContext context, List<CouponEntity> coupons, String emptyMessage, Color textColor, bool isDark) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.discount_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ).animate().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return _buildCouponCard(
          context: context,
          coupon: coupon,
          isDark: isDark,
          textColor: textColor,
          delay: (index * 100).ms,
        );
      },
    );
  }

  Widget _buildCouponCard({required BuildContext context, required CouponEntity coupon, required bool isDark, required Color textColor, required Duration delay}) {
    final expiryStr = DateFormat('MMM dd, yyyy').format(coupon.expiryDate);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer.standard(
        context: context,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(
                coupon.type == 'service' ? Icons.handyman_rounded : Icons.stars_rounded, 
                color: AppColors.primary, 
                size: 32
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coupon.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Valid until: $expiryStr', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                  if (coupon.isUsed)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('USED', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (!coupon.isUsed && coupon.isExpired)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text('EXPIRED', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            if (!coupon.isUsed && !coupon.isExpired) ...[
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                   // Navigate to relevant section
                   if (coupon.type == 'service') {
                     context.go('/'); // Go home to find services
                   } else {
                     context.go('/'); // Go home to book property
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(delay: delay).slideX(begin: 0.1),
    );
  }
}
