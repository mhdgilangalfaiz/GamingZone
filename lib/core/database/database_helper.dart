import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute(_createConsolesTable);
      await txn.execute(_createMembersTable);
      await txn.execute(_createSnacksTable);
      await txn.execute(_createTransactionsTable);
      await txn.execute(_createTransactionItemsTable);
      await txn.execute(_createSettingsTable);
      await txn.execute(_createMemberPointsTable);
      await _seedInitialData(txn);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Rename kolom price_member -> price_vip (kategori member dihapus,
      // diganti jadi kategori VIP / Room AC).
      try {
        await db.execute(
            'ALTER TABLE ${AppConstants.tableConsoles} RENAME COLUMN price_member TO price_vip');
      } catch (_) {
        // Fallback untuk SQLite lama yang belum support RENAME COLUMN
        await db.execute(
            'ALTER TABLE ${AppConstants.tableConsoles} ADD COLUMN price_vip INTEGER NOT NULL DEFAULT 0');
      }

      // Reset & isi ulang data konsol sesuai daftar inventaris terbaru
      // (6x PS3, 4x PS4, 2x PS5, 2x VR, 2x Nintendo Switch).
      await db.delete(AppConstants.tableConsoles);
      await db.transaction((txn) async {
        for (final c in _seedConsoles) {
          await txn.insert(AppConstants.tableConsoles, c);
        }
      });
    }
  }

  // ── DDL Statements ─────────────────────────────────────────────────────────

  static const _createConsolesTable = '''
    CREATE TABLE ${AppConstants.tableConsoles} (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      code        TEXT    NOT NULL UNIQUE,
      name        TEXT    NOT NULL,
      type        TEXT    NOT NULL,
      status      TEXT    NOT NULL DEFAULT 'available',
      price_per_hour INTEGER NOT NULL DEFAULT 0,
      price_vip   INTEGER NOT NULL DEFAULT 0,
      description TEXT,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
    )
  ''';

  static const _createMembersTable = '''
    CREATE TABLE ${AppConstants.tableMembers} (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      member_code TEXT    NOT NULL UNIQUE,
      name        TEXT    NOT NULL,
      phone       TEXT,
      email       TEXT,
      points      INTEGER NOT NULL DEFAULT 0,
      total_spend INTEGER NOT NULL DEFAULT 0,
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
    )
  ''';

  static const _createSnacksTable = '''
    CREATE TABLE ${AppConstants.tableSnacks} (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      code        TEXT    NOT NULL UNIQUE,
      name        TEXT    NOT NULL,
      category    TEXT    NOT NULL DEFAULT 'snack',
      price       INTEGER NOT NULL DEFAULT 0,
      stock       INTEGER NOT NULL DEFAULT 0,
      unit        TEXT    NOT NULL DEFAULT 'pcs',
      is_active   INTEGER NOT NULL DEFAULT 1,
      created_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at  TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
    )
  ''';

  static const _createTransactionsTable = '''
    CREATE TABLE ${AppConstants.tableTransactions} (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_no      TEXT    NOT NULL UNIQUE,
      console_id      INTEGER REFERENCES ${AppConstants.tableConsoles}(id),
      member_id       INTEGER REFERENCES ${AppConstants.tableMembers}(id),
      rental_type     TEXT    NOT NULL DEFAULT 'Regular',
      start_time      TEXT    NOT NULL,
      end_time        TEXT,
      duration_minutes INTEGER,
      rental_cost     INTEGER NOT NULL DEFAULT 0,
      snack_cost      INTEGER NOT NULL DEFAULT 0,
      discount        INTEGER NOT NULL DEFAULT 0,
      tax             INTEGER NOT NULL DEFAULT 0,
      total_cost      INTEGER NOT NULL DEFAULT 0,
      payment_method  TEXT    NOT NULL DEFAULT 'Tunai',
      payment_amount  INTEGER NOT NULL DEFAULT 0,
      change_amount   INTEGER NOT NULL DEFAULT 0,
      points_earned   INTEGER NOT NULL DEFAULT 0,
      points_redeemed INTEGER NOT NULL DEFAULT 0,
      notes           TEXT,
      status          TEXT    NOT NULL DEFAULT 'active',
      cashier_name    TEXT    NOT NULL DEFAULT 'Admin',
      created_at      TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
      updated_at      TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
    )
  ''';

  static const _createTransactionItemsTable = '''
    CREATE TABLE ${AppConstants.tableTransactionItems} (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id  INTEGER NOT NULL REFERENCES ${AppConstants.tableTransactions}(id) ON DELETE CASCADE,
      item_type       TEXT    NOT NULL DEFAULT 'snack',
      item_id         INTEGER NOT NULL,
      item_name       TEXT    NOT NULL,
      quantity        INTEGER NOT NULL DEFAULT 1,
      unit_price      INTEGER NOT NULL DEFAULT 0,
      subtotal        INTEGER NOT NULL DEFAULT 0,
      created_at      TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
    )
  ''';

  static const _createSettingsTable = '''
    CREATE TABLE ${AppConstants.tableSettings} (
      key         TEXT PRIMARY KEY,
      value       TEXT NOT NULL,
      updated_at  TEXT NOT NULL DEFAULT (datetime('now','localtime'))
    )
  ''';

  static const _createMemberPointsTable = '''
    CREATE TABLE ${AppConstants.tableMemberPoints} (
      id              INTEGER PRIMARY KEY AUTOINCREMENT,
      member_id       INTEGER NOT NULL REFERENCES ${AppConstants.tableMembers}(id),
      transaction_id  INTEGER REFERENCES ${AppConstants.tableTransactions}(id),
      points          INTEGER NOT NULL DEFAULT 0,
      type            TEXT    NOT NULL DEFAULT 'earn',
      note            TEXT,
      created_at      TEXT    NOT NULL DEFAULT (datetime('now','localtime'))
    )
  ''';

  // ── Seed Data ──────────────────────────────────────────────────────────────

  /// Daftar inventaris konsol default.
  /// Kategori harga hanya ada 2: Reguler (outdoor) & VIP (Room AC private).
  /// Untuk PlayStation 3/4/5 tersedia kedua kategori.
  /// VR Gaming & Nintendo Switch hanya tersedia kategori VIP
  /// (price_per_hour = 0 menandakan kategori Reguler tidak tersedia).
  static final List<Map<String, dynamic>> _seedConsoles = [
    // PlayStation 3 — 6 unit (Reguler 5.000 / VIP 8.000)
    for (var i = 1; i <= 6; i++)
      {
        'code': 'PS3-${i.toString().padLeft(2, '0')}',
        'name': 'PlayStation 3 #$i',
        'type': 'PlayStation 3',
        'price_per_hour': 5000,
        'price_vip': 8000,
      },
    // PlayStation 4 — 4 unit (Reguler 10.000 / VIP 13.000)
    for (var i = 1; i <= 4; i++)
      {
        'code': 'PS4-${i.toString().padLeft(2, '0')}',
        'name': 'PlayStation 4 #$i',
        'type': 'PlayStation 4',
        'price_per_hour': 10000,
        'price_vip': 13000,
      },
    // PlayStation 5 — 2 unit (Reguler 25.000 / VIP 30.000)
    for (var i = 1; i <= 2; i++)
      {
        'code': 'PS5-${i.toString().padLeft(2, '0')}',
        'name': 'PlayStation 5 #$i',
        'type': 'PlayStation 5',
        'price_per_hour': 25000,
        'price_vip': 30000,
      },
    // VR Gaming — 2 unit (VIP only 35.000)
    for (var i = 1; i <= 2; i++)
      {
        'code': 'VR-${i.toString().padLeft(2, '0')}',
        'name': 'VR Gaming #$i',
        'type': 'VR Gaming',
        'price_per_hour': 0,
        'price_vip': 35000,
      },
    // Nintendo Switch — 2 unit (VIP only 45.000)
    for (var i = 1; i <= 2; i++)
      {
        'code': 'NSW-${i.toString().padLeft(2, '0')}',
        'name': 'Nintendo Switch #$i',
        'type': 'Nintendo Switch',
        'price_per_hour': 0,
        'price_vip': 45000,
      },
  ];

  Future<void> _seedInitialData(Transaction txn) async {
    // Default Settings
    final settings = {
      'store_name': 'Gaming Zone',
      'store_address': 'Jl. Gaming No. 1, Kota',
      'store_phone': '08123456789',
      'owner_name': 'Admin',
      'tax_enabled': '0',
      'tax_percent': '0',
      'point_value': '1000', // Rp 1000 = 1 point
      'point_redeem': '100', // 100 points = Rp 10.000
      'cashier_name': 'Admin',
    };
    for (final e in settings.entries) {
      await txn.insert(AppConstants.tableSettings, {
        'key': e.key,
        'value': e.value,
      });
    }

    // Seed Consoles
    for (final c in _seedConsoles) {
      await txn.insert(AppConstants.tableConsoles, c);
    }

    // Seed Snacks
    final snacks = [
      {
        'code': 'SNK-001',
        'name': 'Indomie Goreng',
        'category': 'makanan',
        'price': 5000,
        'stock': 50,
        'unit': 'bungkus'
      },
      {
        'code': 'SNK-002',
        'name': 'Indomie Rebus',
        'category': 'makanan',
        'price': 5000,
        'stock': 50,
        'unit': 'bungkus'
      },
      {
        'code': 'SNK-003',
        'name': 'Nasi Goreng',
        'category': 'makanan',
        'price': 15000,
        'stock': 20,
        'unit': 'porsi'
      },
      {
        'code': 'SNK-004',
        'name': 'Mie Ayam',
        'category': 'makanan',
        'price': 12000,
        'stock': 20,
        'unit': 'porsi'
      },
      {
        'code': 'SNK-005',
        'name': 'Kopi Hitam',
        'category': 'minuman',
        'price': 5000,
        'stock': 100,
        'unit': 'gelas'
      },
      {
        'code': 'SNK-006',
        'name': 'Kopi Susu',
        'category': 'minuman',
        'price': 8000,
        'stock': 100,
        'unit': 'gelas'
      },
      {
        'code': 'SNK-007',
        'name': 'Es Teh Manis',
        'category': 'minuman',
        'price': 4000,
        'stock': 100,
        'unit': 'gelas'
      },
      {
        'code': 'SNK-008',
        'name': 'Air Mineral',
        'category': 'minuman',
        'price': 3000,
        'stock': 100,
        'unit': 'botol'
      },
      {
        'code': 'SNK-009',
        'name': 'Pocari Sweat',
        'category': 'minuman',
        'price': 8000,
        'stock': 50,
        'unit': 'botol'
      },
      {
        'code': 'SNK-010',
        'name': 'Chitato',
        'category': 'snack',
        'price': 10000,
        'stock': 30,
        'unit': 'bungkus'
      },
      {
        'code': 'SNK-011',
        'name': 'Cheetos',
        'category': 'snack',
        'price': 8000,
        'stock': 30,
        'unit': 'bungkus'
      },
      {
        'code': 'SNK-012',
        'name': 'Rokok Sampoerna',
        'category': 'rokok',
        'price': 28000,
        'stock': 20,
        'unit': 'bungkus'
      },
    ];
    for (final s in snacks) {
      await txn.insert(AppConstants.tableSnacks, s);
    }
  }

  // ── Generic CRUD Helpers ───────────────────────────────────────────────────

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    return db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawInsert(sql, args);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawUpdate(sql, args);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> close() async => _db?.close();
}
