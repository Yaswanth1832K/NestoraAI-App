import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/features/rent_payments/domain/entities/rent_payment_entity.dart';
import 'package:house_rental/features/rent_payments/presentation/providers/rent_payment_providers.dart';
import 'package:house_rental/features/notifications/domain/services/notification_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class QRPaymentPage extends ConsumerStatefulWidget {
  final String propertyName;
  final String ownerName;
  final String ownerUpi;
  final String ownerId;
  final double amount;
  final String userId;

  const QRPaymentPage({
    super.key,
    required this.propertyName,
    required this.ownerName,
    required this.ownerUpi,
    required this.ownerId,
    required this.amount,
    required this.userId,
  });

  @override
  ConsumerState<QRPaymentPage> createState() => _QRPaymentPageState();
}

class _QRPaymentPageState extends ConsumerState<QRPaymentPage> {
  bool _isConfirming = false;

  String get upiPaymentLink =>
      'upi://pay?pa=${widget.ownerUpi}&pn=${Uri.encodeComponent(widget.ownerName)}&am=${widget.amount}&cu=INR';

  Future<void> _handlePaid() async {
    setState(() => _isConfirming = true);
    
    // Simulate API call to record payment
    try {
      final payment = RentPaymentEntity(
        id: const Uuid().v4(),
        tenantId: widget.userId,
        propertyId: 'qr-pay',
        propertyTitle: widget.propertyName,
        ownerId: widget.ownerId,
        amount: widget.amount,
        date: DateTime.now(),
        status: 'success',
        paymentMethod: 'UPI QR Scan',
      );

      await ref.read(makePaymentUseCaseProvider)(payment);
      await ref.read(notificationServiceProvider).notifyPaymentSuccess(
        tenantId: widget.userId,
        propertyTitle: widget.propertyName,
        amount: widget.amount,
      );

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Payment Recorded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Your payment has been recorded successfully. The owner will be notified.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back from QR page
              },
              child: const Text('Done', style: TextStyle(color: Color(0xFF9B7FD4), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording payment: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Pay Rent via QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.propertyName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Owner: ${widget.ownerName}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 24),
                  const Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: upiPaymentLink,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Colors.white38, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Scan using any UPI App',
                        style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(GPay, PhonePe, Paytm)',
                    style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _handlePaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CBF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isConfirming
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'I HAVE PAID',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Click after completing the transaction in your UPI app',
              style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
