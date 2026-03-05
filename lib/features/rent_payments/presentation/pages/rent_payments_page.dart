import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';
import 'package:house_rental/features/rent_payments/presentation/providers/rent_payment_providers.dart';
import 'package:house_rental/features/listings/presentation/providers/listings_providers.dart';
import 'package:house_rental/features/notifications/domain/services/notification_service.dart';
import 'package:house_rental/features/rent_payments/data/services/stripe_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:house_rental/core/router/app_router.dart';

// ── Colors ──────────────────────────────────────────────────────
const _kPurple   = Color(0xFF7C5CBF);
const _kPurpleG  = Color(0xFF9B7FD4);
const _kDark     = Color(0xFF0D0D0D);
const _kCard     = Color(0xFF1C1C1C);

class RentPaymentsPage extends ConsumerWidget {
  const RentPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: _kDark,
        appBar: AppBar(
          title: const Text('Rent Payments',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: _kCard, elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view payments',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    final activeRentalAsync = ref.watch(activeRentalProvider(user.uid));
    final paymentsAsync     = ref.watch(rentPaymentsProvider(user.uid));

    return Scaffold(
      backgroundColor: _kDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Payments',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Premium Hero Header ──────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kDark, Color(0xFF1A1A1A)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _PromoBanner(),
              const SizedBox(height: 32),
              
              const Text('Quick Actions', style: TextStyle(color: Colors.white,
                  fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              _QuickPayRow(userId: user.uid, isDark: isDark),
            ]),
          ),

          // ── Active Payments ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Active Rentals', style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Agreements',
                      style: TextStyle(color: _kPurpleG, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 12),
              activeRentalAsync.when(
                data: (rental) {
                  if (rental == null) return _NoRentalCard();
                  final listingAsync = ref.watch(listingProvider(rental.listingId));
                  return listingAsync.when(
                    data: (l) => _RentCard(context: context, ref: ref,
                        userId: user.uid, title: rental.listingTitle, amount: l.price),
                    loading: () => const _LoadingBox(),
                    error: (_, __) => _RentCard(context: context, ref: ref,
                        userId: user.uid, title: rental.listingTitle, amount: 1200),
                  );
                },
                loading: () => const _LoadingBox(),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),

              const SizedBox(height: 40),

              // ── Clumsy Bill Grid Replacement ──────────────────
              const Text('Bill Payments', style: TextStyle(color: Colors.white,
                  fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Pay all your utilities securely via Nestora Pay',
                  style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              _BillGrid(userId: user.uid),

              const SizedBox(height: 40),

              // ── History ──────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Recent Transactions', style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                      style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 12),
              paymentsAsync.when(
                data: (payments) {
                  if (payments.isEmpty) return _EmptyHistory();
                  return ListView.separated(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _TxCard(payment: payments[i]),
                  );
                },
                loading: () => const _LoadingBox(),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 50),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Stripe promo banner ────────────────────────────────────────
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D1B69).withOpacity(0.9),
            _kPurple.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -20, top: -20,
          child: Icon(Icons.stars_rounded, size: 100, color: Colors.white.withOpacity(0.05)),
        ),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('STRIPE SECURED', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
            ),
            const SizedBox(height: 14),
            const Text('Instant Rent\nPayments.', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, height: 1.1, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text('Secure, fast, and encrypted by Stripe.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
          ])),
          const SizedBox(width: 16),
          Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.credit_card_rounded, size: 48, color: Colors.white),
            const SizedBox(height: 4),
            Text('Nestora Pay', style: TextStyle(
                color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
        ]),
      ]),
    ),
  );
}

