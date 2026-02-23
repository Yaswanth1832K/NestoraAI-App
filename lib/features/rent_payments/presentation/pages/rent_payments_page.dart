import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/widgets/glass_container.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';
import 'package:house_rental/features/rent_payments/presentation/providers/rent_payment_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/notifications/domain/services/notification_service.dart';
import 'package:house_rental/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class RentPaymentsPage extends ConsumerWidget {
  const RentPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text("Rent Payments"), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("Please log in to view payments")),
      );
    }

    final activeRentalAsync = ref.watch(activeRentalProvider(user.uid));
    final paymentsAsync = ref.watch(rentPaymentsProvider(user.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Rent Payments", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Promo Banner
            _buildPromoBanner(context, isDark),
            const SizedBox(height: 32),

            // 2. Current Rent Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Active Rental Due", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {}, // Future: Link to agreement
                  child: const Text("View Agreement", style: TextStyle(color: Color(0xFFFF385C), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            activeRentalAsync.when(
              data: (activeRental) {
                if (activeRental == null) {
                  return _buildNoActiveRentalCard(context, isDark);
                }
                final listingAsync = ref.watch(listingProvider(activeRental.listingId));
                
                return listingAsync.when(
                  data: (listing) => _buildCurrentRentCard(context, ref, user.uid, activeRental.listingTitle, listing.price, isDark),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => _buildCurrentRentCard(context, ref, user.uid, activeRental.listingTitle, 1200.0, isDark),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Error loading rental info: $err"),
            ),

            const SizedBox(height: 40),

            // 3. Payment History Section
            const Text("Payment History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Container(
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text("No transactions yet", style: TextStyle(color: Colors.grey.shade500)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _PaymentHistoryCard(payment: payment, isDark: isDark);
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (err, _) => Text("Error loading history: $err"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF2E1A47), const Color(0xFF1B0F2B)] 
              : [const Color(0xFFFF385C), const Color(0xFFBD1E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFFFF385C)).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "PREMIUM PERK",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Pay with Credit Card",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Earn 2% cashback and secure your credit period.",
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.account_balance_wallet_rounded, size: 72, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildNoActiveRentalCard(BuildContext context, bool isDark) {
    return GlassContainer.standard(
      context: context,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("No Active Rentals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "Once a host approves your visit and you sign an agreement, it will appear here.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRentCard(BuildContext context, WidgetRef ref, String userId, String propertyTitle, double amount, bool isDark) {
    final now = DateTime.now();
    final dueDate = DateTime(now.year, now.month, 5);
    final isOverdue = now.isAfter(dueDate);

    return GlassContainer.standard(
      context: context,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(propertyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      "Due by ${DateFormat('MMM dd, yyyy').format(dueDate)}",
                      style: TextStyle(color: isOverdue ? const Color(0xFFFF385C) : Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isOverdue ? const Color(0xFFFF385C) : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverdue ? "OVERDUE" : "PENDING",
                  style: TextStyle(color: isOverdue ? const Color(0xFFFF385C) : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, color: Colors.white12)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AMOUNT DUE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showPaymentMethods(context, ref, userId, propertyTitle, amount, isDark),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("Pay Rent", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods(BuildContext context, WidgetRef ref, String userId, String propertyTitle, double amount, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckoutUI(
        amount: amount,
        propertyTitle: propertyTitle,
        isDark: isDark,
        onConfirm: (method) => _processPayment(context, ref, userId, propertyTitle, amount, method),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, WidgetRef ref, String userId, String propertyTitle, double amount, String method) async {
    // Show premium progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF385C)),
              SizedBox(height: 24),
              Text("Processing Payment...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    try {
      final payment = RentPaymentEntity(
        id: const Uuid().v4(),
        tenantId: userId,
        propertyId: 'approved-prop-id',
        propertyTitle: propertyTitle,
        amount: amount,
        date: DateTime.now(),
        status: 'success',
        paymentMethod: method,
      );

      await ref.read(makePaymentUseCaseProvider)(payment);
      await ref.read(notificationServiceProvider).notifyPaymentSuccess(tenantId: userId, propertyTitle: propertyTitle, amount: amount);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: const Text("Payment Successful"),
          content: Text("Receipt has been sent to your email and stored in your records."),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF385C))),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }
}

class _CheckoutUI extends StatelessWidget {
  final double amount;
  final String propertyTitle;
  final bool isDark;
  final Function(String) onConfirm;

  const _CheckoutUI({required this.amount, required this.propertyTitle, required this.isDark, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 32),
          const Text("Secure Checkout", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(propertyTitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          _buildMethodTile("UPI (Paytm / GPay)", Icons.qr_code_scanner_rounded),
          _buildMethodTile("Credit / Debit Card", Icons.credit_card_rounded),
          _buildMethodTile("Net Banking", Icons.account_balance_rounded),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Transaction Fee", style: TextStyle(color: Colors.grey)),
              Text("\$0.00", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Payable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("\$${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFFFF385C))),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => onConfirm("UPI"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF385C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Confirm & Pay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: title.contains("UPI") ? Border.all(color: const Color(0xFFFF385C).withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: isDark ? Colors.white70 : Colors.black45),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          if (title.contains("UPI")) const Icon(Icons.check_circle, color: Color(0xFFFF385C), size: 20),
        ],
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final RentPaymentEntity payment;
  final bool isDark;

  const _PaymentHistoryCard({required this.payment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.status == 'success';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isSuccess ? Icons.check_rounded : Icons.close_rounded, color: isSuccess ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.propertyTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy').format(payment.date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("\$${payment.amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(payment.paymentMethod, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
