import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Helper untuk hashing password dengan SHA-256 + salt acak.
/// Password TIDAK PERNAH disimpan dalam bentuk teks biasa di database.
class PasswordHasher {
  PasswordHasher._();

  static final Random _rand = Random.secure();

  static String _generateSalt([int length = 16]) {
    final bytes = List<int>.generate(length, (_) => _rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Hasilnya disimpan dalam format "salt:hash" di kolom password_hash.
  static String hash(String password, {String? salt}) {
    final s = salt ?? _generateSalt();
    final digest = sha256.convert(utf8.encode('$s:$password'));
    return '$s:${digest.toString()}';
  }

  /// Verifikasi password yang diinput user terhadap hash tersimpan.
  static bool verify(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expected = hash(password, salt: salt);
    return expected == storedHash;
  }
}
