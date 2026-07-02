class SnackModel {
  final int? id;
  final String code;
  final String name;
  final String category;
  final int price;
  final int stock;
  final String unit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SnackModel({
    this.id,
    required this.code,
    required this.name,
    this.category = 'snack',
    required this.price,
    this.stock = 0,
    this.unit = 'pcs',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SnackModel.fromMap(Map<String, dynamic> map) {
    return SnackModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'snack',
      price: map['price'] as int? ?? 0,
      stock: map['stock'] as int? ?? 0,
      unit: map['unit'] as String? ?? 'pcs',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'unit': unit,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SnackModel copyWith({
    int? id,
    String? code,
    String? name,
    String? category,
    int? price,
    int? stock,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SnackModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 5;
}
