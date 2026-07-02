import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/console_model.dart';

class ConsoleRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<List<ConsoleModel>> getAll({bool activeOnly = true}) async {
    final rows = await _db.query(
      AppConstants.tableConsoles,
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'type ASC, code ASC',
    );
    return rows.map(ConsoleModel.fromMap).toList();
  }

  Future<ConsoleModel?> getById(int id) async {
    final rows = await _db.query(
      AppConstants.tableConsoles,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : ConsoleModel.fromMap(rows.first);
  }

  Future<List<ConsoleModel>> getByStatus(String status) async {
    final rows = await _db.query(
      AppConstants.tableConsoles,
      where: 'status = ? AND is_active = ?',
      whereArgs: [status, 1],
      orderBy: 'code ASC',
    );
    return rows.map(ConsoleModel.fromMap).toList();
  }

  Future<List<ConsoleModel>> getAvailable() => getByStatus('available');

  Future<List<ConsoleModel>> getPlaying() => getByStatus('playing');

  Future<int> insert(ConsoleModel console) async {
    final now = DateTime.now();
    return _db.insert(
      AppConstants.tableConsoles,
      console.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
  }

  Future<int> update(ConsoleModel console) async {
    return _db.update(
      AppConstants.tableConsoles,
      console.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [console.id],
    );
  }

  Future<int> updateStatus(int id, String status) async {
    return _db.update(
      AppConstants.tableConsoles,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return _db.update(
      AppConstants.tableConsoles,
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getStatusSummary() async {
    final rows = await _db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM ${AppConstants.tableConsoles}
      WHERE is_active = 1
      GROUP BY status
    ''');
    final Map<String, int> summary = {
      'available': 0,
      'playing': 0,
      'reserved': 0,
      'maintenance': 0,
    };
    for (final r in rows) {
      summary[r['status'] as String] = r['count'] as int;
    }
    return summary;
  }
}
