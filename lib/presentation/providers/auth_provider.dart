import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// AuthProvider — mengelola sesi login untuk fitur "Portal Pelanggan".
///
/// PENTING: Dashboard/kasir (MainNavigation) TIDAK memerlukan login sama
/// sekali — aplikasi selalu terbuka langsung ke Dashboard tanpa role apa
/// pun aktif (device toko/kasir sendiri, tidak perlu autentikasi).
///
/// Login di sini hanya dipakai untuk "Portal Pelanggan" (booking & order
/// snack mandiri oleh customer) yang diakses lewat tombol terpisah dari
/// Dashboard. Sesi TIDAK disimpan permanen — setiap kali aplikasi dibuka
/// ulang, tidak ada user yang login (sesuai desain: state selalu kosong
/// saat splash screen).
class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();

  UserModel? _currentUser;
  String? _lastError;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get lastError => _lastError;

  /// Login dengan username & password terhadap database.
  /// Return true jika berhasil, false jika username/password salah.
  Future<bool> login(String username, String password) async {
    _lastError = null;
    final user = await _userRepo.login(username.trim(), password);
    if (user == null) {
      _lastError = 'Username atau password salah';
      notifyListeners();
      return false;
    }
    _currentUser = user;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Refresh data user saat ini dari database (mis. setelah edit profil).
  Future<void> refreshCurrentUser() async {
    if (_currentUser?.id == null) return;
    final user = await _userRepo.getById(_currentUser!.id!);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }
}
