import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class ReceiptService {
  /// Generates and previews a PDF receipt
  static Future<void> generateAndShowReceipt({
    required BuildContext context,
    required String tenantName,
    required String unitName,
    required String propertyName,
    required double amount,
    required String mpesaCode,
    required String paymentType,
    required DateTime paidAt,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'E-KODI',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Smart Property Management',
                      style: const pw.TextStyle(
                        color: PdfColors.blue100,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),

              // ── Receipt details ──────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _receiptRow(
                      'Receipt Date',
                      '${paidAt.day}/${paidAt.month}/${paidAt.year} '
                          '${paidAt.hour}:${paidAt.minute.toString().padLeft(2, '0')}',
                    ),
                    _divider(),
                    _receiptRow('M-Pesa Receipt', mpesaCode),
                    _divider(),
                    _receiptRow('Payment Type', paymentType),
                    _divider(),
                    _receiptRow('Tenant Name', tenantName),
                    _divider(),
                    _receiptRow('Property', propertyName),
                    _divider(),
                    _receiptRow('Unit', unitName),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── Amount box ───────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green700),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'AMOUNT PAID',
                      style: const pw.TextStyle(
                        color: PdfColors.green900,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'KES ${amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: PdfColors.green900,
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── Footer ───────────────────────────────────────────────
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your payment!',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'This is an official receipt generated by E-Kodi Property Management System.',
                      style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 10,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const pw.TextStyle(
                        color: PdfColors.grey500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Show print/save preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'E-Kodi_Receipt_${mpesaCode}_$unitName.pdf',
    );
  }

  static pw.Widget _receiptRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _divider() {
    return pw.Divider(color: PdfColors.grey200, height: 1);
  }
}
