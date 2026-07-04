import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/database_helper.dart';
import '../../providers/console_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/member_snack_provider.dart';
import '../../providers/overtime_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import '../../widgets/cards/console_card.dart';
import '../snack/snack_screen.dart';
import '../settings/settings_screen.dart';
import '../main_navigation.dart';
import '../rental/booking_requests_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _pendingBookings = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<ConsoleProvider>().loadAll(),
      context.read<TransactionProvider>().loadActive(),
      context.read<TransactionProvider>().loadDashboard(),
    ]);
    context.read<OvertimeProvider>().startChecking();
    // Hitung booking dari User yang butuh tindakan kasir: menunggu
    // persetujuan (requested) ATAU sudah disetujui tapi belum check-in
    // & bayar (confirmed).
    final rows = await DatabaseHelper.instance.query(
      AppConstants.tableTransactions,
      where: 'status IN (?, ?)',
      whereArgs: [AppConstants.statusRequested, AppConstants.statusConfirmed],
    );
    if (mounted) setState(() => _pendingBookings = rows.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildActiveRentals(),
                  const SizedBox(height: 20),
                  _buildConsolesGrid(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      actions: [
        // Tombol notifikasi booking masuk dari User
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today_outlined,
                  color: AppColors.textSecondary),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BookingRequestsScreen()),
                );
                _load(); // refresh badge setelah kembali
              },
            ),
            if (_pendingBookings > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.warning, shape: BoxShape.circle),
                  child: Text(
                    '$_pendingBookings',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GAMING ZONE',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        shadows: [
                          const Shadow(
                              color: AppColors.glowPurple, blurRadius: 12)
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.toDateLong(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glowGreen,
                  border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        shadows: [
                          Shadow(color: AppColors.glowGreen, blurRadius: 4)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary Cards ─────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    return Consumer2<TransactionProvider, ConsoleProvider>(
      builder: (_, txp, cp, __) {
        final s = txp.dailySummary;
        final revenue = s['total_revenue'] as int? ?? 0;
        final totalTx = s['total_tx'] as int? ?? 0;
        final playing = cp.playing.length;
        final available = cp.available.length;

        return GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            GZStatCard(
              title: 'Pendapatan Hari Ini',
              value: CurrencyFormatter.toRupiahCompact(revenue),
              icon: Icons.payments_outlined,
              color: AppColors.success,
              subtitle: '+Hari ini',
            ),
            GZStatCard(
              title: 'Total Transaksi',
              value: totalTx.toString(),
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
              subtitle: 'Selesai',
            ),
            GZStatCard(
              title: 'Sedang Bermain',
              value: playing.toString(),
              icon: Icons.sports_esports,
              color: AppColors.statusPlaying,
              subtitle: '$available tersedia',
            ),
            GZStatCard(
              title: 'Konsol Aktif',
              value: (playing + available).toString(),
              icon: Icons.devices_other,
              color: AppColors.warning,
              subtitle: 'dari ${cp.consoles.length}',
            ),
          ],
        );
      },
    );
  }

  // ── Active Rentals ────────────────────────────────────────────────────────
  Widget _buildActiveRentals() {
    return Consumer2<TransactionProvider, OvertimeProvider>(
      builder: (_, txp, otp, __) {
        final actives = txp.active;
        if (actives.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GZSectionHeader(
              title: 'Sesi Aktif (${actives.length})',
              action: 'Lihat Semua',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            ...actives.take(3).map((tx) {
              final isOver = otp.isOvertime(tx.consoleId);
              final c = isOver ? AppColors.danger : AppColors.statusPlaying;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GZCard(
                  borderColor: c.withOpacity(0.4),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.sports_esports, color: c, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.consoleName ?? '-',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              tx.memberName ?? 'Umum • ${tx.rentalType}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GZBadge(
                              label: isOver ? 'OVERTIME' : 'AKTIF',
                              color: isOver
                                  ? AppColors.danger
                                  : AppColors.success),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.toTime(tx.startTime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ── Consoles Grid ─────────────────────────────────────────────────────────
  Widget _buildConsolsGrid() {
    return Consumer<ConsoleProvider>(
      builder: (_, cp, __) {
        final consoles = cp.consoles.take(6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GZSectionHeader(
              title: 'Status Konsol',
              action: 'Semua',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: consoles.length,
              itemBuilder: (_, i) => ConsoleCard(console: consoles[i]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConsolesGrid() => _buildConsolsGrid();

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      const _QuickAction(
          'Mulai Sesi', Icons.play_circle_outline, AppColors.primary, 1),
      const _QuickAction(
          'Kasir Snack', Icons.fastfood_outlined, AppColors.warning, 2),
      const _QuickAction(
          'Data Member', Icons.people_outline, AppColors.accent, 3),
      const _QuickAction(
          'Laporan', Icons.bar_chart_outlined, AppColors.success, 4),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GZSectionHeader(title: 'Aksi Cepat'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: actions.map((a) => _buildQuickActionItem(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(_QuickAction a) {
    return GestureDetector(
      onTap: () {
        if (a.navIndex == 2) {
          // Kasir Snack → push SnackScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SnackScreen()),
          );
        } else {
          // Navigate via MainNavigation bottom nav
          final nav = context.findAncestorStateOfType<MainNavigationState>();
          nav?.navigateTo(a.navIndex);
        }
      },
      child: GZCard(
        padding: const EdgeInsets.all(8),
        borderColor: a.color.withOpacity(0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: a.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.icon, color: a.color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              a.label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final int navIndex;
  const _QuickAction(this.label, this.icon, this.color, this.navIndex);
}
