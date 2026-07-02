import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/database_helper.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/member_snack_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  MemberModel? _member;
  List<TransactionModel> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final memberId = auth.currentUser?.memberId;
    if (memberId != null) {
      final rows = await DatabaseHelper.instance.query(
        AppConstants.tableMembers,
        where: 'id = ?',
        whereArgs: [memberId],
      );
      if (rows.isNotEmpty) _member = MemberModel.fromMap(rows.first);

      final txRepo = TransactionRepository();
      final all = await txRepo.getHistory(limit: 20);
      _history = all
          .where((t) => t.memberId == memberId && t.isCompleted)
          .take(5)
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Diamond': return const Color(0xFF67E8F9);
      case 'Gold':    return AppColors.warning;
      case 'Silver':  return AppColors.textSecondary;
      default:        return const Color(0xFFCD7F32);
    }
  }

  IconData _tierIcon(String tier) {
    switch (tier) {
      case 'Diamond': return Icons.diamond_outlined;
      case 'Gold':    return Icons.emoji_events_outlined;
      case 'Silver':  return Icons.military_tech_outlined;
      default:        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ──────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 160,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A0B35), AppColors.background],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Halo, ${user.fullName.split(' ').first} 👋',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Selamat datang di Gaming Zone',
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                    boxShadow: const [BoxShadow(color: AppColors.glowPurple, blurRadius: 12)],
                                  ),
                                  child: Center(
                                    child: Text(
                                      user.initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_member != null) ...[
                          _buildPointCard(),
                          const SizedBox(height: 16),
                          _buildStatsRow(),
                        ] else
                          _buildNoMemberCard(),
                        const SizedBox(height: 20),
                        const GZSectionHeader(title: 'Riwayat Sewa Terakhir'),
                        const SizedBox(height: 12),
                        if (_history.isEmpty)
                          const GZEmpty(
                              message: 'Belum ada riwayat sewa',
                              icon: Icons.history_outlined)
                        else
                          ..._history.map(_buildHistoryTile),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPointCard() {
    final tier = _member!.tier;
    final color = _tierColor(tier);
    return GZCard(
      borderColor: color.withOpacity(0.4),
      shadows: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_tierIcon(tier), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_member!.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      GZBadge(label: tier, color: color, fontSize: 10),
                      const SizedBox(width: 8),
                      Text(_member!.memberCode,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const GZDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_member!.points}',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: color,
                      shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 12)])),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 6),
                child: Text('poin',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total belanja: ${CurrencyFormatter.toRupiah(_member!.totalSpend)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: GZCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Icon(Icons.history_outlined, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text('${_history.length}',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Text('Sesi Selesai',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GZCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Icon(Icons.stars_outlined, color: AppColors.warning, size: 22),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.toRupiah(_member!.points * 100),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text('Nilai Poin',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildNoMemberCard() {
    return GZCard(
      borderColor: AppColors.warning.withOpacity(0.3),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.warning, size: 22),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Akun kamu belum terhubung ke data member. Hubungi kasir untuk menghubungkan.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ]),
    );
  }

  Widget _buildHistoryTile(TransactionModel tx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GZCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.sports_esports_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.consoleName ?? '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                Text('${tx.durationMinutes ?? 0} menit · ${tx.rentalType}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.toRupiah(tx.totalCost),
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.accent),
          ),
        ]),
      ),
    );
  }
}
