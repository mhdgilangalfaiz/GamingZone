import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/transaction_item_model.dart';

class TransactionRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── Generate Invoice No ────────────────────────────────────────────────────
  /// Menggunakan timestamp milidetik agar dijamin unik walau ada beberapa
  /// transaksi dibuat dalam waktu sangat berdekatan (mencegah duplikat
  /// invoice_no yang menyebabkan insert silently fail karena UNIQUE constraint).
  Future<String> generateInvoiceNo() async {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final uniqueSuffix =
        (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'GZ$date$uniqueSuffix';
  }

  // ── Start Rental ───────────────────────────────────────────────────────────
  Future<int> startRental(TransactionModel tx) async {
    return _db.transaction((txn) async {
      final id = await txn.insert(
        AppConstants.tableTransactions,
        tx.toMap(),
      );
      // Update console status → playing
      if (tx.consoleId != null) {
        await txn.update(
          AppConstants.tableConsoles,
          {'status': 'playing', 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [tx.consoleId],
        );
      }
      return id;
    });
  }

  // ── Complete Rental ────────────────────────────────────────────────────────
  Future<void> completeRental({
    required int transactionId,
    required int consoleId,
    required DateTime endTime,
    required int durationMinutes,
    required int rentalCost,
    required int snackCost,
    required int discount,
    required int tax,
    required int totalCost,
    required String paymentMethod,
    required int paymentAmount,
    required int changeAmount,
    required int pointsEarned,
    required int pointsRedeemed,
    required List<CartItem> cartItems,
    int? memberId,
  }) async {
    await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // Update transaction
      await txn.update(
        AppConstants.tableTransactions,
        {
          'end_time': endTime.toIso8601String(),
          'duration_minutes': durationMinutes,
          'rental_cost': rentalCost,
          'snack_cost': snackCost,
          'discount': discount,
          'tax': tax,
          'total_cost': totalCost,
          'payment_method': paymentMethod,
          'payment_amount': paymentAmount,
          'change_amount': changeAmount,
          'points_earned': pointsEarned,
          'points_redeemed': pointsRedeemed,
          'status': 'completed',
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // Insert cart items as transaction items
      for (final item in cartItems) {
        await txn.insert(AppConstants.tableTransactionItems, {
          'transaction_id': transactionId,
          'item_type': item.itemType,
          'item_id': item.itemId,
          'item_name': item.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'subtotal': item.subtotal,
          'created_at': now,
        });

        // Kurangi stok snack
        if (item.itemType == 'snack') {
          await txn.rawUpdate('''
            UPDATE ${AppConstants.tableSnacks}
            SET stock = stock - ?, updated_at = ?
            WHERE id = ?
          ''', [item.quantity, now, item.itemId]);
        }
      }

      // Update console status → available
      await txn.update(
        AppConstants.tableConsoles,
        {'status': 'available', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [consoleId],
      );

      // Update member points & total spend
      if (memberId != null) {
        final netPoints = pointsEarned - pointsRedeemed;
        await txn.rawUpdate('''
          UPDATE ${AppConstants.tableMembers}
          SET points      = MAX(0, points + ?),
              total_spend = total_spend + ?,
              updated_at  = ?
          WHERE id = ?
        ''', [netPoints, totalCost, now, memberId]);

        // Log point history
        if (pointsEarned > 0) {
          await txn.insert(AppConstants.tableMemberPoints, {
            'member_id': memberId,
            'transaction_id': transactionId,
            'points': pointsEarned,
            'type': 'earn',
            'note': 'Transaksi selesai',
            'created_at': now,
          });
        }
        if (pointsRedeemed > 0) {
          await txn.insert(AppConstants.tableMemberPoints, {
            'member_id': memberId,
            'transaction_id': transactionId,
            'points': -pointsRedeemed,
            'type': 'redeem',
            'note': 'Penukaran poin',
            'created_at': now,
          });
        }
      }
    });
  }

  // ── Check-in Booking (bayar & mulai sesi) ───────────────────────────────
  /// Dipanggil saat user yang booking-nya sudah di-approve datang ke toko.
  /// Di sinilah pembayaran benar-benar dikumpulkan — jam mulai/selesai
  /// direset ke SEKARANG (durasi tetap sama seperti yang diminta user),
  /// supaya sesi bermain dihitung dari saat mereka benar-benar mulai main.
  Future<void> checkinBooking({
    required int transactionId,
    required int consoleId,
    required int durationMinutes,
    required String paymentMethod,
    required int paymentAmount,
    required int changeAmount,
  }) async {
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: durationMinutes));
    await _db.transaction((txn) async {
      await txn.update(
        AppConstants.tableTransactions,
        {
          'start_time': now.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'status': 'active',
          'payment_method': paymentMethod,
          'payment_amount': paymentAmount,
          'change_amount': changeAmount,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      await txn.update(
        AppConstants.tableConsoles,
        {'status': 'playing', 'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [consoleId],
      );
    });
  }

  // ── Cancel Rental ──────────────────────────────────────────────────────────
  Future<void> cancelRental(int transactionId, int consoleId) async {
    await _db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      await txn.update(
        AppConstants.tableTransactions,
        {'status': 'cancelled', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      await txn.update(
        AppConstants.tableConsoles,
        {'status': 'available', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [consoleId],
      );
    });
  }

  // ── Get Active Transaction by Console ─────────────────────────────────────
  Future<TransactionModel?> getActiveByConsole(int consoleId) async {
    final rows = await _db.rawQuery('''
      SELECT t.*, c.name as console_name, m.name as member_name
      FROM ${AppConstants.tableTransactions} t
      LEFT JOIN ${AppConstants.tableConsoles} c ON t.console_id = c.id
      LEFT JOIN ${AppConstants.tableMembers}  m ON t.member_id  = m.id
      WHERE t.console_id = ? AND t.status = 'active'
      LIMIT 1
    ''', [consoleId]);
    return rows.isEmpty ? null : TransactionModel.fromMap(rows.first);
  }

  // ── Get All Active ─────────────────────────────────────────────────────────
  Future<List<TransactionModel>> getActive() async {
    final rows = await _db.rawQuery('''
      SELECT t.*, c.name as console_name, m.name as member_name
      FROM ${AppConstants.tableTransactions} t
      LEFT JOIN ${AppConstants.tableConsoles} c ON t.console_id = c.id
      LEFT JOIN ${AppConstants.tableMembers}  m ON t.member_id  = m.id
      WHERE t.status = 'active'
      ORDER BY t.start_time DESC
    ''');
    return rows.map(TransactionModel.fromMap).toList();
  }

  // ── Get History ────────────────────────────────────────────────────────────
  Future<List<TransactionModel>> getHistory({
    String? dateFrom,
    String? dateTo,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    String where = "t.status != 'active'";
    final args = <dynamic>[];

    if (status != null) {
      where += ' AND t.status = ?';
      args.add(status);
    }
    if (dateFrom != null) {
      where += ' AND DATE(t.created_at) >= ?';
      args.add(dateFrom);
    }
    if (dateTo != null) {
      where += ' AND DATE(t.created_at) <= ?';
      args.add(dateTo);
    }

    final rows = await _db.rawQuery('''
      SELECT t.*, c.name as console_name, m.name as member_name
      FROM ${AppConstants.tableTransactions} t
      LEFT JOIN ${AppConstants.tableConsoles} c ON t.console_id = c.id
      LEFT JOIN ${AppConstants.tableMembers}  m ON t.member_id  = m.id
      WHERE $where
      ORDER BY t.created_at DESC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);
    return rows.map(TransactionModel.fromMap).toList();
  }

  // ── Get Transaction with Items ─────────────────────────────────────────────
  Future<TransactionModel?> getById(int id) async {
    final rows = await _db.rawQuery('''
      SELECT t.*, c.name as console_name, m.name as member_name
      FROM ${AppConstants.tableTransactions} t
      LEFT JOIN ${AppConstants.tableConsoles} c ON t.console_id = c.id
      LEFT JOIN ${AppConstants.tableMembers}  m ON t.member_id  = m.id
      WHERE t.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;

    final tx = TransactionModel.fromMap(rows.first);
    final items = await _db.query(
      AppConstants.tableTransactionItems,
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
    return tx.copyWith(items: items.map(TransactionItemModel.fromMap).toList());
  }

  // ── Dashboard Summary ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDailySummary(String date) async {
    final rows = await _db.rawQuery('''
      SELECT
        COUNT(*)                         AS total_tx,
        COALESCE(SUM(total_cost), 0)     AS total_revenue,
        COALESCE(SUM(rental_cost), 0)    AS rental_revenue,
        COALESCE(SUM(snack_cost), 0)     AS snack_revenue,
        COALESCE(AVG(duration_minutes),0) AS avg_duration
      FROM ${AppConstants.tableTransactions}
      WHERE DATE(created_at) = ? AND status = 'completed'
    ''', [date]);
    return rows.isNotEmpty ? Map<String, dynamic>.from(rows.first) : {};
  }

  Future<List<Map<String, dynamic>>> getWeeklyRevenue() async {
    return _db.rawQuery('''
      SELECT DATE(created_at) as date,
             COALESCE(SUM(total_cost), 0) as revenue
      FROM ${AppConstants.tableTransactions}
      WHERE status = 'completed'
        AND created_at >= datetime('now', '-7 days')
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTopConsoles({int limit = 5}) async {
    return _db.rawQuery('''
      SELECT c.name, c.type,
             COUNT(t.id) as usage_count,
             COALESCE(SUM(t.rental_cost), 0) as revenue
      FROM ${AppConstants.tableTransactions} t
      JOIN ${AppConstants.tableConsoles} c ON t.console_id = c.id
      WHERE t.status = 'completed'
        AND t.created_at >= datetime('now', '-30 days')
      GROUP BY t.console_id
      ORDER BY usage_count DESC
      LIMIT ?
    ''', [limit]);
  }

  // ââ Force Close Session (kasir tutup manual) ââââââââââââââââââââââââââ
  Future<void> forceCloseSession({
    required int transactionId,
    required int consoleId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _db.transaction((txn) async {
      await txn.update(
        AppConstants.tableTransactions,
        {'status': 'completed', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      await txn.update(
        AppConstants.tableConsoles,
        {'status': 'available', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [consoleId],
      );
    });
  }

  // ── Extend Session (catat sebagai transaksi tambahan terpisah) ─────────
  Future<TransactionModel> extendSession({
    required TransactionModel originalTx,
    required int extraMinutes,
    required int extraCost,
    required DateTime newEndTime,
  }) async {
    final now = DateTime.now();
    final invoiceNo = await generateInvoiceNo();

    // 1. Catat transaksi perpanjangan baru (langsung completed/lunas)
    final extTx = TransactionModel(
      invoiceNo: invoiceNo,
      consoleId: originalTx.consoleId,
      consoleName: originalTx.consoleName,
      memberId: originalTx.memberId,
      memberName: originalTx.memberName,
      rentalType: originalTx.rentalType,
      startTime: originalTx.endTime ?? now,
      endTime: newEndTime,
      durationMinutes: extraMinutes,
      rentalCost: extraCost,
      totalCost: extraCost,
      paymentMethod: originalTx.paymentMethod,
      paymentAmount: extraCost,
      status: 'completed',
      notes: 'Perpanjangan waktu dari invoice ${originalTx.invoiceNo}',
      cashierName: originalTx.cashierName,
      createdAt: now,
      updatedAt: now,
    );
    final newId = await _db.insert(
      AppConstants.tableTransactions,
      extTx.toMap()..remove('id'),
    );

    // 2. Update jam selesai & durasi total pada transaksi utama (masih aktif)
    final newTotalDuration =
        (originalTx.durationMinutes ?? 0) + extraMinutes;
    await _db.update(
      AppConstants.tableTransactions,
      {
        'end_time': newEndTime.toIso8601String(),
        'duration_minutes': newTotalDuration,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [originalTx.id],
    );

    return extTx.copyWith(id: newId);
  }


  // ââ Sync Orphan Sessions (fix data tidak sinkron) ââââââââââââââââ
  /// Tutup transaksi aktif yang konsolnya sudah berstatus available
  /// (memperbaiki data yang tidak sinkron)
  Future<void> syncOrphanSessions() async {
    // Kasus 1: transaksi masih 'active' tapi konsolnya sudah 'available'
    await _db.rawUpdate('''
      UPDATE ${AppConstants.tableTransactions}
      SET status = 'completed',
          updated_at = datetime('now','localtime')
      WHERE status = 'active'
        AND console_id IN (
          SELECT id FROM ${AppConstants.tableConsoles}
          WHERE status = 'available'
        )
    ''');

    // Kasus 2: konsol berstatus 'playing' tapi TIDAK ADA transaksi aktif
    // (data korup/manual edit) -> set konsol kembali jadi 'available'
    await _db.rawUpdate('''
      UPDATE ${AppConstants.tableConsoles}
      SET status = 'available',
          updated_at = datetime('now','localtime')
      WHERE status = 'playing'
        AND id NOT IN (
          SELECT console_id FROM ${AppConstants.tableTransactions}
          WHERE status = 'active' AND console_id IS NOT NULL
        )
    ''');
  }
}