import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/models/laundry_service.dart';
import '../../catalog/data/models/pricing_unit.dart';
import '../data/models/order_detail.dart';
import '../data/models/order_draft.dart';
import '../data/models/order_draft_item.dart';
import '../data/models/service_speed.dart';

final orderFormControllerProvider =
    NotifierProvider.autoDispose<OrderFormController, OrderDraft>(
      OrderFormController.new,
    );

/// State of the order form (create and edit).
class OrderFormController extends Notifier<OrderDraft> {
  int _nextUid = 0;

  /// True once the user changed anything; used for the "discard changes?" prompt.
  bool touched = false;

  @override
  OrderDraft build() => const OrderDraft();

  void _update(OrderDraft draft) {
    touched = true;
    state = draft;
  }

  /// Preselects an outlet without counting as a user change.
  void presetOutlet(String outletId) {
    if (state.outletId == null) state = state.copyWith(outletId: outletId);
  }

  /// Different outlets have different services, so items are cleared.
  void setOutlet(String outletId) =>
      _update(state.copyWith(outletId: outletId, items: const []));

  void selectCustomer({
    required String id,
    required String name,
    required String phone,
  }) => _update(
    state.copyWith(customerId: id, customerName: name, customerPhone: phone),
  );

  /// A typed (new) customer; clears any picked customer id.
  void setNewCustomer({required String name, required String phone}) => _update(
    state.copyWith(
      clearCustomerId: true,
      customerName: name,
      customerPhone: phone,
    ),
  );

  void setSpeed(ServiceSpeed speed) => _update(state.copyWith(speed: speed));

  void setNotes(String notes) => _update(state.copyWith(notes: notes));

  void setPaid(bool isPaid) => _update(state.copyWith(isPaid: isPaid));

  /// Sets the per-kilo quantity of [service]; null or 0 removes the line.
  void setKiloQuantity(LaundryService service, int? quantity100) {
    final others = [
      for (final item in state.items)
        if (item.serviceId != service.id) item,
    ];
    if (quantity100 == null || quantity100 <= 0) {
      _update(state.copyWith(items: others));
      return;
    }
    final existing = state.items
        .where((item) => item.serviceId == service.id)
        .firstOrNull;
    final line = OrderDraftItem(
      uid: existing?.uid ?? _nextUid++,
      serviceId: service.id,
      serviceName: service.name,
      unit: service.pricingUnit,
      quantity100: quantity100,
    );
    _update(
      state.copyWith(
        items: [
          for (final item in state.items)
            if (item.serviceId == service.id) line else item,
          if (existing == null) line,
        ],
      ),
    );
  }

  void addUnitItem(
    LaundryService service, {
    int? quantity100,
    int? length100,
    int? width100,
  }) {
    _update(
      state.copyWith(
        items: [
          ...state.items,
          OrderDraftItem(
            uid: _nextUid++,
            serviceId: service.id,
            serviceName: service.name,
            unit: service.pricingUnit,
            quantity100: quantity100,
            length100: length100,
            width100: width100,
          ),
        ],
      ),
    );
  }

  void updateUnitItem(
    int uid, {
    int? quantity100,
    int? length100,
    int? width100,
  }) {
    _update(
      state.copyWith(
        items: [
          for (final item in state.items)
            if (item.uid == uid)
              item.copyWith(
                quantity100: quantity100,
                length100: length100,
                width100: width100,
              )
            else
              item,
        ],
      ),
    );
  }

  void removeItem(int uid) => _update(
    state.copyWith(
      items: [
        for (final item in state.items)
          if (item.uid != uid) item,
      ],
    ),
  );

  /// Fills the form from a saved order (edit mode). Not a user change.
  void loadFrom(OrderDetail detail) {
    int hundredths(double? value) => ((value ?? 0) * 100).round();
    state = OrderDraft(
      outletId: detail.outlet?.id,
      customerId: detail.customer.id.isEmpty ? null : detail.customer.id,
      customerName: detail.customer.name,
      customerPhone: detail.customer.phone ?? '',
      speed: detail.speed,
      notes: detail.notes ?? '',
      items: [
        for (final item in detail.items)
          OrderDraftItem(
            uid: _nextUid++,
            serviceId: item.serviceId,
            serviceName: item.serviceName,
            unit: item.pricingUnit,
            quantity100: item.pricingUnit == PricingUnit.sqm
                ? null
                : hundredths(item.quantity),
            length100: item.pricingUnit == PricingUnit.sqm
                ? hundredths(item.lengthM)
                : null,
            width100: item.pricingUnit == PricingUnit.sqm
                ? hundredths(item.widthM)
                : null,
          ),
      ],
    );
    touched = false;
  }
}
