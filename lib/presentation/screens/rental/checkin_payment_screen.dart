import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../providers/console_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/gz_widgets.dart';

/// Layar "Check-in & Bayar" — dipakai kasir saat user yang booking-nya
/// sudah di-approve datang ke toko dan siap main. Di sinilah pembayaran
/// benar-benar dikumpulkan (sesuai kesepakatan: bayar dulu sebelum main).
///
/// Setelah bayar, jam mulai/selesai sesi direset ke SEKARANG (durasi tetap
/// sama seperti booking asli), transaksi jadi 'active', dan struk tercetak
/// — persis seperti alur booking manual dari kasir.
class CheckinPaymentScreen extends StatefulWidget {
  final TransactionModel booking;
  const CheckinPaymentScreen({super.key, required this.booking});

  @override
  State<CheckinPaymentScreen> createState() => _CheckinPaymentScreenState();
}

class _CheckinPaymentScreenState extends State<CheckinPaymentScreen> {
  int _step = 0; // 0 = konfirmasi & bayar, 1 = struk
  String _paymentMethod = AppConstants.paymentCash;
  final _cashCtrl = TextEditingController();
  bool _isLoading = false;
  TransactionModel? _savedTransaction;

  int get _total => widget.booking.totalCost;
  int get _cashPaid => int.tryParse(_cashCtrl.text.replaceAll('.', '')) ?? 0;
  int get _change => (_cashPaid - _total).clamp(0, 999999999);

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmCheckin() async {
    if (_paymentMethod == AppConstants.paymentCash && _cashPaid < _total) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Uang bayar kurang dari total tagihan'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = TransactionRepository();
      await repo.checkinBooking(
        transactionId: widget.booking.id!,
        consoleId: widget.booking.consoleId!,
        durationMinutes: widget.booking.durationMinutes ?? 0,
        paymentMethod: _paymentMethod,
        paymentAmount: _paymentMethod == AppConstants.paymentCash
            ? _cashPaid
            : _total,
        changeAmount: _paymentMethod == AppConstants.paymentCash ? _change : 0,
      );

      if (mounted) {
        await context.read<ConsoleProvider>().loadAll();
        await context.read<TransactionProvider>().loadActive();
      }

      final saved = await repo.getById(widget.booking.id!);
      if (mounted) {
        setState(() {
          _savedTransaction = saved;
          _step = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal memproses check-in: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    final tx = _savedTransaction;
    if (tx == null) return;

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
            pw.Text('STRUK RENTAL (Booking App)',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _pdfRow('No. Invoice', tx.invoiceNo),
            _pdfRow('Tanggal', CurrencyFormatter.toReceiptDate(tx.createdAt)),
            pw.Divider(),
            _pdfRow('Konsol', tx.consoleName ?? '-'),
            _pdfRow('Tipe', tx.rentalType),
            _pdfRow('Jam Mulai', CurrencyFormatter.toTime(tx.startTime)),
            if (tx.endTime != null)
              _pdfRow('Jam Selesai', CurrencyFormatter.toTime(tx.endTime!)),
            _pdfRow('Durasi',
                CurrencyFormatter.minutesToString(tx.durationMinutes ?? 0)),
            pw.Divider(),
            _pdfRow('Biaya Rental', CurrencyFormatter.toRupiah(tx.rentalCost),
                bold: true),
            pw.Divider(),
            _pdfRow('Metode Bayar', tx.paymentMethod),
            if (tx.paymentMethod == AppConstants.paymentCash) ...[
              _pdfRow('Bayar', CurrencyFormatter.toRupiah(tx.paymentAmount)),
              _pdfRow('Kembalian', CurrencyFormatter.toRupiah(tx.changeAmount)),
            ],
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text('Terima kasih sudah bermain!',
                style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Gaming Zone — Have Fun!',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Struk_${tx.invoiceNo}.pdf',
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
        title: Text(_step == 0 ? 'Check-in & Bayar' : 'Struk'),
        backgroundColor: AppColors.background,
      ),
      body: AnimatedSwitcher(
        duration: AppConstants.animNormal,
        child: _step == 0 ? _buildPaymentStep() : _buildStrukStep(),
      ),
    );
  }

  Widget _buildPaymentStep() {
    final b = widget.booking;
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GZCard(
            borderColor: AppColors.success.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan Booking',
                    style: Theme.of(context).textTheme.headlineSmall),
                const GZDivider(),
                _summaryRow('Konsol', b.consoleName ?? '-'),
                _summaryRow('Tipe', b.rentalType ?? '-'),
                _summaryRow('Dari', b.cashierName ?? 'User'),
                _summaryRow('Durasi',
                    CurrencyFormatter.minutesToString(b.durationMinutes ?? 0)),
                const GZDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                      CurrencyFormatter.toRupiah(_total),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sesi akan mulai dihitung dari sekarang, dengan durasi sama seperti booking.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Metode Pembayaran',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.paymentMethods.map((m) {
              final selected = _paymentMethod == m;
              return GestureDetector(
                onTap: () => setState(() => _paymentMethod = m),
                child: AnimatedContainer(
                  duration: AppConstants.animFast,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surfaceLight,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                    border: Border.all(
                      color:
                          selected ? AppColors.primary : AppColors.cardBorder,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(m,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          if (_paymentMethod == AppConstants.paymentCash) ...[
            GZTextField(
              label: 'Uang Dibayar (Rp)',
              controller: _cashCtrl,
              prefixIcon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [_total, _total + 5000, _total + 10000, 50000, 100000]
                  .map((amt) {
                return GestureDetector(
                  onTap: () {
                    _cashCtrl.text = amt.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]}.');
                    setState(() {});
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      CurrencyFormatter.toRupiah(amt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_cashPaid > 0) ...[
              const SizedBox(height: 12),
              GZCard(
                borderColor: _cashPaid >= _total
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.danger.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _cashPaid >= _total ? 'Kembalian' : 'Kurang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            _cashPaid >= _total ? AppColors.success : AppColors.danger,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.toRupiah(
                          _cashPaid >= _total ? _change : _total - _cashPaid),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            _cashPaid >= _total ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 32),
          GZButton(
            label: 'Konfirmasi & Bayar',
            icon: Icons.check_circle_outline,
            width: double.infinity,
            height: 52,
            isLoading: _isLoading,
            onPressed: _confirmCheckin,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStrukStep() {
    final tx = _savedTransaction;
    if (tx == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text('Check-in Berhasil!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('Konsol sudah bisa dipakai',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                const Text('──────────────────────',
                    style:
                        TextStyle(color: AppColors.cardBorder, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('STRUK RENTAL (Booking App)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _strukRow('No. Invoice', tx.invoiceNo),
                _strukRow(
                    'Tanggal', CurrencyFormatter.toReceiptDate(tx.createdAt)),
                const SizedBox(height: 8),
                const Text('──────────────────────',
                    style:
                        TextStyle(color: AppColors.cardBorder, fontSize: 12)),
                const SizedBox(height: 8),
                _strukRow('Konsol', tx.consoleName ?? '-'),
                _strukRow('Tipe Rental', tx.rentalType),
                _strukRow('Jam Mulai', CurrencyFormatter.toTime(tx.startTime)),
                if (tx.endTime != null)
                  _strukRow(
                      'Jam Selesai', CurrencyFormatter.toTime(tx.endTime!)),
                _strukRow('Durasi',
                    CurrencyFormatter.minutesToString(tx.durationMinutes ?? 0)),
                const SizedBox(height: 8),
                const Text('──────────────────────',
                    style:
                        TextStyle(color: AppColors.cardBorder, fontSize: 12)),
                const SizedBox(height: 8),
                _strukRow(
                    'Biaya Rental', CurrencyFormatter.toRupiah(tx.rentalCost),
                    isBold: true, valueColor: AppColors.accent),
                const SizedBox(height: 8),
                const Text('──────────────────────',
                    style:
                        TextStyle(color: AppColors.cardBorder, fontSize: 12)),
                const SizedBox(height: 8),
                _strukRow('Metode Bayar', tx.paymentMethod),
                if (tx.paymentMethod == AppConstants.paymentCash) ...[
                  _strukRow(
                      'Dibayar', CurrencyFormatter.toRupiah(tx.paymentAmount)),
                  _strukRow(
                      'Kembalian', CurrencyFormatter.toRupiah(tx.changeAmount),
                      valueColor: AppColors.success),
                ],
                const SizedBox(height: 12),
                const Text('──────────────────────',
                    style:
                        TextStyle(color: AppColors.cardBorder, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('Terima kasih sudah bermain!',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const Text('Gaming Zone — Have Fun! 🎮',
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
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _strukRow(String label, String value,
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
