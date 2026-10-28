class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.lastOrderAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final lastOrderAt = json['last_order_at'];
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      lastOrderAt: lastOrderAt is String
          ? DateTime.tryParse(lastOrderAt)?.toLocal()
          : null,
    );
  }

  final String id;
  final String name;
  final String? phone;
  final DateTime? lastOrderAt;
}
