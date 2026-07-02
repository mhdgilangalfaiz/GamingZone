import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/console_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../providers/console_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/overtime_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import '../../widgets/cards/console_card.dart';
import 'booking_screen.dart';
import 'extension_receipt_screen.dart';
import 'console_form_screen.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'Semua';

  final _filters = ['Semua', 'Tersedia', 'Bermain', 'Reservasi', 'Maintenance'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OvertimeProvider>().startChecking();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ConsoleModel> _filtered(List<ConsoleModel> all) {
    switch (_filter) {
      case 'Tersedia':
        return all.where((c) => c.isAvailable).toList();
      case 'Bermain':
        return all.where((c) => c.isPlaying).toList();
      case 'Reservasi':
        return all.where((c) => c.isReserved).toList();
      case 'Maintenance':
        return all.where((c) => c.isMaintain).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFAB(),
      body: Consumer<ConsoleProvider>(
        builder: (_, cp, __) {
          if (cp.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final list = _filtered(cp.consoles);

          return RefreshIndicator(
            onRefresh: () => cp.loadAll(),
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: Column(
              children: [
                _buildStatusBar(cp),
                _buildFilterChips(),
                Expanded(
                  child: list.isEmpty
                      ? GZEmpty(
                          message: 'Tidak ada konsol $_filter',
                          icon: Icons.sports_esports_outlined,
                        )
                      : Consumer<OvertimeProvider>(
                          builder: (_, otp, __) => GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.95,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: list.length,
                            itemBuilder: (_, i) => ConsoleCard(
                              console: list[i],
                              isOvertime: otp.isOvertime(list[i].id),
                              onTap: () => _onConsoleTap(list[i]),
                              onLongPress: () => _onConsoleLongPress(list[i]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Rental Game'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConsoleFormScreen()),
          ).then((_) => context.read<ConsoleProvider>().loadAll()),
          tooltip: 'Tambah Konsol',
        ),
        IconButton(
          icon: const Icon(Icons.build_circle_outlined),
          tooltip: 'Perbaiki Data Tidak Sinkron',
          onPressed: _confirmFixOrphanData,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => context.read<ConsoleProvider>().loadAll(),
        ),
      ],
    );
  }

  void _confirmFixOrphanData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Perbaiki Data Konsol?'),
        content: const Text(
          'Konsol berstatus "Bermain" tapi tidak punya data transaksi aktif '
          'akan dikembalikan ke status "Tersedia". Gunakan ini jika ada '
          'konsol yang menampilkan "Tidak ada data sesi aktif".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await TransactionRepository().syncOrphanSessions();
              if (mounted) {
                await context.read<ConsoleProvider>().loadAll();
                await context.read<TransactionProvider>().loadActive();
                await context.read<OvertimeProvider>().refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data konsol berhasil disinkronkan'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Perbaiki',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(ConsoleProvider cp) {
    final s = cp.statusSummary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.background,
      child: Row(
        children: [
          _statusPill(
              '${s['available'] ?? 0} Tersedia', AppColors.statusAvailable),
          const SizedBox(width: 8),
          _statusPill('${s['playing'] ?? 0} Bermain', AppColors.statusPlaying),
          const SizedBox(width: 8),
          _statusPill(
              '${s['reserved'] ?? 0} Reservasi', AppColors.statusReserved),
          const SizedBox(width: 8),
          _statusPill(
              '${s['maintenance'] ?? 0} Maint.', AppColors.statusMaintain),
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final selected = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: AppConstants.animFast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.cardBorder,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showStartRentalPicker,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Mulai Sesi',
          style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  void _showStartRentalPicker() {
    final cp = context.read<ConsoleProvider>();
    final available = cp.available;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak ada konsol yang tersedia saat ini')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickConsolSheet(
        consoles: available,
        onPick: (console) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingScreen(console: console),
            ),
          ).then((_) => context.read<ConsoleProvider>().loadAll());
        },
      ),
    );
  }

  void _showSessionInfoSheet(
      ConsoleModel console, TransactionModel? tx, bool isOvertime) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SessionInfoSheet(
        console: console,
        transaction: tx,
        isOvertime: isOvertime,
        onSetAvailable: () async {
          Navigator.pop(context);
          if (tx != null) {
            await context.read<OvertimeProvider>().closeSession(
                  transactionId: tx.id!,
                  consoleId: console.id!,
                );
          } else {
            // Tidak ada data transaksi (data korup) -> langsung update status konsol
            await context
                .read<ConsoleProvider>()
                .updateStatus(console.id!, AppConstants.statusAvailable);
          }
          if (mounted) {
            await context.read<ConsoleProvider>().loadAll();
            await context.read<TransactionProvider>().loadActive();
          }
        },
        onExtend: tx == null
            ? null
            : (extraMinutes) async {
                Navigator.pop(context);
                final currentEnd = tx.endTime ?? DateTime.now();
                final newEnd = currentEnd.add(Duration(minutes: extraMinutes));
                final pricePerHour =
                    tx.rentalType == AppConstants.rentalTypeVIP
                        ? console.priceVip
                        : console.pricePerHour;
                // Hanya hitung biaya untuk durasi TAMBAHAN saja
                final extraCost = (pricePerHour * extraMinutes / 60).ceil();

                final extTx =
                    await context.read<OvertimeProvider>().extendSession(
                          originalTx: tx,
                          extraMinutes: extraMinutes,
                          extraCost: extraCost,
                          newEndTime: newEnd,
                        );

                if (mounted) {
                  await context.read<TransactionProvider>().loadActive();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExtensionReceiptScreen(
                        extensionTx: extTx,
                        extraMinutes: extraMinutes,
                      ),
                    ),
                  );
                }
              },
      ),
    );
  }

  void _onConsoleTap(ConsoleModel console) async {
    if (console.isAvailable) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingScreen(console: console)),
      ).then((_) => context.read<ConsoleProvider>().loadAll());
    } else if (console.isPlaying) {
      final otp = context.read<OvertimeProvider>();
      final isOver = otp.isOvertime(console.id);
      final tx = await context
          .read<TransactionProvider>()
          .getActiveByConsole(console.id!);
      if (mounted) {
        _showSessionInfoSheet(console, tx, isOver);
      }
    }
  }

  void _onConsoleLongPress(ConsoleModel console) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ConsoleOptionsSheet(
        console: console,
        onEdit: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ConsoleFormScreen(console: console)),
          ).then((_) => context.read<ConsoleProvider>().loadAll());
        },
        onStatusChange: (status) {
          Navigator.pop(context);
          context.read<ConsoleProvider>().updateStatus(console.id!, status);
        },
      ),
    );
  }
}

