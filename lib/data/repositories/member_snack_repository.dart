import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/member_model.dart';
import '../models/snack_model.dart';

// ════════════════════════════════════════════════════════════
//  Member Repository
// ════════════════════════════════════════════════════════════
class MemberRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<MemberModel>> getAll({bool activeOnly = true}) async {
    final rows = await _db.query(
      AppConstants.tableMembers,
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name ASC',
    );
    return rows.map(MemberModel.fromMap).toList();
  }

  Future<MemberModel?> getById(int id) async {
    final rows = await _db.query(
      AppConstants.tableMembers,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : MemberModel.fromMap(rows.first);
  }

  Future<MemberModel?> getByCode(String code) async {
    final rows = await _db.query(
      AppConstants.tableMembers,
      where: 'member_code = ?',
      whereArgs: [code],
    );
    return rows.isEmpty ? null : MemberModel.fromMap(rows.first);
  }

  Future<List<MemberModel>> search(String query) async {
    final rows = await _db.query(
      AppConstants.tableMembers,
      where:
          "is_active = 1 AND (name LIKE ? OR phone LIKE ? OR member_code LIKE ?)",
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(MemberModel.fromMap).toList();
  }

  Future<String> generateCode() async {
    final rows = await _db
        .rawQuery('SELECT COUNT(*) as cnt FROM ${AppConstants.tableMembers}');
    final count = (rows.first['cnt'] as int? ?? 0) + 1;
    return 'MBR${count.toString().padLeft(5, '0')}';
  }

  Future<int> insert(MemberModel member) async {
    final now = DateTime.now();
    return _db.insert(
      AppConstants.tableMembers,
      member.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  Future<int> update(MemberModel member) async {
    return _db.update(
      AppConstants.tableMembers,
      member.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.update(
      AppConstants.tableMembers,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getSummary() async {
    final rows = await _db.rawQuery('''
      SELECT
        COUNT(*)                        AS total,
        COALESCE(SUM(total_spend), 0)   AS total_spend,
        COALESCE(SUM(points), 0)        AS total_points
      FROM ${AppConstants.tableMembers}
      WHERE is_active = 1
    ''');
    return rows.isNotEmpty ? Map<String, dynamic>.from(rows.first) : {};
  }
}

// ════════════════════════════════════════════════════════════
//  Snack Repository
// ════════════════════════════════════════════════════════════
class SnackRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<SnackModel>> getAll({
    bool activeOnly = true,
    String? category,
  }) async {
    String? where;
    List<dynamic>? args;

    if (activeOnly && category != null) {
      where = 'is_active = ? AND category = ?';
      args = [1, category];
    } else if (activeOnly) {
      where = 'is_active = ?';
      args = [1];
    } else if (category != null) {
      where = 'category = ?';
      args = [category];
    }

    final rows = await _db.query(
      AppConstants.tableSnacks,
      where: where,
      whereArgs: args,
      orderBy: 'category ASC, name ASC',
    );
    return rows.map(SnackModel.fromMap).toList();
  }

  Future<SnackModel?> getById(int id) async {
    final rows = await _db.query(
      AppConstants.tableSnacks,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : SnackModel.fromMap(rows.first);
  }

  Future<List<SnackModel>> search(String query) async {
    final rows = await _db.query(
      AppConstants.tableSnacks,
      where: "is_active = 1 AND (name LIKE ? OR code LIKE ?)",
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return rows.map(SnackModel.fromMap).toList();
  }

  Future<List<String>> getCategories() async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT category FROM ${AppConstants.tableSnacks}
      WHERE is_active = 1 ORDER BY category ASC
    ''');
    return rows.map((r) => r['category'] as String).toList();
  }

  Future<String> generateCode() async {
    final rows = await _db
        .rawQuery('SELECT COUNT(*) as cnt FROM ${AppConstants.tableSnacks}');
    final count = (rows.first['cnt'] as int? ?? 0) + 1;
    return 'SNK-${count.toString().padLeft(3, '0')}';
  }

  Future<int> insert(SnackModel snack) async {
    final now = DateTime.now();
    return _db.insert(
      AppConstants.tableSnacks,
      snack.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  Future<int> update(SnackModel snack) async {
    return _db.update(
      AppConstants.tableSnacks,
      snack.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [snack.id],
    );
  }

  Future<int> updateStock(int id, int stockDelta) async {
    return _db.rawUpdate('''
      UPDATE ${AppConstants.tableSnacks}
      SET stock = MAX(0, stock + ?), updated_at = datetime('now','localtime')
      WHERE id = ?
    ''', [stockDelta, id]);
  }

  Future<int> delete(int id) async {
    return _db.update(
      AppConstants.tableSnacks,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<SnackModel>> getLowStock({int threshold = 5}) async {
    final rows = await _db.query(
      AppConstants.tableSnacks,
      where: 'is_active = 1 AND stock <= ?',
      whereArgs: [threshold],
      orderBy: 'stock ASC',
    );
    return rows.map(SnackModel.fromMap).toList();
  }
}
