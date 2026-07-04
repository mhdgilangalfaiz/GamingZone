import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  MemberModel? _member;
  int _sessionCount = 0;
  bool _loading = true;
  int? _loadedForUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    // Muat ulang tiap kali user berganti (mis. baru saja login).
    if (userId != null && userId != _loadedForUserId) {
      _loadedForUserId = userId;
      _load();
    }
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

      final all = await TransactionRepository().getHistory(limit: 100);
      _sessionCount =
          all.where((t) => t.memberId == memberId && t.isCompleted).length;
    } else {
      _member = null;
      _sessionCount = 0;
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

  // ── Edit Profil ────────────────────────────────────────────────────────
  void _showEditProfileDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialog) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Profil',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GZTextField(
                  label: 'Nama Lengkap',
                  controller: nameCtrl,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 10),
                GZTextField(
                  label: 'No. Telepon (opsional)',
                  controller: phoneCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialog(() => saving = true);
                      final updated = UserModel(
                        id: user.id,
                        username: user.username,
                        passwordHash: user.passwordHash,
                        role: user.role,
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim().isEmpty
                            ? null
                            : phoneCtrl.text.trim(),
                        memberId: user.memberId,
                        isActive: user.isActive,
                        createdAt: user.createdAt,
                        updatedAt: DateTime.now(),
                      );
                      await UserRepository().update(updated);
                      if (context.mounted) {
                        await context.read<AuthProvider>().refreshCurrentUser();
                      }
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil berhasil diperbarui'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Text('Simpan',
                      style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ganti Password',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GZTextField(
                label: 'Password Lama',
                controller: oldCtrl,
                prefixIcon: Icons.lock_outline,
                obscure: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              GZTextField(
                label: 'Password Baru',
                controller: newCtrl,
                prefixIcon: Icons.lock_reset_outlined,
                obscure: true,
                validator: (v) => v == null || v.length < 6
                    ? 'Min. 6 karakter'
                    : null,
              ),
              const SizedBox(height: 10),
              GZTextField(
                label: 'Konfirmasi Password',
                controller: confirmCtrl,
                prefixIcon: Icons.lock_reset_outlined,
                obscure: true,
                validator: (v) =>
                    v != newCtrl.text ? 'Password tidak sama' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final auth = context.read<AuthProvider>();
              final repo = UserRepository();
              // Verifikasi password lama
              final ok = await repo.login(
                  auth.currentUser!.username, oldCtrl.text);
              if (ok == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Password lama salah'),
                    backgroundColor: AppColors.danger,
                  ));
                }
                return;
              }
              await repo.updatePassword(auth.currentUser!.id!, newCtrl.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Password berhasil diubah'),
                  backgroundColor: AppColors.success,
                ));
              }
            },
            child: const Text('Simpan',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: const [
                    BoxShadow(color: AppColors.glowPurple, blurRadius: 16),
                  ],
                ),
                child: const Icon(Icons.person_outline,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Anda belum masuk',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Masuk atau buat akun untuk booking konsol, order snack, dan mengumpulkan poin member.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              GZButton(
                label: 'Masuk',
                icon: Icons.login_rounded,
                width: double.infinity,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
              const SizedBox(height: 12),
              GZButton(
                label: 'Daftar Akun Baru',
                icon: Icons.person_add_alt_1_rounded,
                isOutlined: true,
                width: double.infinity,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Yakin ingin keluar dari akun ini?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              // Kembali ke Dashboard User (root) — Dashboard Admin cuma
              // "menumpuk" di atasnya, jadi logout tinggal turun ke root.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return _buildGuestView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeroHeader(user),
                    const SizedBox(height: 16),

                    if (_member != null) ...[
                      _buildStatsRow(),
                      const SizedBox(height: 16),
                      _buildMembershipCard(),
                      const SizedBox(height: 16),
                    ] else ...[
                      _buildNoMemberCard(),
                      const SizedBox(height: 16),
                    ],

                    _buildInfoCard(user),
                    const SizedBox(height: 16),
                    _buildMenuCard(user),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Header hero ──────────────────────────────────────────────────────────
  Widget _buildHeroHeader(UserModel user) {
    final joined = DateFormat('MMMM yyyy', 'id_ID').format(user.createdAt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.glowPurple, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('@${user.username}',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.white.withOpacity(0.75))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(user.roleLabel,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: Colors.white.withOpacity(0.75)),
              const SizedBox(width: 6),
              Text('Bergabung sejak $joined',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.75))),
              if (user.phone != null && user.phone!.isNotEmpty) ...[
                const SizedBox(width: 14),
                Icon(Icons.phone_outlined,
                    size: 13, color: Colors.white.withOpacity(0.75)),
                const SizedBox(width: 6),
                Text(user.phone!,
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.75))),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(Icons.stars_outlined, '${_member!.points}',
              'Poin', AppColors.warning),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(Icons.history_outlined, '$_sessionCount',
              'Sesi Selesai', AppColors.primary),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return GZCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
      ]),
    );
  }

  // ── Kartu Membership ────────────────────────────────────────────────────
  Widget _buildMembershipCard() {
    final tier = _member!.tier;
    final color = _tierColor(tier);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.22), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_tierIcon(tier), color: color, size: 20),
                  const SizedBox(width: 8),
                  Text('Kartu Member $tier',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
              const Icon(Icons.wifi, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 22),
          Text(_member!.memberCode,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PEMILIK',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(_member!.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('TOTAL BELANJA',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    _rupiah(_member!.totalSpend),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _rupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write('.');
    }
    return 'Rp$buf';
  }

  Widget _buildNoMemberCard() {
    return GZCard(
      borderColor: AppColors.warning.withOpacity(0.3),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppColors.warning, size: 22),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Akun kamu belum terhubung ke data member, jadi belum bisa kumpulkan poin. Hubungi kasir untuk menghubungkan.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ]),
    );
  }

  // ── Info akun ────────────────────────────────────────────────────────────
  Widget _buildInfoCard(UserModel user) {
    return GZCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Informasi Akun',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: () => _showEditProfileDialog(user),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Edit',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const GZDivider(margin: EdgeInsets.zero),
          _infoRow(Icons.person_outline, 'Nama Lengkap', user.fullName),
          const GZDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
          _infoRow(Icons.alternate_email, 'Username', user.username),
          const GZDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
          _infoRow(Icons.phone_outlined, 'No. Telepon',
              (user.phone == null || user.phone!.isEmpty) ? '-' : user.phone!),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  // ── Menu ─────────────────────────────────────────────────────────────────
  Widget _buildMenuCard(UserModel user) {
    return GZCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _menuItem(
            icon: Icons.person_outline,
            label: 'Edit Profil',
            color: AppColors.primary,
            onTap: () => _showEditProfileDialog(user),
          ),
          const GZDivider(margin: EdgeInsets.zero),
          _menuItem(
            icon: Icons.lock_reset_outlined,
            label: 'Ganti Password',
            color: AppColors.primary,
            onTap: _showChangePasswordDialog,
          ),
          const GZDivider(margin: EdgeInsets.zero),
          _menuItem(
            icon: Icons.info_outline,
            label: 'Tentang Aplikasi',
            color: AppColors.textSecondary,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationLegalese: '© 2026 Gaming Zone',
              );
            },
          ),
          const GZDivider(margin: EdgeInsets.zero),
          _menuItem(
            icon: Icons.logout_rounded,
            label: 'Keluar',
            color: AppColors.danger,
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              color: label == 'Keluar' ? AppColors.danger : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
    );
  }
}