// ── Quick pay row ──────────────────────────────────────────────
class _QuickPayRow extends StatelessWidget {
  final String userId;
  final bool isDark;
  const _QuickPayRow({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final methods = [
      ('To Contact', Icons.person_rounded, const Color(0xFF4CAF50)),
      ('To UPI',     Icons.qr_code_rounded, const Color(0xFF2196F3)),
      ('To Bank',    Icons.account_balance_rounded, const Color(0xFFFF9800)),
      ('Card Pay',   Icons.credit_card_rounded, _kPurple),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: methods.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) {
          final (label, icon, color) = methods[i];
          return GestureDetector(
            onTap: () => _showStripeSheet(ctx, userId, 500, label),
            child: Container(
              width: 88,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 10,
                        fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showStripeSheet(BuildContext ctx, String userId, double amount, String method) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _StripeCheckoutSheet(
        amount: amount, method: method, userId: userId),
    );
  }
}

// ── Rent card ──────────────────────────────────────────────────
class _RentCard extends StatelessWidget {
  final BuildContext context;
  final WidgetRef ref;
  final String userId, title;
  final double amount;
  const _RentCard({required this.context, required this.ref,
      required this.userId, required this.title, required this.amount});

  @override
  Widget build(BuildContext ctx) {
    final due = DateTime.now();
    final dueDate = DateTime(due.year, due.month, 5);
    final overdue = due.isAfter(dueDate);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCard, 
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.home_work_rounded, color: _kPurpleG, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900, fontSize: 18),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Due ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                style: TextStyle(
                    color: overdue ? Colors.redAccent : Colors.white38,
                    fontSize: 12, fontWeight: FontWeight.w700)),
          ])),
          _StatusChip(overdue: overdue),
        ]),
        const SizedBox(height: 24),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 24),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TOTAL DUE', style: TextStyle(color: Colors.white38,
                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text('₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white,
                    fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1)),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
              builder: (_) => _StripeCheckoutSheet(
                  amount: amount, method: 'Monthly Rent', userId: userId),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kPurple, _kPurpleG]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.4),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Row(children: [
                Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text('PAY RENT', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool overdue;
  const _StatusChip({required this.overdue});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
        color: (overdue ? Colors.red : Colors.orange).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (overdue ? Colors.red : Colors.orange).withOpacity(0.2))),
    child: Text(overdue ? 'OVERDUE' : 'PENDING',
        style: TextStyle(color: overdue ? Colors.redAccent : Colors.orange,
            fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
  );
}

// ── Bill grid ──────────────────────────────────────────────────
class _BillGrid extends StatelessWidget {
  final String userId;
  const _BillGrid({required this.userId});

  @override
  Widget build(BuildContext context) {
    final bills = [
      ('Electricity', Icons.bolt_rounded,         const Color(0xFFFFD600)),
      ('Water',       Icons.water_drop_rounded,   const Color(0xFF29B6F6)),
      ('Gas',         Icons.local_fire_department_rounded, const Color(0xFFFF7043)),
      ('Internet',    Icons.wifi_rounded,          const Color(0xFF66BB6A)),
      ('DTH/Cable',   Icons.tv_rounded,            const Color(0xFFAB47BC)),
      ('Maintenance', Icons.build_rounded,         const Color(0xFF42A5F5)),
      ('Society',     Icons.apartment_rounded,     const Color(0xFFEC407A)),
      ('Insurance',   Icons.shield_rounded,        const Color(0xFF26A69A)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 0.85),
      itemCount: bills.length,
      itemBuilder: (ctx, i) {
        final (name, icon, color) = bills[i];
        return GestureDetector(
          onTap: () => showModalBottomSheet(
            context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
            builder: (_) => _StripeCheckoutSheet(
                amount: 200, method: name, userId: userId),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _kCard, 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(name, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ]),
          ),
        );
      },
    );
  }
}

// ── Stripe checkout bottom sheet ───────────────────────────────
class _StripeCheckoutSheet extends ConsumerStatefulWidget {
  final double amount;
  final String method, userId;
  const _StripeCheckoutSheet({required this.amount, required this.method, required this.userId});

  @override
  ConsumerState<_StripeCheckoutSheet> createState() => _StripeCheckoutSheetState();
}

class _StripeCheckoutSheetState extends ConsumerState<_StripeCheckoutSheet> {
  bool _processing = false;
  late int _selected;

  @override
  void initState() {
    super.initState();
    if (widget.method.toLowerCase().contains('upi')) {
      _selected = 1;
    } else if (widget.method.toLowerCase().contains('bank')) {
      _selected = 2;
    } else {
      _selected = 0;
    }
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    try {
      final paymentMethod = _selected == 0 ? 'Card' : _selected == 1 ? 'UPI' : 'Net Banking';
      // Attempt Stripe PaymentSheet
      final success = await StripeService.instance.makePayment(
          amount: widget.amount, currency: 'inr', context: context, method: paymentMethod);

      if (!mounted) return;
      if (success) {
        // Record in Firestore
        final payment = RentPaymentEntity(
          id: const Uuid().v4(),
          tenantId: widget.userId,
          propertyId: 'stripe-pay',
          propertyTitle: widget.method,
          amount: widget.amount,
          date: DateTime.now(),
          status: 'success',
          paymentMethod: _selected == 0 ? 'Stripe Card' : _selected == 1 ? 'UPI' : 'Net Banking',
        );
        await ref.read(makePaymentUseCaseProvider)(payment);
        await ref.read(notificationServiceProvider).notifyPaymentSuccess(
            tenantId: widget.userId, propertyTitle: widget.method, amount: widget.amount);

        if (!mounted) return;
        Navigator.pop(context);
        _showSuccess();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'),
              backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSuccess() {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 48),
        ),
        const SizedBox(height: 20),
        const Text('Payment Successful!', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 8),
        Text('₹${widget.amount.toStringAsFixed(0)} paid via Stripe',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        
        // Reward Promo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text('You earned a free spin!', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
          ]),
        ),
        const SizedBox(height: 24),

