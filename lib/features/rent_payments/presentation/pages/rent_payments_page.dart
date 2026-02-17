import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';
import 'package:house_rental/features/rent_payments/presentation/providers/rent_payment_providers.dart';
import 'package:house_rental/features/notifications/domain/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class RentPaymentsPage extends ConsumerWidget {
  const RentPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    final activeRentalAsync = ref.watch(activeRentalProvider(user.uid));
    final paymentsAsync = ref.watch(rentPaymentsProvider(user.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Rent Payments", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Current Rent Section
            const Text(
              "Current Due",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            activeRentalAsync.when(
              data: (activeRental) {
                if (activeRental == null) {
                  return _buildNoActiveRentalCard(context);
                }
                // Mock rent amount for now, or fetch from listing if available
                const rentAmount = 1200.00; 
                return _buildCurrentRentCard(context, ref, user.uid, activeRental.listingTitle, rentAmount);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text("Error loading rental info: $err"),
            ),

            const SizedBox(height: 24),

            // 2. Payment History Section
            const Text(
              "Payment History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text("No payment history", style: TextStyle(color: Colors.grey.shade600)),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _PaymentHistoryCard(payment: payment);
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (err, _) => Text("Error loading history: $err"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveRentalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.home_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            "No Active Rentals",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "You don't have any approved properties yet.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRentCard(BuildContext context, WidgetRef ref, String userId, String propertyTitle, double amount) {
    final now = DateTime.now();
    // Due date is 5th of current month
    final dueDate = DateTime(now.year, now.month, 5);
    final isOverdue = now.isAfter(dueDate); // Simple check

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverdue 
            ? [Colors.red.shade50, Colors.white]
            : [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    Text(
                      propertyTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}",
                      style: TextStyle(
                        color: isOverdue ? Colors.red : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOverdue ? "OVERDUE" : "PENDING",
                  style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${amount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () => _showPaymentMethods(context, ref, userId, propertyTitle, amount),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.black, // Dark button for contrast
                  foregroundColor: Colors.white,
                ),
                child: const Text("Pay Rent"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods(BuildContext context, WidgetRef ref, String userId, String propertyTitle, double amount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PaymentMethodsSheet(
        amount: amount,
        onPaymentSelected: (method) {
          Navigator.pop(context); // Close sheet
          _processPayment(context, ref, userId, propertyTitle, amount, method);
        },
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context, 
    WidgetRef ref, 
    String userId, 
    String propertyTitle, 
    double amount, 
    String method
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    try {
      final payment = RentPaymentEntity(
        id: const Uuid().v4(),
        tenantId: userId,
        propertyId: 'approved-prop-id', // Hook up to real ID
        propertyTitle: propertyTitle,
        amount: amount,
        date: DateTime.now(),
        status: 'success',
        paymentMethod: method,
      );

      await ref.read(makePaymentUseCaseProvider)(payment);
      
      // Trigger Notification
      await ref.read(notificationServiceProvider).notifyPaymentSuccess(
        tenantId: userId,
        propertyTitle: propertyTitle,
        amount: amount,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      // Show Success Dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text("Payment Successful"),
          content: Text("You have successfully paid \$$amount for $propertyTitle."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Done")
            ),
          ],
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment failed: $e")));
    }
  }
}

class _PaymentMethodsSheet extends StatelessWidget {
  final double amount;
  final Function(String) onPaymentSelected;

  const _PaymentMethodsSheet({required this.amount, required this.onPaymentSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("\$$amount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 24),
          _buildMethodTile(context, "UPI", Icons.qr_code, "Google Pay, PhonePe, Paytm"),
          _buildMethodTile(context, "Credit / Debit Card", Icons.credit_card, "Visa, Mastercard"),
          _buildMethodTile(context, "Net Banking", Icons.account_balance, "All major banks supported"),
          _buildMethodTile(context, "Wallet", Icons.account_balance_wallet, "PayPal, Apple Pay"),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMethodTile(BuildContext context, String title, IconData icon, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () => onPaymentSelected(title),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final RentPaymentEntity payment;

  const _PaymentHistoryCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isSuccess = payment.status == 'success';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: isSuccess ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.propertyTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(payment.date),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  "TxID: ${payment.id.split('-').first.toUpperCase()}",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontFamily: 'Monospace'),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${payment.amount.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (isSuccess)
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Receipt downloaded!")),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text("Receipt", style: TextStyle(color: Colors.blue.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
