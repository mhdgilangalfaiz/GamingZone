import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pin_manager.dart';

enum PinLockMode { setup, unlock, change }

/// Layar PIN untuk mengunci Dashboard Admin.
///
/// - [PinLockMode.setup]  : buat PIN baru pertama kali (minta 2x input).
/// - [PinLockMode.change] : sama seperti setup, dipakai untuk ganti PIN.
/// - [PinLockMode.unlock] : minta PIN yang sudah tersimpan untuk masuk.
///
/// Saat sukses, [onSuccess] dipanggil. Untuk mode unlock yang dipakai
/// sebagai gerbang wajib (tidak boleh diskip), set [canCancel] = false
/// supaya tombol back disembunyikan/dicegah.
class PinLockScreen extends StatefulWidget {
  final PinLockMode mode;
  final bool canCancel;
  /// Dipanggil dengan BuildContext milik PinLockScreen sendiri (selalu
  /// valid/mounted saat dipanggil) — pakai ini untuk navigasi, jangan
  /// pakai context dari layar pemanggil karena bisa saja sudah di-dispose.
  final void Function(BuildContext context)? onSuccess;
  final String? title;
  final String? subtitle;

  const PinLockScreen({
    super.key,
    required this.mode,
    this.canCancel = true,
    this.onSuccess,
    this.title,
    this.subtitle,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  static const int _pinLength = 6;

  String _input = '';
  String? _firstEntry; // dipakai saat setup/change (konfirmasi ke-2)
  String? _errorText;
  bool _isChecking = false;
  bool _isConfirmStep = false;

  bool get _isSetupFlow =>
      widget.mode == PinLockMode.setup || widget.mode == PinLockMode.change;

  String get _headline {
    if (widget.title != null) return widget.title!;
    if (_isSetupFlow) {
      return _isConfirmStep ? 'Ulangi PIN Baru' : 'Buat PIN Dashboard';
    }
    return 'Masukkan PIN';
  }

  String get _subheadline {
    if (widget.subtitle != null) return widget.subtitle!;
    if (_isSetupFlow) {
      return _isConfirmStep
          ? 'Masukkan sekali lagi untuk konfirmasi'
          : 'PIN ini akan diminta setiap kali Dashboard dibuka';
    }
    return 'PIN diperlukan untuk membuka Dashboard';
  }

  void _onKeyTap(String digit) {
    if (_isChecking) return;
    if (_input.length >= _pinLength) return;
    setState(() {
      _input += digit;
      _errorText = null;
    });
    if (_input.length == _pinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_isChecking || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _handleComplete() async {
    if (_isSetupFlow) {
      if (!_isConfirmStep) {
        // Simpan entry pertama, minta konfirmasi.
        setState(() {
          _firstEntry = _input;
          _input = '';
          _isConfirmStep = true;
        });
        return;
      }
      // Tahap konfirmasi.
      if (_input != _firstEntry) {
        setState(() {
          _errorText = 'PIN tidak sama, coba lagi dari awal';
          _input = '';
          _firstEntry = null;
          _isConfirmStep = false;
        });
        HapticFeedback.heavyImpact();
        return;
      }
      setState(() => _isChecking = true);
      await PinManager.setPin(_input);
      if (!mounted) return;
      setState(() => _isChecking = false);
      widget.onSuccess?.call(context);
      return;
    }

    // Mode unlock.
    setState(() => _isChecking = true);
    final ok = await PinManager.verify(_input);
    if (!mounted) return;
    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isChecking = false;
        _errorText = 'PIN salah, coba lagi';
        _input = '';
      });
      return;
    }
    setState(() => _isChecking = false);
    widget.onSuccess?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canCancel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: widget.canCancel
            ? AppBar(backgroundColor: AppColors.background, elevation: 0)
            : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.glowPurple,
                          blurRadius: 20,
                          spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  _headline,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subheadline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),
                _buildDots(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 20,
                  child: _errorText != null
                      ? Text(
                          _errorText!,
                          style: const TextStyle(
                              color: AppColors.dangerLight, fontSize: 13),
                        )
                      : null,
                ),
                const Spacer(),
                _buildKeypad(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        final filled = i < _input.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: filled ? AppColors.primary : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 68, height: 68);
              if (key == 'back') {
                return _KeypadButton(
                  onTap: _onBackspace,
                  child: const Icon(Icons.backspace_outlined,
                      color: AppColors.textSecondary, size: 22),
                );
              }
              return _KeypadButton(
                onTap: () => _onKeyTap(key),
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _KeypadButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        child: child,
      ),
    );
  }
}
