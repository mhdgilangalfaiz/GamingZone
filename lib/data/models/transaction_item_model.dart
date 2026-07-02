class TransactionItemModel {
  final int? id;
  final int transactionId;
  final String itemType;
  final int itemId;
  final String itemName;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final DateTime createdAt;

  const TransactionItemModel({
    this.id,
    required this.transactionId,
    this.itemType = 'snack',
    required this.itemId,
    required this.itemName,
    this.quantity = 1,
    required this.unitPrice,
    required this.subtotal,
    required this.createdAt,
  });

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      itemType: map['item_type'] as String? ?? 'snack',
      itemId: map['item_id'] as int,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: map['unit_price'] as int? ?? 0,
      subtotal: map['subtotal'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'transaction_id': transactionId,
      'item_type': itemType,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
