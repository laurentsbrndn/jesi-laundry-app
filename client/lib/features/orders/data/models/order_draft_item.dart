import '../../../catalog/data/models/pricing_unit.dart';

/// One line of the order form. Quantities are integers in hundredths
/// (2,5 kg = 250) so previews never touch floating point.
class OrderDraftItem {
  const OrderDraftItem({
    required this.uid,
    required this.serviceId,
    required this.serviceName,
    required this.unit,
    this.quantity100,
    this.length100,
    this.width100,
  });

  /// Local identity, stable while editing.
  final int uid;
  final String serviceId;

  /// Kept so an item whose service is no longer active can still be named.
  final String serviceName;
  final PricingUnit unit;

  /// kg (hundredths) or pcs (whole number x100). Null for `sqm`.
  final int? quantity100;

  /// Metres in hundredths, `sqm` only.
  final int? length100;
  final int? width100;

  OrderDraftItem copyWith({int? quantity100, int? length100, int? width100}) {
    return OrderDraftItem(
      uid: uid,
      serviceId: serviceId,
      serviceName: serviceName,
      unit: unit,
      quantity100: quantity100 ?? this.quantity100,
      length100: length100 ?? this.length100,
      width100: width100 ?? this.width100,
    );
  }

  /// JSON of one `items[]` entry. `sqm` sends length and width, not quantity.
  Map<String, Object?> toJson() {
    return switch (unit) {
      PricingUnit.sqm => {
        'service_id': serviceId,
        'length_m': (length100 ?? 0) / 100,
        'width_m': (width100 ?? 0) / 100,
      },
      PricingUnit.piece => {
        'service_id': serviceId,
        'quantity': (quantity100 ?? 0) ~/ 100,
      },
      PricingUnit.kg => {
        'service_id': serviceId,
        'quantity': (quantity100 ?? 0) / 100,
      },
    };
  }
}
