import 'dart:convert';

class SnackOrderItem {
  final int snackId;
  final String name;
  final int price;
  final int qty;

  const SnackOrderItem({
    required this.snackId,
    required this.name,
    required this.price,
    required this.qty,
  });

  int get subtotal => price * qty;

  Map<String, dynamic> toJson() => {
        'snackId': snackId,
        'name': name,
        'price': price,
        'qty': qty,
      };

  factory SnackOrderItem.fromJson(Map<String, dynamic> json) {
    return SnackOrderItem(
      snackId: json['snackId'] as int,
      name: json['name'] as String,
      price: json['price'] as int,
      qty: json['qty'] as int,
    );
  }
}

class SnackOrderModel {
  final int? id;
  final String orderNo;
  final int? userId;
  final int? memberId;
  final String customerName;
  final List<SnackOrderItem> items;
  final int totalCost;
  final String status; // pending | completed | cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SnackOrderModel({
    this.id,
    required this.orderNo,
    this.userId,
    this.memberId,
    required this.customerName,
    required this.items,
    required this.totalCost,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SnackOrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = jsonDecode(map['items_json'] as String) as List;
    return SnackOrderModel(
      id: map['id'] as int?,
      orderNo: map['order_no'] as String,
      userId: map['user_id'] as int?,
      memberId: map['member_id'] as int?,
      customerName: map['customer_name'] as String,
      items: rawItems
          .map((e) => SnackOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCost: map['total_cost'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_no': orderNo,
      'user_id': userId,
      'member_id': memberId,
      'customer_name': customerName,
      'items_json': jsonEncode(items.map((e) => e.toJson()).toList()),
      'total_cost': totalCost,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