        Row(children: [
           Expanded(
             child: TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text('Back', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
             ),
           ),
           const SizedBox(width: 12),
           Expanded(
             flex: 2,
             child: GestureDetector(
               onTap: () {
                 Navigator.pop(context);
                 context.push(AppRouter.bookingSpin);
               },
               child: Container(
                 padding: const EdgeInsets.symmetric(vertical: 14),
                 alignment: Alignment.center,
                 decoration: BoxDecoration(
                     gradient: const LinearGradient(colors: [_kPurple, _kPurpleG]),
                     borderRadius: BorderRadius.circular(14)),
                 child: const Text('SPIN & WIN', style: TextStyle(
                     color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
               ),
             ),
           ),
        ]),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24,
          24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),

        const Text('Secure Checkout', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.w900, fontSize: 22)),
        const SizedBox(height: 4),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_rounded, size: 12, color: Colors.white38),
          SizedBox(width: 4),
          Text('256-bit SSL encrypted by Stripe',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        const SizedBox(height: 28),

        // Amount
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_kPurple.withOpacity(0.2), _kPurpleG.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kPurple.withOpacity(0.3)),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.method, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text('₹${widget.amount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w900, fontSize: 32)),
            ]),
            const Spacer(),
            Column(children: [
              const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 22),
              const SizedBox(height: 4),
              const Text('Verified', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
            ]),
          ]),
        ),
        const SizedBox(height: 22),

        // Payment method selector
        const Align(alignment: Alignment.centerLeft,
            child: Text('PAYMENT METHOD', style: TextStyle(color: Colors.white38,
                fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
        const SizedBox(height: 12),
        _methodTile(0, 'Credit / Debit Card', Icons.credit_card_rounded),
        const SizedBox(height: 8),
        _methodTile(1, 'UPI (Paytm / GPay / PhonePe)', Icons.qr_code_scanner_rounded),
        const SizedBox(height: 8),
        _methodTile(2, 'Net Banking', Icons.account_balance_rounded),

        const SizedBox(height: 28),

        // Confirm button
        GestureDetector(
          onTap: _processing ? null : _pay,
          child: Container(
            width: double.infinity, height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kPurple, _kPurpleG]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: _processing
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Pay ₹${widget.amount.toStringAsFixed(0)} Securely',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w900, fontSize: 16)),
                ]),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Powered by Stripe · Your card is never stored on our servers',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 11)),
      ]),
    );
  }

  Widget _methodTile(int idx, String label, IconData icon) {
    final sel = _selected == idx;
    return GestureDetector(
      onTap: () => setState(() => _selected = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? _kPurple.withOpacity(0.15) : _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? _kPurple : Colors.white10, width: 1.5),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: sel ? _kPurpleG : Colors.white38),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white60,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
          const Spacer(),
          if (sel) const Icon(Icons.check_circle_rounded, color: _kPurpleG, size: 18),
        ]),
      ),
    );
  }
}

// ── No rental card ─────────────────────────────────────────────
class _NoRentalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10)),
    child: Column(children: [
      Icon(Icons.home_outlined, size: 52, color: Colors.white24),
      const SizedBox(height: 16),
      const Text('No Active Rentals', style: TextStyle(
          color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      const Text('Once your rental is approved, payment will appear here.',
          style: TextStyle(color: Colors.white38, fontSize: 13),
          textAlign: TextAlign.center),
    ]),
  );
}

// ── Loading box ────────────────────────────────────────────────
class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) => const Center(
      child: Padding(padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _kPurple)));
}

// ── Empty history ──────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32), alignment: Alignment.center,
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(18)),
    child: const Text('No transactions yet',
        style: TextStyle(color: Colors.white38, fontSize: 14)),
  );
}

// ── Transaction card ───────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final RentPaymentEntity payment;
  const _TxCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final ok = payment.status == 'success';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: (ok ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, size: 20,
              color: ok ? Colors.greenAccent : Colors.redAccent),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.propertyTitle, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(DateFormat('MMM dd, yyyy • h:mm a').format(payment.date),
              style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${payment.amount.toStringAsFixed(0)}',
              style: TextStyle(color: ok ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(payment.paymentMethod.toUpperCase(),
              style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ]),
      ]),
    );
  }
}
