import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {

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
              // Kembali ke Dashboard (Portal Pelanggan cuma "menumpuk" di
              // atas Dashboard, jadi logout tinggal turun ke root).
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
    final user = auth.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar + info
            GZCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: const [
                        BoxShadow(color: AppColors.glowPurple, blurRadius: 12),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text('@${user.username}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        GZBadge(label: user.roleLabel, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu
            GZCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
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
            ),
          ],
        ),
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
