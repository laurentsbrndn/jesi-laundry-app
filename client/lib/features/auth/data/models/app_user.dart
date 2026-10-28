import 'outlet_ref.dart';
import 'user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.outlet,
    required this.lastLoginAt,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final outlet = json['outlet'];
    final lastLoginAt = json['last_login_at'];
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromValue(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      outlet: outlet is Map<String, dynamic>
          ? OutletRef.fromJson(outlet)
          : null,
      lastLoginAt: lastLoginAt is String
          ? DateTime.parse(lastLoginAt).toLocal()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;

  /// Null for owners (they are not tied to one outlet).
  final OutletRef? outlet;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  bool get isOwner => role.isOwner;
}
