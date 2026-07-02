import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

/// Provider yang mengecek setiap menit apakah ada sesi overtime
class OvertimeProvider extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();

  Timer? _timer;
  List<TransactionModel> _overtimeSessions = [];
  List<TransactionModel> _activeSessions = [];

  List<TransactionModel> get overtimeSessions => _overtimeSessions;
  List<TransactionModel> get activeSessions => _activeSessions;

  bool isOvertime(int? consoleId) {
    if (consoleId == null) return false;
    return _overtimeSessions.any((t) => t.consoleId == consoleId);
  }

  TransactionModel? getSession(int? consoleId) {
    if (consoleId == null) return null;
    try {
      return _activeSessions.firstWhere((t) => t.consoleId == consoleId);
    } catch (_) {
      return null;
    }
  }

  void startChecking() {
    _checkNow();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkNow());
  }

  void stopChecking() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkNow() async {
    try {
      final active = await _repo.getActive();
      final now = DateTime.now();
      _activeSessions = active;
      _overtimeSessions = active.where((tx) {
        if (tx.endTime == null) return false;
        return now.isAfter(tx.endTime!);
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() => _checkNow();

  /// Tandai sesi selesai (close session)
  Future<void> closeSession({
    required int transactionId,
    required int consoleId,
  }) async {
    await _repo.forceCloseSession(
      transactionId: transactionId,
      consoleId: consoleId,
    );
    await _checkNow();
  }

  /// Perpanjang waktu sesi — mengembalikan transaksi perpanjangan (untuk struk)
  Future<TransactionModel> extendSession({
    required TransactionModel originalTx,
    required int extraMinutes,
    required int extraCost,
    required DateTime newEndTime,
  }) async {
    final extTx = await _repo.extendSession(
      originalTx: originalTx,
      extraMinutes: extraMinutes,
      extraCost: extraCost,
      newEndTime: newEndTime,
    );
    await _checkNow();
    return extTx;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
