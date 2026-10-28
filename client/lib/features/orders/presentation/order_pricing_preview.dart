import '../../catalog/data/models/laundry_service.dart';
import '../../catalog/data/models/pricing_unit.dart';
import '../data/models/order_draft.dart';
import '../data/models/order_draft_item.dart';
import '../data/models/service_speed.dart';

// Preview of the order total, mirroring BACKEND.md §8.1. The server stays the
// source of truth: after saving, only server values are shown.
//
// All arithmetic uses integers in hundredths (2,5 kg = 250), never doubles,
// and rounds half up.
//
// Expected results (documentation only):
//
//   item                               | billed | unit price | subtotal
//   -----------------------------------+--------+------------+---------
//   2,5 kg, min 3 kg                   | 3      | 7.000      | 21.000
//   3,33 kg, min 3 kg                  | 3,33   | 7.000      | 23.310
//   2 x 2,5 m (area 5), no minimum     | 5      | 15.000     | 75.000
//
//   step                      | formula
//   --------------------------+--------------------------------------------
//   sqm area (hundredths)     | (length100 * width100 + 50) ~/ 100
//   billed (hundredths)       | max(quantity100, minQuantity100)
//   subtotal (rupiah)         | (billed100 * unitPrice + 50) ~/ 100
//   total                     | sum of subtotals

/// Largest quantities the server accepts, in hundredths.
const int _maxKg100 = 99999;
const int _maxPiece100 = 99900;
const int _maxLength100 = 9999;
const int maxOrderItems = 50;

/// Result for one draft line.
typedef ItemPreview = ({
  bool isValid,
  int quantity100,
  int billed100,
  int unitPrice,
  int subtotal,
  int durationDays,
});

class OrderPreview {
  const OrderPreview({
    required this.lines,
    required this.total,
    required this.longestDurationDays,
  });

  /// By [OrderDraftItem.uid]. Items without a known service are omitted.
  final Map<int, ItemPreview> lines;
  final int total;

  /// 0 when there is no valid item.
  final int longestDurationDays;

  /// Estimated finish if the order were created at [from].
  DateTime? estimatedDoneAt(DateTime from) => longestDurationDays == 0
      ? null
      : from.add(Duration(days: longestDurationDays));
}

/// Area in hundredths of m² from length and width in hundredths of metres.
int areaHundredths(int length100, int width100) =>
    (length100 * width100 + 50) ~/ 100;

/// A service minimum such as `3` or `0.5` in hundredths.
int minQuantityHundredths(double minQuantity) => (minQuantity * 100).round();

ItemPreview previewItem(
  OrderDraftItem item,
  LaundryService service,
  ServiceSpeed speed,
) {
  final unitPrice = speed == ServiceSpeed.express
      ? service.expressPrice
      : service.regularPrice;
  final durationDays = speed == ServiceSpeed.express
      ? service.expressDurationDays
      : service.regularDurationDays;

  var quantity100 = 0;
  var isValid = false;
  switch (service.pricingUnit) {
    case PricingUnit.kg:
      quantity100 = item.quantity100 ?? 0;
      isValid = quantity100 > 0 && quantity100 <= _maxKg100;
    case PricingUnit.piece:
      quantity100 = item.quantity100 ?? 0;
      isValid =
          quantity100 >= 100 &&
          quantity100 <= _maxPiece100 &&
          quantity100 % 100 == 0;
    case PricingUnit.sqm:
      final length = item.length100 ?? 0;
      final width = item.width100 ?? 0;
      quantity100 = areaHundredths(length, width);
      isValid =
          length > 0 &&
          length <= _maxLength100 &&
          width > 0 &&
          width <= _maxLength100 &&
          quantity100 > 0;
  }

  final minimum = minQuantityHundredths(service.minQuantity);
  final billed100 = quantity100 > minimum ? quantity100 : minimum;
  final subtotal = isValid ? (billed100 * unitPrice + 50) ~/ 100 : 0;
  return (
    isValid: isValid,
    quantity100: quantity100,
    billed100: billed100,
    unitPrice: unitPrice,
    subtotal: subtotal,
    durationDays: durationDays,
  );
}

OrderPreview previewOrder(
  OrderDraft draft,
  Map<String, LaundryService> servicesById,
) {
  final lines = <int, ItemPreview>{};
  var total = 0;
  var longest = 0;
  for (final item in draft.items) {
    final service = servicesById[item.serviceId];
    if (service == null) continue;
    final line = previewItem(item, service, draft.speed);
    lines[item.uid] = line;
    if (!line.isValid) continue;
    total += line.subtotal;
    if (line.durationDays > longest) longest = line.durationDays;
  }
  return OrderPreview(lines: lines, total: total, longestDurationDays: longest);
}
