import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/paged_async_list.dart';
import '../../../core/widgets/search_field.dart';
import '../../outlets/presentation/widgets/outlet_filter_dropdown.dart';
import '../data/models/order_list_item.dart';
import '../data/models/order_status.dart';
import '../data/models/payment_status.dart';
import 'orders_list_controller.dart';
import 'widgets/order_filter_bar.dart';
import 'widgets/order_list_tile.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  OrderStatus? _status;
  PaymentStatus? _payment;
  String? _outletId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(ordersListControllerProvider);
    final controller = ref.read(ordersListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ordersTitle),
        actions: [
          // Hidden unless there is more than one active outlet (owners only).
          OutletFilterDropdown(
            value: _outletId,
            allowAll: true,
            onChanged: (id) {
              setState(() => _outletId = id);
              controller.setOutlet(id);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.orderNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.ordersNew),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchField(
              hint: l10n.ordersSearchHint,
              onChanged: controller.setSearch,
            ),
          ),
          OrderFilterBar(
            status: _status,
            payment: _payment,
            onStatusChanged: (value) {
              setState(() => _status = value);
              controller.setStatus(value);
            },
            onPaymentChanged: (value) {
              setState(() => _payment = value);
              controller.setPayment(value);
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: PagedAsyncList<OrderListItem>(
              value: state,
              onRefresh: controller.refresh,
              onLoadMore: controller.loadMore,
              onRetry: () => ref.invalidate(ordersListControllerProvider),
              empty: EmptyView(
                icon: Icons.receipt_long_outlined,
                title: l10n.ordersEmptyTitle,
                message: l10n.ordersEmptyMessage,
              ),
              itemBuilder: (context, order) => OrderListTile(
                order: order,
                onTap: () => context.push(AppRoutes.orderDetail(order.id)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
