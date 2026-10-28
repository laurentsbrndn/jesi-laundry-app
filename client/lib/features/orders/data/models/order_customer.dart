/// Customer block of an order detail.
class OrderCustomer {
  const OrderCustomer({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory OrderCustomer.fromJson(Map<String, dynamic> json) {
    return OrderCustomer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }

  final String id;
  final String name;
  final String? phone;
}
