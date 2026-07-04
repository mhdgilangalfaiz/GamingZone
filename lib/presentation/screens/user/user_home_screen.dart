import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/database/database_helper.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/console_model.dart';
import '../../../data/models/snack_model.dart';
import '../../../data/repositories/member_snack_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/console_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'user_navigation.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  MemberModel? _member;
  List<TransactionModel> _history = [];
  List<ConsoleModel> _consoles = [];
  List<SnackModel> _snacks = [];
  bool _loading = true;

  final GlobalKey _historyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final memberId = auth.currentUser?.memberId;

    final consoles = await ConsoleRepository().getAll();
    final snacks = await SnackRepository().getAll();
    _consoles = consoles;
    _snacks = snacks;

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

  void _goToTab(int index) {
    context.findAncestorStateOfType<UserNavigationState>()?.navigateTo(index);
  }

  void _scrollToHistory() {
    final ctx = _historyKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: AppConstants.animNormal, curve: Curves.easeOut);
    }
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

  Color _statusColor(String status) {
    switch (status) {
      case 'playing': return AppColors.primary;
      case 'reserved': return AppColors.warning;
      case 'maintenance': return AppColors.danger;
      default: return AppColors.success;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'playing': return 'Dipakai';
      case 'reserved': return 'Reservasi';
      case 'maintenance': return 'Maintenance';
      default: return 'Tersedia';
    }
  }

  IconData _snackIcon(String category) {
    switch (category) {
      case 'minuman': return Icons.local_drink_outlined;
      case 'rokok':   return Icons.smoking_rooms_outlined;
      default:        return Icons.fastfood_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser; // nullable — bisa guest

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
                    expandedHeight: 150,
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
                                      user != null
                                          ? 'Halo, ${user.fullName.split(' ').first} 👋'
                                          : 'Halo, Pengunjung 👋',
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
                                    child: user != null
                                        ? Text(
                                            user.initials,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16),
                                          )
                                        : const Icon(Icons.person_outline,
                                            color: Colors.white, size: 22),
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Hero banner ──────────────────────────────────
                        _buildHeroBanner(),
                        const SizedBox(height: 16),

                        // ── Quick actions ────────────────────────────────
                        _buildQuickActions(),
                        const SizedBox(height: 20),

                        // ── Status akun / member ─────────────────────────
                        if (user == null) ...[
                          _buildGuestCard(),
                          const SizedBox(height: 20),
                        ] else if (_member != null) ...[
                          _buildPointCard(),
                          const SizedBox(height: 16),
                          _buildStatsRow(),
                          const SizedBox(height: 20),
                        ] else ...[
                          _buildNoMemberCard(),
                          const SizedBox(height: 20),
                        ],

                        // ── Konsol tersedia ───────────────────────────────
                        if (_consoles.isNotEmpty) ...[
                          _sectionHeaderWithAction(
                            'Konsol Tersedia',
                            'Lihat Semua',
                            () => _goToTab(1),
                          ),
                          const SizedBox(height: 12),
                          _buildConsoleRow(),
                          const SizedBox(height: 20),
                        ],

                        // ── Menu favorit ──────────────────────────────────
                        if (_snacks.isNotEmpty) ...[
                          _sectionHeaderWithAction(
                            'Menu Favorit',
                            'Order Sekarang',
                            () => _goToTab(2),
                          ),
                          const SizedBox(height: 12),
                          _buildSnackRow(),
                          const SizedBox(height: 20),
                        ],

                        // ── Riwayat ────────────────────────────────────────
                        if (user != null) ...[
                          Container(
                            key: _historyKey,
                            child: const GZSectionHeader(title: 'Riwayat Sewa Terakhir'),
                          ),
                          const SizedBox(height: 12),
                          if (_history.isEmpty)
                            const GZEmpty(
                                message: 'Belum ada riwayat sewa',
                                icon: Icons.history_outlined)
                          else
                            ..._history.map(_buildHistoryTile),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Hero banner ──────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.glowPurple, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.sports_esports_rounded,
                size: 90, color: Colors.white.withOpacity(0.12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Main Tanpa Antri',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 200,
                child: Text(
                  'Booking konsol favoritmu & atur sendiri jam mainnya, langsung dari HP.',
                  style: TextStyle(
                      fontSize: 12.5, color: Colors.white.withOpacity(0.9)),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => _goToTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Booking Sekarang',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.primaryDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick actions ────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      (Icons.calendar_today_outlined, 'Booking', AppColors.primary, () => _goToTab(1)),
      (Icons.fastfood_outlined, 'Order', AppColors.accent, () => _goToTab(2)),
      (Icons.history_outlined, 'Riwayat', AppColors.warning, _scrollToHistory),
      (Icons.person_outline, 'Profil', AppColors.textSecondary, () => _goToTab(3)),
    ];

    return Row(
      children: actions.map((a) {
        final (icon, label, color, onTap) = a;
        return Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionHeaderWithAction(String title, String actionLabel, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GZSectionHeader(title: title),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(actionLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  // ── Konsol tersedia (horizontal) ─────────────────────────────────────────
  Widget _buildConsoleRow() {
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _consoles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = _consoles[i];
          final color = _statusColor(c.status);
          return GestureDetector(
            onTap: () => _goToTab(1),
            child: Container(
              width: 128,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(Icons.sports_esports, color: color, size: 16),
                      ),
                      GZBadge(label: _statusLabel(c.status), color: color, fontSize: 9),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    c.isVipOnly
                        ? 'VIP ${CurrencyFormatter.toRupiah(c.priceVip)}'
                        : '${CurrencyFormatter.toRupiah(c.pricePerHour)}/jam',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Menu favorit (horizontal) ────────────────────────────────────────────
  Widget _buildSnackRow() {
    final items = _snacks.where((s) => s.isActive && s.stock > 0).take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = items[i];
          return GestureDetector(
            onTap: () => _goToTab(2),
            child: Container(
              width: 118,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_snackIcon(s.category), color: AppColors.accent, size: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(CurrencyFormatter.toRupiah(s.price),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestCard() {
    return GZCard(
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_membership_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kumpulkan poin member, simpan riwayat sewa, & booking lebih cepat — cukup masuk atau daftar dulu.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GZButton(
                  label: 'Masuk',
                  icon: Icons.login_rounded,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GZButton(
                  label: 'Daftar Akun',
                  icon: Icons.person_add_alt_1_rounded,
                  isOutlined: true,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
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
