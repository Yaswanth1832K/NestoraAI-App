import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nestora Privacy Policy",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Effective Date: January 1, 2024",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              "1. Introduction",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Welcome to Nestora. We are committed to protecting your privacy and ensuring you have a positive experience on our website and in using our products and services.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 24),
            Text(
              "2. Data We Collect",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We collect information you provide directly to us, such as when you create an account, update your profile, or communicate with us.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 24),
            Text(
              "3. How We Use Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We use the information we collect to provide, maintain, and improve our services, such as to process transactions and send you related information.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 24),
            Text(
              "4. Data Sharing and Disclosure",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We do not share your personal information with third parties except as described in this policy. We may share information with:",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              "• Service providers who perform services on our behalf\n• Professional advisors\n• Law enforcement or other government agencies if required by law",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 24),
            Text(
              "5. Data Security",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We use reasonable measures to help protect information about you from loss, theft, misuse and unauthorized access, disclosure, alteration and destruction.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 24),
            Text(
              "6. Your Rights",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "You have the right to access, correct, or delete your personal information. You can manage your information in your account settings or contact us for assistance.",
              style: TextStyle(height: 1.5),
            ),
             SizedBox(height: 24),
            Text(
              "7. Contact Us",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "If you have any questions about this Privacy Policy, please contact us at support@nestora.ai.",
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
