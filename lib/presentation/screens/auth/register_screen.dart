import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_hasher.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/member_snack_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gz_widgets.dart';

/// Pendaftaran akun mandiri untuk pelanggan (role `user`).
/// Tidak perlu dibuatkan Admin — siapa pun bisa daftar sendiri di sini.
/// Setiap akun baru otomatis dibuatkan juga data Member (poin & riwayat)
/// yang terhubung lewat `member_id`.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final UserRepository _userRepo = UserRepository();
  final MemberRepository _memberRepo = MemberRepository();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final username = _usernameCtrl.text.trim().toLowerCase();

      final exists = await _userRepo.usernameExists(username);
      if (exists) {
        setState(() {
          _isLoading = false;
          _errorText = 'Username sudah dipakai, coba yang lain';
        });
        return;
      }

      final now = DateTime.now();

      // 1. Buat data Member baru (untuk poin & riwayat transaksi)
      final memberCode = await _memberRepo.generateCode();
      final memberId = await _memberRepo.insert(MemberModel(
        memberCode: memberCode,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      ));

      // 2. Buat akun login (role user), tertaut ke Member di atas
      await _userRepo.insert(UserModel(
        username: username,
        passwordHash: PasswordHasher.hash(_passwordCtrl.text),
        role: AppConstants.roleUser,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        memberId: memberId,
        createdAt: now,
        updatedAt: now,
      ));

      if (!mounted) return;

      // 3. Auto-login setelah daftar (role selalu 'user').
      final auth = context.read<AuthProvider>();
      final loggedIn = await auth.login(username, _passwordCtrl.text);

      if (!mounted) return;

      if (!loggedIn) {
        // Sangat jarang terjadi (race condition), tapi tetap ditangani.
        setState(() {
          _isLoading = false;
          _errorText = 'Akun berhasil dibuat, silakan login manual';
        });
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Gagal mendaftar, silakan coba lagi';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingXL, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buat akun untuk booking konsol & order snack sendiri',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                if (_errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      border:
                          Border.all(color: AppColors.danger.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                                color: AppColors.dangerLight, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                GZTextField(
                  label: 'Nama Lengkap',
                  controller: _nameCtrl,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                GZTextField(
                  label: 'No. HP (opsional)',
                  controller: _phoneCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                GZTextField(
                  label: 'Username',
                  controller: _usernameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                    if (v.trim().length < 4) return 'Min. 4 karakter';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Hanya huruf, angka, underscore';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                GZTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  prefixIcon: Icons.lock_outline,
                  obscure: _obscurePass,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Min. 6 karakter'
                      : null,
                ),
                const SizedBox(height: 14),
                GZTextField(
                  label: 'Konfirmasi Password',
                  controller: _confirmCtrl,
                  prefixIcon: Icons.lock_reset_outlined,
                  obscure: _obscureConfirm,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Password tidak sama' : null,
                ),
                const SizedBox(height: 24),
                GZButton(
                  label: 'Daftar',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: _isLoading,
                  width: double.infinity,
                  onPressed: _isLoading ? null : _handleRegister,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
