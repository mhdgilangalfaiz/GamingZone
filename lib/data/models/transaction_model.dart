import 'transaction_item_model.dart';

class TransactionModel {
  final int? id;
  final String invoiceNo;
  final int? consoleId;
  final String? consoleName;
  final int? memberId;
  final String? memberName;
  final String rentalType;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final int rentalCost;
  final int snackCost;
  final int discount;
  final int tax;
  final int totalCost;
  final String paymentMethod;
  final int paymentAmount;
  final int changeAmount;
  final int pointsEarned;
  final int pointsRedeemed;
  final String? notes;
  final String status;
  final String cashierName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relasi
  final List<TransactionItemModel> items;

  const TransactionModel({
    this.id,
    required this.invoiceNo,
    this.consoleId,
    this.consoleName,
    this.memberId,
    this.memberName,
    this.rentalType = 'Regular',
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.rentalCost = 0,
    this.snackCost = 0,
    this.discount = 0,
    this.tax = 0,
    this.totalCost = 0,
    this.paymentMethod = 'Tunai',
    this.paymentAmount = 0,
    this.changeAmount = 0,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
    this.notes,
    this.status = 'active',
    this.cashierName = 'Admin',
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      invoiceNo: map['invoice_no'] as String,
      consoleId: map['console_id'] as int?,
      consoleName: map['console_name'] as String?,
      memberId: map['member_id'] as int?,
      memberName: map['member_name'] as String?,
      rentalType: map['rental_type'] as String? ?? 'Regular',
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      durationMinutes: map['duration_minutes'] as int?,
      rentalCost: map['rental_cost'] as int? ?? 0,
      snackCost: map['snack_cost'] as int? ?? 0,
      discount: map['discount'] as int? ?? 0,
      tax: map['tax'] as int? ?? 0,
      totalCost: map['total_cost'] as int? ?? 0,
      paymentMethod: map['payment_method'] as String? ?? 'Tunai',
      paymentAmount: map['payment_amount'] as int? ?? 0,
      changeAmount: map['change_amount'] as int? ?? 0,
      pointsEarned: map['points_earned'] as int? ?? 0,
      pointsRedeemed: map['points_redeemed'] as int? ?? 0,
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'active',
      cashierName: map['cashier_name'] as String? ?? 'Admin',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_no': invoiceNo,
      'console_id': consoleId,
      'member_id': memberId,
      'rental_type': rentalType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
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
      'notes': notes,
      'status': status,
      'cashier_name': cashierName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    int? id,
    String? invoiceNo,
    int? consoleId,
    String? consoleName,
    int? memberId,
    String? memberName,
    String? rentalType,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? rentalCost,
    int? snackCost,
    int? discount,
    int? tax,
    int? totalCost,
    String? paymentMethod,
    int? paymentAmount,
    int? changeAmount,
    int? pointsEarned,
    int? pointsRedeemed,
    String? notes,
    String? status,
    String? cashierName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TransactionItemModel>? items,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      consoleId: consoleId ?? this.consoleId,
      consoleName: consoleName ?? this.consoleName,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      rentalType: rentalType ?? this.rentalType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rentalCost: rentalCost ?? this.rentalCost,
      snackCost: snackCost ?? this.snackCost,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      totalCost: totalCost ?? this.totalCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      cashierName: cashierName ?? this.cashierName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  bool get isActive => status == 'active';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  int get subtotal => rentalCost + snackCost;
  int get grandTotal => subtotal - discount + tax;
}

// ── Cart Item (untuk sesi aktif) ───────────────────────────────────────────
class CartItem {
  final int itemId;
  final String itemType; // 'snack'
  final String name;
  int quantity;
  final int unitPrice;

  CartItem({
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  int get subtotal => quantity * unitPrice;
}
