import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pin_manager.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import '../auth/pin_lock_screen.dart';
import '../main_navigation.dart';
import 'manage_accounts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxCtrl = TextEditingController(text: '10');
  final _pointValueCtrl = TextEditingController(text: '1000');
  final _pointRedeemCtrl = TextEditingController(text: '10000');

  bool _taxEnabled = false;
  bool _lockEnabled = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _confirmLogout(BuildContext context) {
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
            onPressed: () async {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              // Kembali ke Dashboard — tidak perlu login lagi untuk pakai
              // aplikasi kasir, login hanya untuk Portal Pelanggan.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Keluar',
                style: TextStyle(color: AppColors.danger,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Kunci Dashboard (PIN) ───────────────────────────────────────────────
  Future<void> _onToggleLock(bool value) async {
    if (value) {
      // Aktifkan → minta buat PIN baru dulu.
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PinLockScreen(
            mode: PinLockMode.setup,
            onSuccess: (ctx) => Navigator.pop(ctx, true),
          ),
        ),
      );
      final enabled = await PinManager.isEnabled();
      if (mounted) setState(() => _lockEnabled = enabled);
      if (enabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kunci Dashboard diaktifkan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Matikan Kunci PIN?',
              style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
              'Dashboard akan langsung terbuka tanpa PIN setiap kali aplikasi dibuka.',
              style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Matikan',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await PinManager.disable();
        if (mounted) setState(() => _lockEnabled = false);
      }
    }
  }

  Future<void> _onChangePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinLockScreen(
          mode: PinLockMode.change,
          onSuccess: (ctx) => Navigator.pop(ctx),
        ),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN berhasil diubah'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _onLockNow() {
    // Langsung minta PIN & bersihkan semua halaman di atasnya, sehingga
    // Dashboard tidak bisa diakses (misal lewat tombol back) sampai PIN
    // dimasukkan lagi. Berguna sebelum menyerahkan HP ke pelanggan.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PinLockScreen(
          mode: PinLockMode.unlock,
          canCancel: false,
          onSuccess: (ctx) => Navigator.of(ctx).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
          ),
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final lockEnabled = await PinManager.isEnabled();
    setState(() {
      _lockEnabled = lockEnabled;
      _storeNameCtrl.text =
          prefs.getString(AppConstants.prefStoreName) ?? 'Gaming Zone';
      _ownerNameCtrl.text = prefs.getString(AppConstants.prefOwnerName) ?? '';
      _addressCtrl.text = prefs.getString(AppConstants.prefStoreAddress) ?? '';
      _phoneCtrl.text = prefs.getString(AppConstants.prefStorePhone) ?? '';
      _taxEnabled = prefs.getBool(AppConstants.prefTaxEnabled) ?? false;
      _taxCtrl.text =
          (prefs.getDouble(AppConstants.prefTaxPercent) ?? 10).toString();
      _pointValueCtrl.text =
          (prefs.getInt(AppConstants.prefPointValue) ?? 1000).toString();
      _pointRedeemCtrl.text =
          (prefs.getInt(AppConstants.prefPointRedeem) ?? 10000).toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          AppConstants.prefStoreName, _storeNameCtrl.text.trim());
      await prefs.setString(
          AppConstants.prefOwnerName, _ownerNameCtrl.text.trim());
      await prefs.setString(
          AppConstants.prefStoreAddress, _addressCtrl.text.trim());
      await prefs.setString(
          AppConstants.prefStorePhone, _phoneCtrl.text.trim());
      await prefs.setBool(AppConstants.prefTaxEnabled, _taxEnabled);
      await prefs.setDouble(
          AppConstants.prefTaxPercent, double.tryParse(_taxCtrl.text) ?? 10);
      await prefs.setInt(AppConstants.prefPointValue,
          int.tryParse(_pointValueCtrl.text) ?? 1000);
      await prefs.setInt(AppConstants.prefPointRedeem,
          int.tryParse(_pointRedeemCtrl.text) ?? 10000);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _taxCtrl.dispose();
    _pointValueCtrl.dispose();
    _pointRedeemCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.accent),
                  )
                : const Icon(Icons.save_outlined, color: AppColors.accent),
            label: const Text('Simpan',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Informasi Toko',
                    icon: Icons.store_outlined,
                    color: AppColors.primary,
                    children: [
                      GZTextField(
                        label: 'Nama Toko*',
                        controller: _storeNameCtrl,
                        prefixIcon: Icons.storefront_outlined,
                      ),
                      const SizedBox(height: 12),
                      GZTextField(
                        label: 'Nama Pemilik',
                        controller: _ownerNameCtrl,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      GZTextField(
                        label: 'Alamat',
                        controller: _addressCtrl,
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      GZTextField(
                        label: 'Nomor Telepon',
                        controller: _phoneCtrl,
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Pajak & Biaya',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.warning,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktifkan Pajak',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Pajak akan dihitung pada setiap transaksi',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _taxEnabled,
                            onChanged: (v) => setState(() => _taxEnabled = v),
                          ),
                        ],
                      ),
                      if (_taxEnabled) ...[
                        const GZDivider(),
                        GZTextField(
                          label: 'Persentase Pajak (%)',
                          controller: _taxCtrl,
                          prefixIcon: Icons.percent,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Program Poin Member',
                    icon: Icons.stars_outlined,
                    color: AppColors.accent,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GZTextField(
                              label: 'Transaksi per Poin (Rp)',
                              controller: _pointValueCtrl,
                              prefixIcon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GZTextField(
                              label: 'Nilai Tukar Poin (Rp)',
                              controller: _pointRedeemCtrl,
                              prefixIcon: Icons.redeem_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPointPreview(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── Akun yang sedang login ─────────────────────────────
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) {
                      final user = auth.currentUser;
                      if (user == null) return const SizedBox.shrink();
                      return GZCard(
                        borderColor: AppColors.primary.withOpacity(0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppColors.textPrimary)),
                                      Text('@${user.username}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                GZBadge(
                                  label: user.roleLabel,
                                  color: user.isAdmin ? AppColors.warning : AppColors.primary,
                                ),
                              ],
                            ),
                            if (user.isAdmin) ...[
                              const GZDivider(),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageAccountsScreen()),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.manage_accounts_outlined,
                                        color: AppColors.primary, size: 18),
                                    SizedBox(width: 8),
                                    Text('Kelola Akun',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                            const GZDivider(),
                            GestureDetector(
                              onTap: () => _confirmLogout(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.logout_rounded,
                                      color: AppColors.danger, size: 18),
                                  SizedBox(width: 8),
                                  Text('Keluar dari Akun',
                                      style: TextStyle(
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Keamanan Aplikasi',
                    icon: Icons.lock_outline_rounded,
                    color: AppColors.danger,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kunci Dashboard dengan PIN',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Minta PIN setiap kali aplikasi dibuka, sebelum Dashboard terlihat',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _lockEnabled,
                            onChanged: _onToggleLock,
                          ),
                        ],
                      ),
                      if (_lockEnabled) ...[
                        const GZDivider(),
                        GestureDetector(
                          onTap: _onChangePin,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pin_outlined,
                                  color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Ubah PIN',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                        const GZDivider(),
                        GestureDetector(
                          onTap: _onLockNow,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_clock_outlined,
                                  color: AppColors.warning, size: 18),
                              SizedBox(width: 8),
                              Text('Kunci Sekarang',
                                  style: TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Tentang Aplikasi',
                    icon: Icons.info_outline,
                    color: AppColors.textSecondary,
                    children: [
                      _buildInfoRow('Nama Aplikasi', AppConstants.appName),
                      const GZDivider(
                          margin: EdgeInsets.symmetric(vertical: 8)),
                      _buildInfoRow('Versi', AppConstants.appVersion),
                      const GZDivider(
                          margin: EdgeInsets.symmetric(vertical: 8)),
                      _buildInfoRow('Tagline', AppConstants.appTagline),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return GZCard(
      borderColor: color.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 16)),
            ],
          ),
          const GZDivider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildPointPreview() {
    final pointValue = int.tryParse(_pointValueCtrl.text) ?? 1000;
    final pointRedeem = int.tryParse(_pointRedeemCtrl.text) ?? 10000;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 14),
              SizedBox(width: 6),
              Text('Preview Perhitungan Poin',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Setiap transaksi ${CurrencyFormatter.toRupiah(pointValue)} = 1 poin',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            '100 poin = ${CurrencyFormatter.toRupiah(pointRedeem ~/ 100 * 100)} diskon',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
