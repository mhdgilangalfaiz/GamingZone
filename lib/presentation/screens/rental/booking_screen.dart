import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/console_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../providers/console_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class BookingScreen extends StatefulWidget {
  final ConsoleModel console;
  const BookingScreen({super.key, required this.console});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  int _step = 0; // 0 = booking, 1 = payment, 2 = struk

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late String _rentalType = widget.console.isVipOnly
      ? AppConstants.rentalTypeVIP
      : AppConstants.rentalTypeRegular;
  String _paymentMethod = AppConstants.paymentCash;
  final _cashCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TransactionModel? _savedTransaction;
  bool _isLoading = false;

  // ── Computed ───────────────────────────────────────────────────────────────
  int get _durationMinutes {
    if (_startTime == null || _endTime == null) return 0;
    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    final diff = end - start;
    return diff > 0 ? diff : diff + 1440; // handle midnight crossing
  }

  int get _rentalCost {
    if (_durationMinutes <= 0) return 0;
    final pricePerHour = _rentalType == AppConstants.rentalTypeVIP
        ? widget.console.priceVip
        : widget.console.pricePerHour;
    return (pricePerHour * _durationMinutes / 60).ceil();
  }

  int get _cashPaid => int.tryParse(_cashCtrl.text.replaceAll('.', '')) ?? 0;
  int get _change => (_cashPaid - _rentalCost).clamp(0, 999999999);

  String _timeStr(TimeOfDay? t) => t == null
      ? '--:--'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime _toDateTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Pick Time ──────────────────────────────────────────────────────────────
  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  // ── Save Booking ───────────────────────────────────────────────────────────
  Future<void> _confirmBooking() async {
    if (_startTime == null || _endTime == null) {
      _snack('Pilih jam mulai dan jam selesai dulu', isError: true);
      return;
    }
    if (_durationMinutes <= 0) {
      _snack('Jam selesai harus lebih dari jam mulai', isError: true);
      return;
    }
    if (_paymentMethod == AppConstants.paymentCash && _cashPaid < _rentalCost) {
      _snack('Uang bayar kurang dari total tagihan', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = TransactionRepository();
      final invoiceNo = await repo.generateInvoiceNo();
      final now = DateTime.now();
      final startDt = _toDateTime(_startTime!);
      final endDt = _toDateTime(_endTime!);

      final tx = TransactionModel(
        invoiceNo: invoiceNo,
        consoleId: widget.console.id,
        consoleName: widget.console.name,
        rentalType: _rentalType,
        startTime: startDt,
        endTime: endDt,
        durationMinutes: _durationMinutes,
        rentalCost: _rentalCost,
        totalCost: _rentalCost,
        paymentMethod: _paymentMethod,
        paymentAmount: _paymentMethod == AppConstants.paymentCash
            ? _cashPaid
            : _rentalCost,
        changeAmount: _paymentMethod == AppConstants.paymentCash ? _change : 0,
        status: 'active',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        cashierName: 'Admin',
        createdAt: now,
        updatedAt: now,
      );

      await repo.startRental(tx);

      // Reload providers
      if (mounted) {
        await context.read<ConsoleProvider>().loadAll();
        await context.read<TransactionProvider>().loadActive();
      }

      // Fetch saved transaction for struk
      if (mounted) {
        final saved = await context
            .read<TransactionProvider>()
            .getActiveByConsole(widget.console.id!);
        setState(() {
          _savedTransaction = saved ?? tx.copyWith(invoiceNo: invoiceNo);
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) _snack('Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
    ));
  }

  // ── PDF Export ─────────────────────────────────────────────────────────────
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
            pw.Text('STRUK RENTAL',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _pdfRow('No. Invoice', tx.invoiceNo),
            _pdfRow('Tanggal', CurrencyFormatter.toReceiptDate(tx.createdAt)),
            pw.Divider(),
            _pdfRow('Konsol', tx.consoleName ?? '-'),
            _pdfRow('Tipe', tx.rentalType),
            _pdfRow('Jam Mulai', _timeStr(_startTime)),
            _pdfRow('Jam Selesai', _timeStr(_endTime)),
            _pdfRow(
                'Durasi', CurrencyFormatter.minutesToString(_durationMinutes)),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_step == 0
            ? 'Booking Rental'
            : _step == 1
                ? 'Pembayaran'
                : 'Struk Pembayaran'),
        backgroundColor: AppColors.background,
      ),
      body: AnimatedSwitcher(
        duration: AppConstants.animNormal,
        child: _step == 0
            ? _buildBookingStep()
            : _step == 1
                ? _buildPaymentStep()
                : _buildStrukStep(),
      ),
    );
  }

  // ── STEP 0: Booking ────────────────────────────────────────────────────────
  Widget _buildBookingStep() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Konsol
          GZCard(
            borderColor: AppColors.primary.withOpacity(0.4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sports_esports,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.console.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(widget.console.type,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (!widget.console.isVipOnly) ...[
                            Text(
                              'Reguler: ${CurrencyFormatter.toRupiah(widget.console.pricePerHour)}/jam',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            'VIP: ${CurrencyFormatter.toRupiah(widget.console.priceVip)}/jam',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kategori
          Text('Kategori', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          if (widget.console.isVipOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Konsol ini hanya tersedia di Room VIP (ber-AC)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.warning),
              ),
            ),
          Row(
            children: (widget.console.isVipOnly
                    ? [AppConstants.rentalTypeVIP]
                    : [
                        AppConstants.rentalTypeRegular,
                        AppConstants.rentalTypeVIP
                      ])
                .map((type) {
              final selected = _rentalType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _rentalType = type),
                  child: AnimatedContainer(
                    duration: AppConstants.animFast,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMD),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.cardBorder,
                      ),
                      boxShadow: selected
                          ? [
                              const BoxShadow(
                                  color: AppColors.glowPurple, blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: Text(
                      type == AppConstants.rentalTypeVIP ? 'VIP' : 'Reguler',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Pilih Jam
          Text('Waktu Bermain',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _timePickerCard('Jam Mulai', _startTime, true)),
              const SizedBox(width: 12),
              Expanded(child: _timePickerCard('Jam Selesai', _endTime, false)),
            ],
          ),

          // Durasi & Harga Preview
          if (_startTime != null &&
              _endTime != null &&
              _durationMinutes > 0) ...[
            const SizedBox(height: 16),
            GZCard(
              borderColor: AppColors.accent.withOpacity(0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoBox(
                      'Durasi',
                      CurrencyFormatter.minutesToString(_durationMinutes),
                      AppColors.accent),
                  Container(width: 1, height: 40, color: AppColors.cardBorder),
                  _infoBox(
                      'Total Harga',
                      CurrencyFormatter.toRupiah(_rentalCost),
                      AppColors.success),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Catatan
          GZTextField(
            label: 'Catatan (opsional)',
            controller: _notesCtrl,
            prefixIcon: Icons.notes_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          GZButton(
            label: 'Lanjut ke Pembayaran',
            icon: Icons.arrow_forward,
            width: double.infinity,
            height: 52,
            onPressed:
                (_startTime != null && _endTime != null && _durationMinutes > 0)
                    ? () => setState(() => _step = 1)
                    : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _timePickerCard(String label, TimeOfDay? time, bool isStart) {
    return GestureDetector(
      onTap: () => _pickTime(isStart),
      child: GZCard(
        borderColor: time != null
            ? AppColors.primary.withOpacity(0.4)
            : AppColors.cardBorder,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              isStart ? Icons.play_circle_outline : Icons.stop_circle_outlined,
              color: time != null ? AppColors.primary : AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              _timeStr(time),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color:
                    time != null ? AppColors.textPrimary : AppColors.textMuted,
                shadows: time != null
                    ? [const Shadow(color: AppColors.glowPurple, blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  // ── STEP 1: Payment ────────────────────────────────────────────────────────
  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ringkasan
          GZCard(
            borderColor: AppColors.success.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan Booking',
                    style: Theme.of(context).textTheme.headlineSmall),
                const GZDivider(),
                _summaryRow('Konsol', widget.console.name),
                _summaryRow('Tipe', _rentalType),
                _summaryRow('Jam Mulai', _timeStr(_startTime)),
                _summaryRow('Jam Selesai', _timeStr(_endTime)),
                _summaryRow('Durasi',
                    CurrencyFormatter.minutesToString(_durationMinutes)),
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
                      CurrencyFormatter.toRupiah(_rentalCost),
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
          const SizedBox(height: 20),

          // Metode Bayar
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

          // Input uang cash
          if (_paymentMethod == AppConstants.paymentCash) ...[
            GZTextField(
              label: 'Uang Dibayar (Rp)',
              controller: _cashCtrl,
              prefixIcon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            // Quick cash buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _rentalCost,
                _rentalCost + 5000,
                _rentalCost + 10000,
                50000,
                100000,
              ].map((amt) {
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
                borderColor: _cashPaid >= _rentalCost
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.danger.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _cashPaid >= _rentalCost ? 'Kembalian' : 'Kurang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _cashPaid >= _rentalCost
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.toRupiah(_cashPaid >= _rentalCost
                          ? _change
                          : _rentalCost - _cashPaid),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _cashPaid >= _rentalCost
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 32),
          Row(
            children: [
              GZButton(
                label: 'Kembali',
                icon: Icons.arrow_back,
                isOutlined: true,
                height: 52,
                width: 120,
                onPressed: () => setState(() => _step = 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GZButton(
                  label: 'Konfirmasi & Bayar',
                  icon: Icons.check_circle_outline,
                  height: 52,
                  isLoading: _isLoading,
                  onPressed: _confirmBooking,
                ),
              ),
            ],
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

  // ── STEP 2: Struk ──────────────────────────────────────────────────────────
  Widget _buildStrukStep() {
    final tx = _savedTransaction;
    if (tx == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success header
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
                const Text('Pembayaran Berhasil!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('Konsol siap digunakan',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Struk
          GZCard(
            borderColor: AppColors.cardBorder,
            child: Column(
              children: [
                // Header struk
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
                const Text('STRUK RENTAL',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),

                // Detail
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
                _strukRow('Jam Mulai', _timeStr(_startTime)),
                _strukRow('Jam Selesai', _timeStr(_endTime)),
                _strukRow('Durasi',
                    CurrencyFormatter.minutesToString(_durationMinutes)),
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

          // Action buttons
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
