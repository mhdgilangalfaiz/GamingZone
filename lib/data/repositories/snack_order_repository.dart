import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/snack_order_model.dart';

class SnackOrderRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Generate Order No ──────────────────────────────────────────────────────
  Future<String> generateOrderNo() async {
    final now = DateTime.now();
    final ts = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$ts';
  }

  // ── Insert ─────────────────────────────────────────────────────────────────
  Future<int> insert(SnackOrderModel order) async {
    final map = order.toMap();
    map.remove('id');
    return _db.insert(AppConstants.tableSnackOrders, map);
  }

  // ── Get Pending (untuk kasir) ──────────────────────────────────────────────
  Future<List<SnackOrderModel>> getPending() async {
    final rows = await _db.query(
      AppConstants.tableSnackOrders,
      where: "status = 'pending'",
      orderBy: 'created_at ASC',
    );
    return rows.map(SnackOrderModel.fromMap).toList();
  }

  // ── Get by User ────────────────────────────────────────────────────────────
  Future<List<SnackOrderModel>> getByUser(int userId, {int limit = 20}) async {
    final rows = await _db.query(
      AppConstants.tableSnackOrders,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(SnackOrderModel.fromMap).toList();
  }

  // ── Update Status ──────────────────────────────────────────────────────────
  Future<void> updateStatus(int id, String status) async {
    await _db.update(
      AppConstants.tableSnackOrders,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Count Pending ──────────────────────────────────────────────────────────
  Future<int> countPending() async {
    final rows = await _db.rawQuery(
      "SELECT COUNT(*) as cnt FROM ${AppConstants.tableSnackOrders} WHERE status = 'pending'",
    );
    return rows.first['cnt'] as int? ?? 0;
  }
}
