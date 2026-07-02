class ConsoleModel {
  final int? id;
  final String code;
  final String name;
  final String type;
  final String status;
  final int pricePerHour;
  final int priceVip;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsoleModel({
    this.id,
    required this.code,
    required this.name,
    required this.type,
    this.status = 'available',
    required this.pricePerHour,
    required this.priceVip,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsoleModel.fromMap(Map<String, dynamic> map) {
    return ConsoleModel(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      status: map['status'] as String? ?? 'available',
      pricePerHour: map['price_per_hour'] as int? ?? 0,
      priceVip: map['price_vip'] as int? ?? 0,
      description: map['description'] as String?,
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
      'type': type,
      'status': status,
      'price_per_hour': pricePerHour,
      'price_vip': priceVip,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConsoleModel copyWith({
    int? id,
    String? code,
    String? name,
    String? type,
    String? status,
    int? pricePerHour,
    int? priceVip,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsoleModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      priceVip: priceVip ?? this.priceVip,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isPlaying => status == 'playing';
  bool get isReserved => status == 'reserved';
  bool get isMaintain => status == 'maintenance';

  /// Konsol yang hanya tersedia dalam kategori VIP (Room AC) saja,
  /// misalnya VR Gaming dan Nintendo Switch — tidak punya opsi Reguler.
  bool get isVipOnly => pricePerHour <= 0;
}
