class AppConstants {
  AppConstants._();

  // ── App Info ───────────────────────────────────────────────────────────────
  static const String appName = 'Gaming Zone';
  static const String appTagline = 'Gaming Center Management';
  static const String appVersion = '1.0.0';

  // ── Database ───────────────────────────────────────────────────────────────
  static const String dbName = 'gaming_zone.db';
  static const int dbVersion = 3;

  // ── Tables ─────────────────────────────────────────────────────────────────
  static const String tableConsoles = 'consoles';
  static const String tableMembers = 'members';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionItems = 'transaction_items';
  static const String tableSnacks = 'snacks';
  static const String tableSettings = 'settings';
  static const String tableMemberPoints = 'member_points';
  static const String tableUsers = 'users';
  static const String tableSnackOrders = 'snack_orders';

  // ── User Roles ─────────────────────────────────────────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleUser  = 'user';

  // ── Transaction Status ─────────────────────────────────────────────────────
  static const String statusRequested = 'requested'; // booking masuk dari User
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // ── Snack Order Status ─────────────────────────────────────────────────────
  static const String orderPending = 'pending';
  static const String orderCompleted = 'completed';
  static const String orderCancelled = 'cancelled';

  // ── Shared Preferences Keys (Auth) ────────────────────────────────────────
  static const String prefLoggedInUserId = 'logged_in_user_id';

  // ── Shared Preferences Keys (App Lock / PIN Dashboard) ────────────────────
  static const String prefAppLockEnabled = 'app_lock_enabled';
  static const String prefAppLockPinHash = 'app_lock_pin_hash';

  // ── Rental Types ───────────────────────────────────────────────────────────
  static const String rentalTypeRegular = 'Regular';
  static const String rentalTypeVIP = 'VIP';

  static const List<String> rentalTypes = [
    rentalTypeRegular,
    rentalTypeVIP,
  ];

  // ── Console Types ──────────────────────────────────────────────────────────
  static const String consoleTypePS3 = 'PlayStation 3';
  static const String consoleTypePS4 = 'PlayStation 4';
  static const String consoleTypePS5 = 'PlayStation 5';
  static const String consoleTypePC = 'Gaming PC';
  static const String consoleTypeXbox = 'Xbox';
  static const String consoleTypeNintendo = 'Nintendo Switch';
  static const String consoleTypeVR = 'VR Gaming';

  static const List<String> consoleTypes = [
    consoleTypePS3,
    consoleTypePS4,
    consoleTypePS5,
    consoleTypePC,
    consoleTypeXbox,
    consoleTypeNintendo,
    consoleTypeVR,
  ];

  // ── Console Status ─────────────────────────────────────────────────────────
  static const String statusAvailable = 'available';
  static const String statusPlaying = 'playing';
  static const String statusReserved = 'reserved';
  static const String statusMaintain = 'maintenance';

  // ── Payment Methods ────────────────────────────────────────────────────────
  static const String paymentCash = 'Tunai';
  static const String paymentQris = 'QRIS';
  static const String paymentTransfer = 'Transfer';
  static const String paymentDebit = 'Debit';

  static const List<String> paymentMethods = [
    paymentCash,
    paymentQris,
    paymentTransfer,
    paymentDebit,
  ];

  // ── Transaction Status ─────────────────────────────────────────────────────
  static const String txStatusActive = 'active';
  static const String txStatusCompleted = 'completed';
  static const String txStatusCancelled = 'cancelled';

  // ── Duration Options (minutes) ─────────────────────────────────────────────
  static const List<int> durationOptions = [
    30,
    60,
    90,
    120,
    180,
    240,
    300,
    360
  ];

  // ── Shared Preferences Keys ────────────────────────────────────────────────
  static const String prefOwnerName = 'owner_name';
  static const String prefStoreName = 'store_name';
  static const String prefStoreAddress = 'store_address';
  static const String prefStorePhone = 'store_phone';
  static const String prefTaxEnabled = 'tax_enabled';
  static const String prefTaxPercent = 'tax_percent';
  static const String prefPointValue =
      'point_value'; // e.g. 1 point per Rp 1000
  static const String prefPointRedeem =
      'point_redeem'; // e.g. 100 points = Rp 10000

  // ── Layout & Spacing ──────────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusFull = 100.0;

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
}
