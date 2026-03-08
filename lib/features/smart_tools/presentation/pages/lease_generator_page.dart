import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:house_rental/core/theme/app_colors.dart';
import 'package:house_rental/features/smart_tools/domain/models/lease_details.dart';
import 'package:house_rental/features/smart_tools/domain/services/pdf_service.dart';
import 'package:house_rental/features/notifications/domain/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaseGeneratorPage extends ConsumerStatefulWidget {
  const LeaseGeneratorPage({super.key});

  @override
  ConsumerState<LeaseGeneratorPage> createState() => _LeaseGeneratorPageState();
}

class _LeaseGeneratorPageState extends ConsumerState<LeaseGeneratorPage> {
  final _formKey = GlobalKey<FormState>();
  final _tenantController = TextEditingController();
  final _ownerController = TextEditingController();
  final _addressController = TextEditingController();
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  int _duration = 11;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  bool _isGenerating = false;
  Uint8List? _pdfBytes;

  Future<void> _generateLease() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      final details = LeaseDetails(
        tenantName: _tenantController.text,
        ownerName: _ownerController.text,
        propertyAddress: _addressController.text,
        rentAmount: double.parse(_rentController.text),
        securityDeposit: double.parse(_depositController.text),
        durationMonths: _duration,
        startDate: _startDate,
      );

      final bytes = await PdfService.generateLeaseAgreement(details);
      
      // Trigger notification
      await ref.read(notificationServiceProvider).notifyLeaseAgreementGenerated(
        tenantName: _tenantController.text,
      );

      setState(() {
        _pdfBytes = bytes;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lease agreement generated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating lease: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Rental agreement generator', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: txt,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColors.s24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tenant & Owner Details', isDark),
              _buildTextField(_tenantController, 'Tenant Name', Icons.person_outline, isDark),
              _buildTextField(_ownerController, 'Owner Name', Icons.person_pin_outlined, isDark),
              const SizedBox(height: 24),
              _buildSectionTitle('Property Information', isDark),
              _buildTextField(_addressController, 'Property Address', Icons.location_on_outlined, isDark, maxLines: 2),
              const SizedBox(height: 24),
              _buildSectionTitle('Financial Terms', isDark),
              Row(
                children: [
                  Expanded(child: _buildTextField(_rentController, 'Monthly Rent', Icons.currency_rupee, isDark, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_depositController, 'Security Deposit', Icons.account_balance_wallet_outlined, isDark, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Lease Duration', isDark),
              DropdownButtonFormField<int>(
                value: _duration,
                decoration: _getInputDecoration('Duration', Icons.calendar_month_outlined, isDark),
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                style: TextStyle(color: txt, fontWeight: FontWeight.w600),
                items: [1, 3, 6, 11, 24].map((m) => DropdownMenuItem(value: m, child: Text('$m Months'))).toList(),
                onChanged: (v) => setState(() => _duration = v!),
              ),
              const SizedBox(height: 32),
              if (_pdfBytes == null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateLease,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isGenerating 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Generate Rental Agreement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Agreement Ready',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Printing.layoutPdf(
                              onLayout: (format) async => _pdfBytes!,
                              name: 'Lease_Agreement_${_tenantController.text.replaceAll(' ', '_')}.pdf',
                            ),
                            icon: const Icon(Icons.file_present_rounded),
                            label: const Text('Preview / Print'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => PdfService.sharePdf(
                              _pdfBytes!, 
                              'Lease_Agreement_${_tenantController.text.replaceAll(' ', '_')}.pdf'
                            ),
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _pdfBytes = null),
                      child: const Text('Create New Agreement'),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool isDark, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
        decoration: _getInputDecoration(label, icon, isDark),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon, bool isDark) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
    );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
