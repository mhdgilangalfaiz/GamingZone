import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () =>
                context.read<TransactionProvider>().loadDashboard(),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (_, txp, __) {
          final s = txp.dailySummary;

          return RefreshIndicator(
            onRefresh: txp.loadDashboard,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(),
                  const SizedBox(height: 16),
                  _buildDailySummaryCards(s),
                  const SizedBox(height: 20),
                  _buildWeeklyChart(txp),
                  const SizedBox(height: 20),
                  _buildTopConsoles(txp),
                  const SizedBox(height: 20),
                  _buildRevenueBreakdown(s),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader() {
    return GZCard(
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.today_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Laporan Hari Ini',
                  style: Theme.of(context).textTheme.titleLarge),
              Text(
                CurrencyFormatter.toDateLong(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCards(Map<String, dynamic> s) {
    final revenue = s['total_revenue'] as int? ?? 0;
    final totalTx = s['total_tx'] as int? ?? 0;
    final rentalRev = s['rental_revenue'] as int? ?? 0;
    final snackRev = s['snack_revenue'] as int? ?? 0;
    final avgDur = (s['avg_duration'] as num?)?.toInt() ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        GZStatCard(
          title: 'Pendapatan Hari Ini',
          value: CurrencyFormatter.toRupiahCompact(revenue),
          icon: Icons.trending_up,
          color: AppColors.success,
        ),
        GZStatCard(
          title: 'Total Transaksi',
          value: '$totalTx',
          icon: Icons.receipt_long_outlined,
          color: AppColors.primary,
        ),
        GZStatCard(
          title: 'Pendapatan Rental',
          value: CurrencyFormatter.toRupiahCompact(rentalRev),
          icon: Icons.sports_esports_outlined,
          color: AppColors.statusPlaying,
        ),
        GZStatCard(
          title: 'Pendapatan Snack',
          value: CurrencyFormatter.toRupiahCompact(snackRev),
          icon: Icons.fastfood_outlined,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(TransactionProvider txp) {
    final data = txp.weeklyRevenue;
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data.fold<double>(
      1,
      (m, d) => (d['revenue'] as int? ?? 0) > m
          ? (d['revenue'] as int).toDouble()
          : m,
    );

    return GZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GZSectionHeader(title: 'Pendapatan 7 Hari Terakhir'),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.25,
                minY: 0,
                backgroundColor: Colors.transparent,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.cardBorder,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= data.length)
                          return const SizedBox.shrink();
                        final date = DateTime.tryParse(
                            data[idx]['date'] as String? ?? '');
                        if (date == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, _) {
                        if (v == 0) return const SizedBox.shrink();
                        final label = v >= 1000000
                            ? '${(v / 1000000).toStringAsFixed(1)}jt'
                            : v >= 1000
                                ? '${(v / 1000).toStringAsFixed(0)}rb'
                                : v.toStringAsFixed(0);
                        return Text(
                          label,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textMuted),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final rev = rod.toY.toInt();
                      final label = rev >= 1000000
                          ? 'Rp ${(rev / 1000000).toStringAsFixed(1)}jt'
                          : 'Rp ${(rev / 1000).toStringAsFixed(0)}rb';
                      return BarTooltipItem(
                        label,
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(data.length, (i) {
                  final rev = (data[i]['revenue'] as int? ?? 0).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rev,
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.primary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.25,
                          color: AppColors.cardBorder.withOpacity(0.25),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopConsoles(TransactionProvider txp) {
    final top = txp.topConsoles;
    if (top.isEmpty) return const SizedBox.shrink();

    return GZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GZSectionHeader(title: 'Konsol Terpopuler (30 Hari)'),
          const SizedBox(height: 12),
          ...top.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final name = item['name'] as String? ?? '-';
            final count = item['usage_count'] as int? ?? 0;
            final rev = item['revenue'] as int? ?? 0;
            final maxCount = (top.first['usage_count'] as int? ?? 1);
            final ratio = maxCount > 0 ? count / maxCount : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: idx == 0
                              ? AppColors.warning.withOpacity(0.2)
                              : AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${idx + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: idx == 0
                                    ? AppColors.warning
                                    : AppColors.textMuted,
                              )),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Text('$count sesi',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Text(CurrencyFormatter.toRupiahCompact(rev),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation(
                        idx == 0 ? AppColors.warning : AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown(Map<String, dynamic> s) {
    final rental = s['rental_revenue'] as int? ?? 0;
    final snack = s['snack_revenue'] as int? ?? 0;
    final total = rental + snack;
    final rentalPct =
        total > 0 ? (rental / total * 100).toStringAsFixed(1) : '0';
    final snackPct = total > 0 ? (snack / total * 100).toStringAsFixed(1) : '0';

    return GZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GZSectionHeader(title: 'Komposisi Pendapatan'),
          const SizedBox(height: 12),
          if (total > 0) ...[
            SizedBox(
              height: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Flexible(
                      flex: rental,
                      child: Container(color: AppColors.statusPlaying),
                    ),
                    Flexible(
                      flex: snack,
                      child: Container(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _legendItem('Rental', AppColors.statusPlaying, rentalPct,
                  CurrencyFormatter.toRupiah(rental)),
              const SizedBox(width: 16),
              _legendItem('Snack', AppColors.warning, snackPct,
                  CurrencyFormatter.toRupiah(snack)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, String pct, String amount) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '$pct% • $amount',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
