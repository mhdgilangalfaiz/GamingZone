import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

/// Pastikan user sudah login sebelum melanjutkan aksi yang butuh akun
/// (mis. booking konsol, order snack).
///
/// Kalau sudah login, langsung return `true`. Kalau belum, buka
/// [LoginScreen] (yang juga punya link ke halaman Daftar) dan tunggu
/// sampai ditutup, lalu cek ulang status login-nya.
///
/// Contoh pakai:
/// ```dart
/// final ok = await ensureLoggedIn(context, message: 'Masuk dulu untuk booking');
/// if (!ok) return;
/// // lanjut proses booking...
/// ```
Future<bool> ensureLoggedIn(BuildContext context, {String? message}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn) return true;

  if (message != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );

  if (!context.mounted) return false;
  return context.read<AuthProvider>().isLoggedIn;
}
