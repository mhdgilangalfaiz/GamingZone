class MemberModel {
  final int? id;
  final String memberCode;
  final String name;
  final String? phone;
  final String? email;
  final int points;
  final int totalSpend;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberModel({
    this.id,
    required this.memberCode,
    required this.name,
    this.phone,
    this.email,
    this.points = 0,
    this.totalSpend = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      id: map['id'] as int?,
      memberCode: map['member_code'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      points: map['points'] as int? ?? 0,
      totalSpend: map['total_spend'] as int? ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'member_code': memberCode,
      'name': name,
      'phone': phone,
      'email': email,
      'points': points,
      'total_spend': totalSpend,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MemberModel copyWith({
    int? id,
    String? memberCode,
    String? name,
    String? phone,
    String? email,
    int? points,
    int? totalSpend,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberModel(
      id: id ?? this.id,
      memberCode: memberCode ?? this.memberCode,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      points: points ?? this.points,
      totalSpend: totalSpend ?? this.totalSpend,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'M';
  }

  /// Member tier berdasarkan total belanja
  String get tier {
    if (totalSpend >= 5000000) return 'Diamond';
    if (totalSpend >= 2000000) return 'Gold';
    if (totalSpend >= 500000) return 'Silver';
    return 'Bronze';
  }
}
