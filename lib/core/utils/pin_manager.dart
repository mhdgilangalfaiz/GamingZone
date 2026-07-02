import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'password_hasher.dart';

/// Helper untuk fitur "Kunci Dashboard" — PIN 4-6 digit yang harus
/// dimasukkan setiap kali aplikasi kasir dibuka, sebelum Dashboard Admin
/// (data pendapatan, transaksi, dll) bisa dilihat.
///
/// PIN disimpan dalam bentuk hash (pakai PasswordHasher yang sama dengan
/// password akun), TIDAK PERNAH dalam bentuk teks biasa.
class PinManager {
  PinManager._();

  /// Apakah fitur kunci PIN sedang aktif.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefAppLockEnabled) ?? false;
  }

  /// Apakah PIN sudah pernah dibuat sebelumnya.
  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(AppConstants.prefAppLockPinHash);
    return hash != null && hash.isNotEmpty;
  }

  /// Simpan PIN baru (dipakai saat setup awal atau ganti PIN), sekaligus
  /// mengaktifkan kunci.
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.prefAppLockPinHash, PasswordHasher.hash(pin));
    await prefs.setBool(AppConstants.prefAppLockEnabled, true);
  }

  /// Verifikasi PIN yang diinput terhadap hash tersimpan.
  static Future<bool> verify(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString(AppConstants.prefAppLockPinHash);
    if (hash == null) return false;
    return PasswordHasher.verify(pin, hash);
  }

  /// Matikan kunci PIN sepenuhnya (hapus PIN tersimpan).
  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefAppLockPinHash);
    await prefs.setBool(AppConstants.prefAppLockEnabled, false);
  }
}
