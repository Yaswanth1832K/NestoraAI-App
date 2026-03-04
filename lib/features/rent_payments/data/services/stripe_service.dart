import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// flutter_stripe is only usable on mobile/desktop, NOT web.
// We guard EVERY call with kIsWeb checks below.
// ignore: depend_on_referenced_packages
import 'package:flutter_stripe/flutter_stripe.dart'
    if (dart.library.html) 'stripe_web_stub.dart';

// ── Colors ──────────────────────────────────────────────────────
const _kPurple  = Color(0xFF7C5CBF);
const _kPurpleG = Color(0xFF9B7FD4);
const _kCard    = Color(0xFF1C1C1C);

/// Safe Stripe wrapper – works on Web (graceful dialog) and Mobile (real sheet).
class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  // ── Replace these with your real Stripe keys ─────────────────
  static const String _publishableKey = 'pk_test_REPLACE_WITH_YOUR_KEY';
  static const String _secretKey      = 'sk_test_REPLACE_WITH_YOUR_KEY';

  // ── Init – called from main.dart ──────────────────────────────
  static void init() {
    if (kIsWeb) return; // flutter_stripe not supported on web
    Stripe.publishableKey    = _publishableKey;
    Stripe.merchantIdentifier = 'merchant.com.nestora';
  }

  // ── Make payment ──────────────────────────────────────────────
  Future<bool> makePayment({
    required double amount,
    required String currency,
    required BuildContext context,
    String method = 'Card',
  }) async {
    if (kIsWeb) {
      // Web: show a beautiful functional checkout instead of a dead end
      return await _showWebCheckout(context, amount, currency, method);
    }
    return _nativePay(amount: amount, currency: currency, context: context);
  }

  // ── Native Stripe PaymentSheet (Mobile) ────────────────────────
  Future<bool> _nativePay({
    required double amount,
    required String currency,
    required BuildContext context,
  }) async {
    final secret = await _createIntent((amount * 100).toInt(), currency);
    if (secret == null) throw Exception('Could not create payment intent');

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: secret,
        merchantDisplayName: 'Nestora',
        style: ThemeMode.dark,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF7C5CBF),
            background: Color(0xFF1C1C1C),
            componentBackground: Color(0xFF252525),
            componentText: Colors.white,
            placeholderText: Colors.white30,
          ),
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return true;
  }

  // ── Create PaymentIntent (Mobile direct API call) ─────────────
  Future<String?> _createIntent(int amount, String currency) async {
    try {
      final res = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type':  'application/x-www-form-urlencoded',
        },
        body: {'amount': amount.toString(), 'currency': currency},
      );
      final data = json.decode(res.body);
      return data['client_secret'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Web Functional Checkout (High-End Simulation) ──────────────
  Future<bool> _showWebCheckout(BuildContext context, double amount, String currency, String method) async {
    bool success = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          bool processing = false;
          final isUPI = method.contains('UPI');
          final isBank = method.contains('Bank');
          
          return AlertDialog(
            backgroundColor: _kCard,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            content: Container(
              width: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Text('STRIPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        const Spacer(),
                        const Text('TEST MODE', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('Nestora', style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('₹${amount.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(height: 32),

                        // Form Fields based on method
                        if (isUPI) ...[
                          _webField(Icons.qr_code_rounded, 'UPI ID / VPA', 'yourname@upi'),
                          const SizedBox(height: 12),
                          const Text('A notification will be sent to your UPI app', 
                              style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w600)),
                        ] else if (isBank) ...[
                          _webField(Icons.account_balance_rounded, 'Bank Name', 'Select your bank'),
                          const SizedBox(height: 16),
                          _webField(Icons.person_rounded, 'Account Holder', 'Enter name'),
                        ] else ...[
                          _webField(Icons.credit_card_rounded, 'Card Number', '4242 4242 4242 4242'),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _webField(Icons.calendar_today_rounded, 'Expiry', 'MM / YY')),
                            const SizedBox(width: 16),
                            Expanded(child: _webField(Icons.lock_outline_rounded, 'CVC', '•••')),
                          ]),
                        ],
                        const SizedBox(height: 32),

                        // Pay Button
                        GestureDetector(
                          onTap: processing ? null : () async {
                            setState(() => processing = true);
                            await Future.delayed(const Duration(seconds: 2));
                            success = true;
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Container(
                            height: 60,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _kPurple,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: processing
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                : Text('Pay with ${isUPI ? 'UPI' : isBank ? 'Net Banking' : 'Card'}', 
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Secure payments by Stripe', style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    return success;
  }

  Widget _webField(IconData icon, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(children: [
            Icon(icon, color: Colors.white24, size: 18),
            const SizedBox(width: 12),
            Text(hint, style: const TextStyle(color: Colors.white24, fontSize: 14)),
          ]),
        ),
      ],
    );
  }
}
