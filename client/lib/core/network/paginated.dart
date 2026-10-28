/// A page of a list endpoint: `{"data": [...], "meta": {"page", "limit", "total"}}`.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final meta = json['meta'] as Map<String, dynamic>;
    return Paginated(
      items: (json['data'] as List)
          .cast<Map<String, dynamic>>()
          .map(fromItem)
          .toList(),
      page: (meta['page'] as num).toInt(),
      limit: (meta['limit'] as num).toInt(),
      total: (meta['total'] as num).toInt(),
    );
  }

  final List<T> items;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;
}
