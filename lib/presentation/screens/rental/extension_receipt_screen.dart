import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../widgets/common/gz_widgets.dart';

/// Struk untuk perpanjangan waktu rental — hanya menampilkan biaya
/// tambahan (bukan total ulang), karena durasi sebelumnya sudah dibayar.
class ExtensionReceiptScreen extends StatelessWidget {
  final TransactionModel extensionTx;
  final int extraMinutes;

  const ExtensionReceiptScreen({
    super.key,
    required this.extensionTx,
    required this.extraMinutes,
  });

  Future<void> _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 8 * PdfPageFormat.mm,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('GAMING ZONE',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Gaming Center Management',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 4),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text('STRUK PERPANJANGAN WAKTU',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _pdfRow('No. Invoice', extensionTx.invoiceNo),
            _pdfRow('Tanggal',
                CurrencyFormatter.toReceiptDate(extensionTx.createdAt)),
            pw.Divider(),
            _pdfRow('Konsol', extensionTx.consoleName ?? '-'),
            _pdfRow('Penambahan Waktu',
                CurrencyFormatter.minutesToString(extraMinutes)),
            _pdfRow('Jam Selesai Baru',
                CurrencyFormatter.toTime(extensionTx.endTime!)),
            pw.Divider(),
            _pdfRow('Biaya Tambahan',
                CurrencyFormatter.toRupiah(extensionTx.rentalCost),
                bold: true),
            pw.Divider(),
            _pdfRow('Metode Bayar', extensionTx.paymentMethod),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text('Catatan: waktu sebelumnya sudah lunas.',
                style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Terima kasih sudah bermain!',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Struk_Perpanjangan_${extensionTx.invoiceNo}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Struk Perpanjangan'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
              ),
              child: Column(
                children: [
                  const Icon(Icons.access_time_filled,
                      color: Colors.white, size: 44),
                  const SizedBox(height: 8),
                  const Text('Waktu Berhasil Diperpanjang!',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text(
                    '+${CurrencyFormatter.minutesToString(extraMinutes)} ditambahkan',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Struk
            GZCard(
              borderColor: AppColors.cardBorder,
              child: Column(
                children: [
                  const Text('GAMING ZONE',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 2)),
                  const Text('Gaming Center Management',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const _Dashed(),
                  const SizedBox(height: 4),
                  const Text('STRUK PERPANJANGAN WAKTU',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  _row('No. Invoice', extensionTx.invoiceNo),
                  _row('Tanggal',
                      CurrencyFormatter.toReceiptDate(extensionTx.createdAt)),
                  const SizedBox(height: 8),
                  const _Dashed(),
                  const SizedBox(height: 8),
                  _row('Konsol', extensionTx.consoleName ?? '-'),
                  _row('Penambahan Waktu',
                      CurrencyFormatter.minutesToString(extraMinutes)),
                  if (extensionTx.endTime != null)
                    _row('Jam Selesai Baru',
                        CurrencyFormatter.toTime(extensionTx.endTime!),
                        valueColor: AppColors.primary),
                  const SizedBox(height: 8),
                  const _Dashed(),
                  const SizedBox(height: 8),
                  _row('Biaya Tambahan',
                      CurrencyFormatter.toRupiah(extensionTx.rentalCost),
                      isBold: true, valueColor: AppColors.accent),
                  const SizedBox(height: 8),
                  const _Dashed(),
                  const SizedBox(height: 8),
                  _row('Metode Bayar', extensionTx.paymentMethod),
                  const SizedBox(height: 12),
                  const _Dashed(),
                  const SizedBox(height: 8),
                  const Text(
                    'Catatan: waktu sebelumnya sudah lunas,\nini hanya tagihan tambahan.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text('Terima kasih sudah bermain! 🎮',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: GZButton(
                    label: 'Export PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    color: AppColors.danger,
                    isOutlined: true,
                    height: 50,
                    onPressed: _exportPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GZButton(
                    label: 'Selesai',
                    icon: Icons.done_all,
                    height: 50,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();
  @override
  Widget build(BuildContext context) {
    return const Text('──────────────────────',
        style: TextStyle(color: AppColors.cardBorder, fontSize: 12));
  }
}
