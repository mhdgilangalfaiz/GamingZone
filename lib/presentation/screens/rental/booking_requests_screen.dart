import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/database_helper.dart';
import '../../../data/models/transaction_model.dart';
import '../../widgets/common/gz_widgets.dart';
import 'checkin_payment_screen.dart';

/// Layar untuk kasir mengelola booking yang masuk dari aplikasi User.
///
/// Alurnya 2 tahap:
/// 1. "Menunggu Persetujuan" (status=requested) — kasir Setujui/Tolak.
///    Setujui HANYA mengunci jadwal & konsol (jadi 'confirmed' /
///    'reserved'), BELUM ada pembayaran.
/// 2. "Menunggu Check-in" (status=confirmed) — begitu user datang ke
///    toko, kasir tap "Check-in & Bayar" untuk memproses pembayaran &
///    memulai sesi (baru di sinilah tagihan/struk dibuat).
class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});
  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<TransactionModel> _requests = [];
  List<TransactionModel> _confirmed = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final requestedRows = await DatabaseHelper.instance.query(
      AppConstants.tableTransactions,
      where: 'status = ?',
      whereArgs: [AppConstants.statusRequested],
      orderBy: 'created_at ASC',
    );
    final confirmedRows = await DatabaseHelper.instance.query(
      AppConstants.tableTransactions,
      where: 'status = ?',
      whereArgs: [AppConstants.statusConfirmed],
      orderBy: 'start_time ASC',
    );
    _requests = requestedRows.map(TransactionModel.fromMap).toList();
    _confirmed = confirmedRows.map(TransactionModel.fromMap).toList();
    if (mounted) setState(() => _loading = false);
  }

  // ── Tahap 1: Setujui / Tolak ──────────────────────────────────────────────
  Future<void> _approve(TransactionModel tx) async {
    final timeLabel = tx.endTime != null
        ? '${DateFormat('HH:mm', 'id_ID').format(tx.startTime)}–${DateFormat('HH:mm', 'id_ID').format(tx.endTime!)}'
        : DateFormat('HH:mm', 'id_ID').format(tx.startTime);
    final confirm = await _showConfirmDialog(
      title: 'Konfirmasi Booking',
      message:
          'Setujui booking ${tx.consoleName} dari ${tx.cashierName} untuk jam $timeLabel?\nKonsol akan direservasi untuk user ini — pembayaran diminta saat mereka check-in.',
      confirmLabel: 'Setujui',
      confirmColor: AppColors.success,
    );
    if (!confirm) return;

    // Status jadi 'confirmed' — BELUM 'active', karena belum ada
    // pembayaran. Jam mulai/selesai TETAP dipakai persis seperti yang
    // diatur user saat booking, biar kasir tahu jadwalnya.
    await DatabaseHelper.instance.update(
      AppConstants.tableTransactions,
      {
        'status': AppConstants.statusConfirmed,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tx.id],
    );
    // Konsol jadi 'reserved' (dikunci untuk booking ini, belum 'playing'
    // karena sesi belum dimulai/dibayar).
    if (tx.consoleId != null) {
      await DatabaseHelper.instance.update(
        AppConstants.tableConsoles,
        {'status': AppConstants.statusReserved},
        where: 'id = ?',
        whereArgs: [tx.consoleId],
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Booking ${tx.consoleName} disetujui — menunggu user check-in ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    }
  }

  Future<void> _reject(TransactionModel tx) async {
    final confirm = await _showConfirmDialog(
      title: 'Tolak Booking',
      message: 'Tolak booking ${tx.consoleName} dari ${tx.cashierName}?',
      confirmLabel: 'Tolak',
      confirmColor: AppColors.danger,
    );
    if (!confirm) return;

    await DatabaseHelper.instance.update(
      AppConstants.tableTransactions,
      {
        'status': AppConstants.statusCancelled,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tx.id],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking ditolak'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    }
  }

  // ── Tahap 2: Check-in & Bayar / Batalkan ──────────────────────────────────
  Future<void> _goToCheckin(TransactionModel tx) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckinPaymentScreen(booking: tx)),
    );
    if (result == true) _load();
  }

  Future<void> _cancelConfirmed(TransactionModel tx) async {
    final confirm = await _showConfirmDialog(
      title: 'Batalkan Booking',
      message:
          'Batalkan booking ${tx.consoleName} dari ${tx.cashierName}? Konsol akan tersedia lagi.',
      confirmLabel: 'Batalkan',
      confirmColor: AppColors.danger,
    );
    if (!confirm) return;

    await DatabaseHelper.instance.update(
      AppConstants.tableTransactions,
      {
        'status': AppConstants.statusCancelled,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tx.id],
    );
    if (tx.consoleId != null) {
      await DatabaseHelper.instance.update(
        AppConstants.tableConsoles,
        {'status': AppConstants.statusAvailable},
        where: 'id = ?',
        whereArgs: [tx.consoleId],
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking dibatalkan, konsol tersedia lagi'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking dari User'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(text: 'Persetujuan (${_requests.length})'),
            Tab(text: 'Check-in (${_confirmed.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildConfirmedTab(),
              ],
            ),
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _requests.isEmpty
          ? const GZEmpty(
              message: 'Tidak ada booking yang menunggu persetujuan',
              icon: Icons.calendar_today_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _buildRequestCard(_requests[i]),
            ),
    );
  }

  Widget _buildConfirmedTab() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _confirmed.isEmpty
          ? const GZEmpty(
              message: 'Tidak ada booking yang menunggu check-in',
              icon: Icons.how_to_reg_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _confirmed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _buildConfirmedCard(_confirmed[i]),
            ),
    );
  }

  Widget _buildRequestCard(TransactionModel tx) {
    final date =
        DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt);

    return GZCard(
      borderColor: AppColors.warning.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_esports_outlined,
                    color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.consoleName ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Dari: ${tx.cashierName ?? 'User'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              GZBadge(
                  label: 'Menunggu',
                  color: AppColors.warning,
                  fontSize: 10),
            ],
          ),
          const GZDivider(),
          _detailRow(Icons.category_outlined, 'Kategori',
              tx.rentalType ?? '-'),
          const SizedBox(height: 6),
          _detailRow(
            Icons.schedule_outlined,
            'Jam Main',
            tx.endTime != null
                ? '${DateFormat('HH:mm', 'id_ID').format(tx.startTime)} – '
                    '${DateFormat('HH:mm', 'id_ID').format(tx.endTime!)} '
                    '(${(tx.durationMinutes ?? 0)} menit)'
                : '${(tx.durationMinutes ?? 0)} menit',
          ),
          const SizedBox(height: 6),
          _detailRow(Icons.payments_outlined, 'Estimasi',
              CurrencyFormatter.toRupiah(tx.totalCost)),
          const SizedBox(height: 6),
          _detailRow(Icons.access_time_outlined, 'Dikirim', date),
          if (tx.notes != null && tx.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.notes_outlined, 'Catatan', tx.notes!),
          ],
          const GZDivider(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reject(tx),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approve(tx),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedCard(TransactionModel tx) {
    return GZCard(
      borderColor: AppColors.primary.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.consoleName ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Dari: ${tx.cashierName ?? 'User'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              GZBadge(
                  label: 'Terjadwal',
                  color: AppColors.primary,
                  fontSize: 10),
            ],
          ),
          const GZDivider(),
          _detailRow(Icons.category_outlined, 'Kategori',
              tx.rentalType ?? '-'),
          const SizedBox(height: 6),
          _detailRow(
            Icons.schedule_outlined,
            'Jam Main',
            tx.endTime != null
                ? '${DateFormat('HH:mm', 'id_ID').format(tx.startTime)} – '
                    '${DateFormat('HH:mm', 'id_ID').format(tx.endTime!)} '
                    '(${(tx.durationMinutes ?? 0)} menit)'
                : '${(tx.durationMinutes ?? 0)} menit',
          ),
          const SizedBox(height: 6),
          _detailRow(Icons.payments_outlined, 'Perlu Dibayar',
              CurrencyFormatter.toRupiah(tx.totalCost)),
          const GZDivider(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelConfirmed(tx),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Batalkan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _goToCheckin(tx),
                  icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                  label: const Text('Check-in & Bayar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
