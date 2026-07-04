import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../user/user_navigation.dart';

/// Splash screen yang tampil ±4 detik saat aplikasi pertama kali dibuka,
/// menampilkan logo Gaming Zone sebelum masuk ke aplikasi.
///
/// PENTING: Halaman utama default untuk SEMUA orang (baik pengunjung baru
/// maupun admin) adalah UserNavigation (Dashboard User / Portal Pelanggan)
/// — BUKAN Dashboard Admin/Kasir. Ini supaya data kasir (pendapatan,
/// transaksi, dll) tidak langsung terlihat oleh siapa pun yang buka
/// aplikasi.
///
/// Dashboard Admin/Kasir (MainNavigation) hanya bisa diakses lewat
/// LoginScreen dengan akun berrole 'admin' yang sudah ada di database
/// (lihat tombol "Masuk" di tab Profil / saat mencoba booking).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward();

    // Total durasi splash screen: 4 detik (di antara 3-5 detik), lalu
    // pindah otomatis ke Dashboard User — tanpa login.
    _navTimer = Timer(const Duration(seconds: 4), _goToHome);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, anim, __) => const UserNavigation(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fade,
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
