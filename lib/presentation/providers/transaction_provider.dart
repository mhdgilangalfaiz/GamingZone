import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/snack_model.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();

  // ── Active Transactions ────────────────────────────────────────────────────
  List<TransactionModel> _active = [];
  List<TransactionModel> _history = [];
  bool _loading = false;
  String? _error;

  // ── Dashboard Data ─────────────────────────────────────────────────────────
  Map<String, dynamic> _dailySummary = {};
  List<Map<String, dynamic>> _weeklyRevenue = [];
  List<Map<String, dynamic>> _topConsoles = [];

  // ── Cart (for current checkout) ────────────────────────────────────────────
  final List<CartItem> _cart = [];

  // ── Getters ────────────────────────────────────────────────────────────────
  List<TransactionModel> get active => _active;
  List<TransactionModel> get history => _history;
  bool get isLoading => _loading;
  String? get error => _error;
  Map<String, dynamic> get dailySummary => _dailySummary;
  List<Map<String, dynamic>> get weeklyRevenue => _weeklyRevenue;
  List<Map<String, dynamic>> get topConsoles => _topConsoles;
  List<CartItem> get cart => _cart;

  int get cartTotal => _cart.fold(0, (s, i) => s + i.subtotal);

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> loadActive() async {
    _loading = true;
    notifyListeners();
    try {
      _active = await _repo.getActive();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory({String? dateFrom, String? dateTo}) async {
    _loading = true;
    notifyListeners();
    try {
      _history = await _repo.getHistory(dateFrom: dateFrom, dateTo: dateTo);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboard() async {
    try {
      final today = DateTime.now();
      final date =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      _dailySummary = await _repo.getDailySummary(date);
      _weeklyRevenue = await _repo.getWeeklyRevenue();
      _topConsoles = await _repo.getTopConsoles();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Start Rental ───────────────────────────────────────────────────────────
  Future<String?> startRental({
    required int consoleId,
    required String consoleName,
    required String rentalType,
    required int pricePerHour,
    int? memberId,
    String? memberName,
    String cashierName = 'Admin',
  }) async {
    try {
      final invoiceNo = await _repo.generateInvoiceNo();
      final now = DateTime.now();

      final tx = TransactionModel(
        invoiceNo: invoiceNo,
        consoleId: consoleId,
        consoleName: consoleName,
        memberId: memberId,
        memberName: memberName,
        rentalType: rentalType,
        startTime: now,
        cashierName: cashierName,
        createdAt: now,
        updatedAt: now,
      );

      await _repo.startRental(tx);
      clearCart();
      await loadActive();
      return invoiceNo;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Complete Rental ────────────────────────────────────────────────────────
  Future<bool> completeRental({
    required TransactionModel tx,
    required int pricePerHour,
    required String paymentMethod,
    required int paymentAmount,
    int discount = 0,
    int taxPercent = 0,
    int pointsRedeemed = 0,
    int pointValueRp = 1000, // Rp per point
  }) async {
    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(tx.startTime);
      final minutes = duration.inMinutes;

      // Hitung biaya rental (minimal 30 menit dibulatkan per 30 menit)
      final billableMinutes = (minutes / 30).ceil() * 30;
      final rentalCost = (billableMinutes / 60 * pricePerHour).ceil();

      final snackCost = cartTotal;
      final subtotal = rentalCost + snackCost - discount;
      final tax = taxPercent > 0 ? (subtotal * taxPercent / 100).ceil() : 0;
      final totalCost = subtotal + tax - (pointsRedeemed * pointValueRp ~/ 100);
      final change = paymentAmount - totalCost;

      // Points earned: setiap Rp 1000 = 1 poin
      final pointsEarned = (totalCost / pointValueRp).floor();

      await _repo.completeRental(
        transactionId: tx.id!,
        consoleId: tx.consoleId!,
        endTime: endTime,
        durationMinutes: minutes,
        rentalCost: rentalCost,
        snackCost: snackCost,
        discount: discount,
        tax: tax,
        totalCost: totalCost,
        paymentMethod: paymentMethod,
        paymentAmount: paymentAmount,
        changeAmount: change > 0 ? change : 0,
        pointsEarned: pointsEarned,
        pointsRedeemed: pointsRedeemed,
        cartItems: List.from(_cart),
        memberId: tx.memberId,
      );

      clearCart();
      await loadActive();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRental(int txId, int consoleId) async {
    try {
      await _repo.cancelRental(txId, consoleId);
      clearCart();
      await loadActive();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<TransactionModel?> getActiveByConsole(int consoleId) async {
    return _repo.getActiveByConsole(consoleId);
  }

  Future<TransactionModel?> getById(int id) => _repo.getById(id);

  // ── Cart Management ────────────────────────────────────────────────────────
  void addToCart(SnackModel snack) {
    final idx = _cart.indexWhere(
      (i) => i.itemId == snack.id && i.itemType == 'snack',
    );
    if (idx >= 0) {
      _cart[idx].quantity++;
    } else {
      _cart.add(CartItem(
        itemId: snack.id!,
        itemType: 'snack',
        name: snack.name,
        quantity: 1,
        unitPrice: snack.price,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int itemId, String itemType) {
    _cart.removeWhere((i) => i.itemId == itemId && i.itemType == itemType);
    notifyListeners();
  }

  void updateCartQuantity(int itemId, String itemType, int quantity) {
    final idx = _cart.indexWhere(
      (i) => i.itemId == itemId && i.itemType == itemType,
    );
    if (idx >= 0) {
      if (quantity <= 0) {
        _cart.removeAt(idx);
      } else {
        _cart[idx].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
