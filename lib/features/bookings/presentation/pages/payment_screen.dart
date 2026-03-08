import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/listings/domain/entities/listing_entity.dart';
import 'package:house_rental/features/bookings/data/repositories/booking_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/coupon_providers.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final ListingEntity listing;
  final double totalPayable;
  final DateTime moveInDate;
  final String? appliedCouponId;

  const PaymentScreen({
    super.key,
    required this.listing,
    required this.totalPayable,
    required this.moveInDate,
    this.appliedCouponId,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isProcessing = false;
  
  void _processPayment() async {
    setState(() => _isProcessing = true);
    
    // Call Mock Repository POST /bookings
    // Assuming currentUser_123 is just a placeholder, we use real uid if available
    final user = ref.read(authStateProvider).value;
    final tenantId = user?.uid ?? 'unknown_user';

    final success = await ref.read(bookingRepositoryProvider).createBooking(
      propertyId: widget.listing.id,
      tenantId: tenantId,
      rentAmount: widget.totalPayable,
      bookingDate: widget.moveInDate,
      paymentStatus: 'PAID',
    );
    
    if (!mounted) return;
    
    if (success) {
      if (widget.appliedCouponId != null && user != null) {
        await ref.read(couponNotifierProvider.notifier).useCoupon(
          widget.appliedCouponId!,
          user.uid,
        );
      }
      context.pushReplacement('/payment-success', extra: widget.listing);
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment or booking failed. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Secure Payment', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Display
            Center(
              child: Column(
                children: [
                  Text('Amount to Pay', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 8),
                  Text(
                    '₹${NumberFormat('#,##,###').format(widget.totalPayable)}',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: textColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Payment Methods
            Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 16),
            
            _buildPaymentMethodCard('Credit/Debit Card', Icons.credit_card, true, isDark),
            const SizedBox(height: 12),
            _buildPaymentMethodCard('UPI', Icons.account_balance_wallet, false, isDark),
            const SizedBox(height: 12),
            _buildPaymentMethodCard('Net Banking', Icons.account_balance, false, isDark),

            const SizedBox(height: 48),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, bool isSelected, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
        boxShadow: AppColors.softShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      ),
    );
  }
}
