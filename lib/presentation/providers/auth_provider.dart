import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// AuthProvider — mengelola sesi login untuk SATU form login yang dipakai
/// bersama oleh admin maupun user biasa (username & password dari tabel
/// `users` yang sama).
///
/// Halaman utama default aplikasi adalah Dashboard User (UserNavigation),
/// bisa dibrowse tanpa login. Begitu ada aksi yang butuh akun (booking,
/// order snack, buka tab Profil) atau admin mau masuk ke Dashboard
/// Admin/Kasir, baru diarahkan ke LoginScreen.
///
/// - Login sukses & role == 'admin' → Dashboard Admin/Kasir (MainNavigation)
/// - Login sukses & role == 'user'  → tetap di Dashboard User, status jadi
///   "sudah login"
///
/// Sesi TIDAK disimpan permanen — setiap kali aplikasi dibuka ulang, tidak
/// ada user yang login (state selalu kosong saat splash screen), jadi
/// admin harus login ulang tiap kali mau ke Dashboard Admin.
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
