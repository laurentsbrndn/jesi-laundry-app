/// Short outlet reference embedded in other responses.
class OutletRef {
  const OutletRef({required this.id, required this.code, required this.name});

  factory OutletRef.fromJson(Map<String, dynamic> json) {
    return OutletRef(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String code;
  final String name;
}
