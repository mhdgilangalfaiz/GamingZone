import '../../core/constants/app_constants.dart';

class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String role; // 'admin' | 'user'
  final String fullName;
  final String? phone;
  final int? memberId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.fullName,
    this.phone,
    this.memberId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String? ?? AppConstants.roleUser,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      memberId: map['member_id'] as int?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'password_hash': passwordHash,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'member_id': memberId,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? role,
    String? fullName,
    String? phone,
    int? memberId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        username: username ?? this.username,
        passwordHash: passwordHash ?? this.passwordHash,
        role: role ?? this.role,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        memberId: memberId ?? this.memberId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isUser  => role == AppConstants.roleUser;

  String get roleLabel => isAdmin ? 'Admin' : 'User';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}
