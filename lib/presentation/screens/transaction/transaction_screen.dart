import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import 'receipt_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadActive();
      context.read<TransactionProvider>().loadHistory();
    });
    // Timer untuk update tampilan setiap detik agar durasi sesi aktif
    // (jam:menit:detik) berjalan secara real-time tanpa perlu refresh manual.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaksi'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Aktif', icon: Icon(Icons.play_circle_outline, size: 18)),
            Tab(text: 'Riwayat', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildActiveTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    return Consumer<TransactionProvider>(
      builder: (_, txp, __) {
        if (txp.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (txp.active.isEmpty) {
          return const GZEmpty(
            message: 'Tidak ada sesi aktif saat ini',
            icon: Icons.sports_esports_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () => txp.loadActive(),
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: txp.active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _activeCard(txp.active[i]),
          ),
        );
      },
    );
  }

  Widget _activeCard(TransactionModel tx) {
    final elapsed = DateTime.now().difference(tx.startTime);
    return GZCard(
      borderColor: AppColors.statusPlaying.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.statusPlaying.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_esports,
                    color: AppColors.statusPlaying, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.consoleName ?? '-',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(tx.invoiceNo,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              GZTimerDisplay(elapsed: elapsed, color: AppColors.accent),
            ],
          ),
          const GZDivider(),
          Row(
            children: [
              _txInfo('Tipe', tx.rentalType),
              _txInfo('Member', tx.memberName ?? 'Umum'),
              _txInfo('Mulai', CurrencyFormatter.toTime(tx.startTime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _txInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildDateFilter(),
        Expanded(
          child: Consumer<TransactionProvider>(
            builder: (_, txp, __) {
              if (txp.isLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (txp.history.isEmpty) {
                return const GZEmpty(
                  message: 'Belum ada riwayat transaksi',
                  icon: Icons.receipt_long_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () => txp.loadHistory(),
                color: AppColors.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: txp.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _historyCard(txp.history[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(isFrom: true),
              child: GZCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      _dateFrom != null
                          ? CurrencyFormatter.toDateShort(_dateFrom!)
                          : 'Dari Tanggal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDate(isFrom: false),
              child: GZCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      _dateTo != null
                          ? CurrencyFormatter.toDateShort(_dateTo!)
                          : 'Sampai Tanggal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearFilter,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(TransactionModel tx) {
    final isCompleted = tx.isCompleted;
    final statusColor = isCompleted ? AppColors.success : AppColors.danger;

    return GZCard(
      onTap: () async {
        final detail =
            await context.read<TransactionProvider>().getById(tx.id!);
        if (detail != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ReceiptScreen(transaction: detail)),
          );
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.consoleName ?? '-',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${tx.invoiceNo} • ${CurrencyFormatter.toDateTime(tx.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tx.memberName != null)
                  Text(tx.memberName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                          )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.toRupiah(tx.totalCost),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              GZBadge(
                label: isCompleted ? 'Selesai' : 'Batal',
                color: statusColor,
                fontSize: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom)
        _dateFrom = picked;
      else
        _dateTo = picked;
    });
    final from = _dateFrom != null
        ? '${_dateFrom!.year}-${_dateFrom!.month.toString().padLeft(2, '0')}-${_dateFrom!.day.toString().padLeft(2, '0')}'
        : null;
    final to = _dateTo != null
        ? '${_dateTo!.year}-${_dateTo!.month.toString().padLeft(2, '0')}-${_dateTo!.day.toString().padLeft(2, '0')}'
        : null;
    context.read<TransactionProvider>().loadHistory(dateFrom: from, dateTo: to);
  }

  void _clearFilter() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    context.read<TransactionProvider>().loadHistory();
  }
}