// ── Session Info Sheet ─────────────────────────────────────────────────────
class _SessionInfoSheet extends StatelessWidget {
  final ConsoleModel console;
  final TransactionModel? transaction;
  final bool isOvertime;
  final VoidCallback onSetAvailable;
  final Future<void> Function(int extraMinutes)? onExtend;

  const _SessionInfoSheet({
    required this.console,
    required this.transaction,
    this.isOvertime = false,
    required this.onSetAvailable,
    this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final accentColor = isOvertime ? AppColors.danger : AppColors.statusPlaying;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          if (isOvertime) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppColors.danger.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Waktu bermain sudah habis! Konfirmasi ke user: perpanjang atau selesai.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sports_esports, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(console.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    GZBadge(
                      label: isOvertime ? 'OVERTIME' : 'SEDANG BERMAIN',
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tx != null) ...[
            GZCard(
              borderColor: accentColor.withOpacity(0.3),
              child: Column(
                children: [
                  _row(context, 'No. Invoice', tx.invoiceNo),
                  _row(context, 'Tipe', tx.rentalType),
                  _row(context, 'Jam Mulai',
                      CurrencyFormatter.toTime(tx.startTime)),
                  if (tx.endTime != null)
                    _row(context, 'Jam Selesai',
                        CurrencyFormatter.toTime(tx.endTime!),
                        valueColor: isOvertime ? AppColors.danger : null),
                  if (tx.durationMinutes != null)
                    _row(context, 'Durasi',
                        CurrencyFormatter.minutesToString(tx.durationMinutes!)),
                  const GZDivider(),
                  _row(context, 'Total Tagihan',
                      CurrencyFormatter.toRupiah(tx.rentalCost),
                      bold: true, valueColor: AppColors.accent),
                  _row(context, 'Status Bayar', 'LUNAS',
                      valueColor: AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            GZCard(
              borderColor: AppColors.warning.withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tidak ada data sesi aktif untuk konsol ini.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isOvertime && onExtend != null) ...[
            Text('Perpanjang Waktu',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [15, 30, 60].map((m) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GZButton(
                      label: '+$m mnt',
                      color: AppColors.primary,
                      isOutlined: true,
                      height: 44,
                      onPressed: () => onExtend!(m),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          GZButton(
            label: 'Selesaikan Sesi (Set Tersedia)',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            width: double.infinity,
            height: 48,
            onPressed: onSetAvailable,
          ),
          const SizedBox(height: 8),
          GZButton(
            label: 'Tutup',
            isOutlined: true,
            width: double.infinity,
            height: 44,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _PickConsolSheet extends StatelessWidget {
  final List<ConsoleModel> consoles;
  final void Function(ConsoleModel) onPick;

  const _PickConsolSheet({required this.consoles, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text('Pilih Konsol', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: consoles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = consoles[i];
              return GZCard(
                onTap: () => onPick(c),
                borderColor: AppColors.statusAvailable.withOpacity(0.4),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusAvailable.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sports_esports,
                          color: AppColors.statusAvailable, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(c.type,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    GZBadge(
                        label: 'Tersedia', color: AppColors.statusAvailable),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Console Options Sheet ──────────────────────────────────────────────────
class _ConsoleOptionsSheet extends StatelessWidget {
  final ConsoleModel console;
  final VoidCallback onEdit;
  final void Function(String) onStatusChange;

  const _ConsoleOptionsSheet({
    required this.console,
    required this.onEdit,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(console.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _option(context, Icons.edit_outlined, 'Edit Konsol',
              AppColors.primary, onEdit),
          const SizedBox(height: 8),
          if (!console.isAvailable)
            _option(context, Icons.check_circle_outline, 'Set Tersedia',
                AppColors.statusAvailable, () => onStatusChange('available')),
          if (!console.isReserved) ...[
            const SizedBox(height: 8),
            _option(context, Icons.bookmark_outline, 'Set Reservasi',
                AppColors.statusReserved, () => onStatusChange('reserved')),
          ],
          if (!console.isMaintain) ...[
            const SizedBox(height: 8),
            _option(context, Icons.build_outlined, 'Set Maintenance',
                AppColors.statusMaintain, () => onStatusChange('maintenance')),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _option(BuildContext ctx, IconData icon, String label, Color color,
      VoidCallback onTap) {
    return GZCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderColor: color.withOpacity(0.3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
