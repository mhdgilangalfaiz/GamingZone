import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/database_helper.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../widgets/common/gz_widgets.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});
  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  List<TransactionModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await DatabaseHelper.instance.query(
      AppConstants.tableTransactions,
      where: "status = ?",
      whereArgs: [AppConstants.statusRequested],
      orderBy: 'created_at ASC',
    );
    _requests = rows.map(TransactionModel.fromMap).toList();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(TransactionModel tx) async {
    final confirm = await _showConfirmDialog(
      title: 'Konfirmasi Booking',
      message:
          'Setujui booking ${tx.consoleName} dari ${tx.cashierName}?\nKonsol akan langsung aktif.',
      confirmLabel: 'Setujui',
      confirmColor: AppColors.success,
    );
    if (!confirm) return;

    final repo = TransactionRepository();
    // Ubah status jadi active dan set startTime ke sekarang
    await DatabaseHelper.instance.update(
      AppConstants.tableTransactions,
      {
        'status': AppConstants.statusActive,
        'start_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [tx.id],
    );
    // Set konsol jadi playing
    if (tx.consoleId != null) {
      await DatabaseHelper.instance.update(
        AppConstants.tableConsoles,
        {'status': 'playing'},
        where: 'id = ?',
        whereArgs: [tx.consoleId],
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking ${tx.consoleName} disetujui ✓'),
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
        title: Row(
          children: [
            const Text('Booking Masuk'),
            if (_requests.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_requests.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppColors.background,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _requests.isEmpty
                  ? const GZEmpty(
                      message: 'Tidak ada booking masuk saat ini',
                      icon: Icons.calendar_today_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _buildCard(_requests[i]),
                    ),
            ),
    );
  }

  Widget _buildCard(TransactionModel tx) {
    final date = DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
        .format(tx.createdAt);

    return GZCard(
      borderColor: AppColors.warning.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Detail
          _detailRow(Icons.category_outlined, 'Kategori',
              tx.rentalType ?? '-'),
          const SizedBox(height: 6),
          _detailRow(Icons.schedule_outlined, 'Durasi',
              '${(tx.durationMinutes ?? 0)} menit'),
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

          // Tombol aksi
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
