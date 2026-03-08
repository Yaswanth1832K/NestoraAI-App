import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:house_rental/features/smart_tools/domain/models/lease_details.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<Uint8List> generateLeaseAgreement(LeaseDetails details) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'RESIDENTIAL LEASE AGREEMENT',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text('Date: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}'),
                pw.SizedBox(height: 20),
                pw.Text('This Lease Agreement is made between:'),
                pw.SizedBox(height: 10),
                pw.Bullet(text: 'LANDLORD: ${details.ownerName}'),
                pw.Bullet(text: 'TENANT: ${details.tenantName}'),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, text: '1. PROPERTY'),
                pw.Text('The Landlord agrees to rent to the Tenant the property located at:'),
                pw.Text(details.propertyAddress, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, text: '2. TERM'),
                pw.Text('The lease will begin on ${DateFormat('dd MMMM yyyy').format(details.startDate)} and will continue for a period of ${details.durationMonths} months.'),
                pw.SizedBox(height: 20),
                pw.Header(level: 1, text: '3. RENT & DEPOSIT'),
                pw.Text('Monthly Rent: INR ${details.rentAmount}'),
                pw.Text('Security Deposit: INR ${details.securityDeposit}'),
                pw.SizedBox(height: 30),
                pw.Header(level: 1, text: '4. SIGNATURES'),
                pw.SizedBox(height: 50),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide()))),
                        pw.Text('Landlord Signature'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide()))),
                        pw.Text('Tenant Signature'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
