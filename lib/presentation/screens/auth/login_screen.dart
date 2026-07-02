import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import '../main_navigation.dart';
import '../user/user_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.login(_usernameCtrl.text, _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      setState(() => _errorText = auth.lastError ?? 'Login gagal');
      return;
    }

    final destination = auth.isAdmin
        ? const MainNavigation()
        : const UserNavigation();

    // Dashboard (MainNavigation) tetap jadi root paling bawah — login di
    // sini cuma "menumpuk" Portal Pelanggan di atasnya, supaya logout bisa
    // kembali ke Dashboard tanpa perlu login lagi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXL, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Header
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.glowPurple,
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sports_esports_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masuk untuk melanjutkan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorText != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.4)),
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
                    label: 'Username',
                    controller: _usernameCtrl,
                    prefixIcon: Icons.person_outline,
                    keyboardType: TextInputType.text,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  GZTextField(
                    label: 'Password',
                    controller: _passwordCtrl,
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),
                  GZButton(
                    label: 'Masuk',
                    icon: Icons.login_rounded,
                    isLoading: _isLoading,
                    width: double.infinity,
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            );
                          },
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                        children: const [
                          TextSpan(text: 'Belum punya akun? '),
                          TextSpan(
                            text: 'Daftar di sini',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
