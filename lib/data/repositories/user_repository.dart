import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/password_hasher.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<UserModel?> login(String username, String password) async {
    final rows = await _db.query(
      AppConstants.tableUsers,
      where: 'username = ? AND is_active = 1',
      whereArgs: [username.trim().toLowerCase()],
    );
    if (rows.isEmpty) return null;
    final user = UserModel.fromMap(rows.first);
    if (!PasswordHasher.verify(password, user.passwordHash)) return null;
    return user;
  }

  // ── Get by ID ──────────────────────────────────────────────────────────────
  Future<UserModel?> getById(int id) async {
    final rows = await _db.query(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  // ── Get All (admin only) ───────────────────────────────────────────────────
  Future<List<UserModel>> getAll({String? role}) async {
    final rows = await _db.query(
      AppConstants.tableUsers,
      where: role != null ? 'role = ?' : null,
      whereArgs: role != null ? [role] : null,
      orderBy: 'role ASC, full_name ASC',
    );
    return rows.map(UserModel.fromMap).toList();
  }

  // ── Insert ─────────────────────────────────────────────────────────────────
  Future<int> insert(UserModel user) async {
    final map = user.toMap();
    map.remove('id');
    return _db.insert(AppConstants.tableUsers, map);
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<void> update(UserModel user) async {
    await _db.update(
      AppConstants.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ── Update Password ────────────────────────────────────────────────────────
  Future<void> updatePassword(int userId, String newPassword) async {
    await _db.update(
      AppConstants.tableUsers,
      {'password_hash': PasswordHasher.hash(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ── Toggle Active ──────────────────────────────────────────────────────────
  Future<void> toggleActive(int userId, bool active) async {
    await _db.update(
      AppConstants.tableUsers,
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> delete(int userId) async {
    await _db.delete(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ── Check username exists ──────────────────────────────────────────────────
  Future<bool> usernameExists(String username, {int? excludeId}) async {
    final rows = await _db.query(
      AppConstants.tableUsers,
      where: excludeId != null
          ? 'username = ? AND id != ?'
          : 'username = ?',
      whereArgs: excludeId != null
          ? [username.trim().toLowerCase(), excludeId]
          : [username.trim().toLowerCase()],
    );
    return rows.isNotEmpty;
  }
}
