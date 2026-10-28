class Outlet {
  const Outlet({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
  });

  factory Outlet.fromJson(Map<String, dynamic> json) {
    return Outlet(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final bool isActive;
}
