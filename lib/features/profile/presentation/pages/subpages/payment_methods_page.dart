import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/auth/presentation/providers/auth_providers.dart';
import 'package:house_rental/features/notifications/domain/entities/notification_entity.dart';
import 'package:house_rental/features/notifications/presentation/providers/notification_providers.dart';
import 'package:uuid/uuid.dart';

class PaymentMethodsPage extends ConsumerStatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  ConsumerState<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _upiController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _upiController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      // Trigger Notification
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final uuid = const Uuid();
        ref.read(addNotificationUseCaseProvider)(
          user.uid,
          NotificationEntity(
            id: uuid.v4(),
            title: "Payment Processed",
            body: "Your payment of \$${_amountController.text} via UPI was successful.",
            timestamp: DateTime.now(),
            type: 'success',
            isRead: false,
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful!")),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payments")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Send Payment",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _upiController,
                decoration: InputDecoration(
                  labelText: "UPI ID",
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: "user@upi",
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Pay Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
