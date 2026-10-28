import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/network/api_error_code.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../settings/presentation/widgets/choice_sheet.dart';
import '../data/models/order_detail.dart';
import '../data/models/order_status.dart';
import '../data/models/payment_status.dart';
import 'order_detail_provider.dart';
import 'orders_providers.dart';
import 'widgets/order_actions_bar.dart';
import 'widgets/order_items_table.dart';
import 'widgets/order_status_chip.dart';
import 'widgets/payment_status_chip.dart';
import 'widgets/status_timeline.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _busy = false;

  /// Runs one mutation. The server's response replaces the detail state.
  Future<void> _run(
    Future<OrderDetail> Function() action, {
    String? successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await action();
      invalidateOrderData(ref, updated: updated);
      if (mounted && successMessage != null) {
        showAppSnackBar(context, successMessage);
      }
    } catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleError(Object error) {
    showAppSnackBar(context, errorMessage(context, error));
    if (error is! ApiException) return;
    if (error.code == ApiErrorCode.notFound) {
      invalidateOrderData(ref);
      context.go(AppRoutes.orders);
    } else if (error.code == ApiErrorCode.invalidStatusTransition ||
        error.code == ApiErrorCode.orderNotEditable ||
        error.code == ApiErrorCode.paymentRequired) {
      // Changed elsewhere in the meantime: show the current state.
      ref.invalidate(orderDetailProvider(widget.orderId));
    }
  }

  Future<void> _advance(OrderDetail order) async {
    final next = order.status.next;
    if (next == null) return;
    final repository = ref.read(orderRepositoryProvider);
    final l10n = context.l10n;

    if (next == OrderStatus.pickedUp && !order.paymentStatus.isPaid) {
      final paid = await showConfirmDialog(
        context,
        title: l10n.orderPaidQuestionTitle,
        message: l10n.orderPaidQuestionBody,
        confirmLabel: l10n.orderPaidQuestionConfirm,
      );
      if (!paid || !mounted) return;
      setState(() => _busy = true);
      OrderDetail? afterPayment;
      try {
        afterPayment = await repository.changePayment(
          order.id,
          PaymentStatus.paid,
        );
        final pickedUp = await repository.changeStatus(
          order.id,
          OrderStatus.pickedUp,
        );
        invalidateOrderData(ref, updated: pickedUp);
      } catch (e) {
        if (!mounted) return;
        if (afterPayment != null) {
          // Paid, but not picked up: refetch and explain.
          invalidateOrderData(ref);
          showAppSnackBar(
            context,
            '${l10n.orderPaidButNotPickedUp} ${errorMessage(context, e)}',
          );
        } else {
          _handleError(e);
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    await _run(() => repository.changeStatus(order.id, next));
  }

  Future<void> _changeStatus(OrderDetail order) async {
    final l10n = context.l10n;
    final picked = await showChoiceSheet<OrderStatus>(
      context,
      title: l10n.orderActionChangeStatus,
      options: order.status.previous,
      selected: order.status,
      labelOf: (status) => status.label(context),
    );
    if (picked == null || !mounted) return;
    await _run(
      () => ref.read(orderRepositoryProvider).changeStatus(order.id, picked),
    );
  }

  Future<void> _unpay(OrderDetail order) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.orderUnpayTitle,
      message: l10n.orderUnpayBody,
      confirmLabel: l10n.orderActionUnpay,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => ref
          .read(orderRepositoryProvider)
          .changePayment(order.id, PaymentStatus.unpaid),
    );
  }

  Future<void> _delete(OrderDetail order) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.orderDeleteTitle,
      message: l10n.orderDeleteBody(order.orderNumber),
      confirmLabel: l10n.orderActionDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(orderRepositoryProvider).delete(order.id);
      invalidateOrderData(ref);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = l10n.orderDeleted;
      context.go(AppRoutes.orders);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final detail = ref.watch(orderDetailProvider(widget.orderId));
    final auth = ref.watch(authControllerProvider).value;
    final isOwner = auth is Authenticated && auth.user.isOwner;
    final order = detail.value;

    Future<void> refresh() async {
      ref.invalidate(orderDetailProvider(widget.orderId));
      try {
        await ref.read(orderDetailProvider(widget.orderId).future);
      } catch (_) {
        // The error state is rendered by the screen itself.
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(order?.orderNumber ?? l10n.orderDetailTitle)),
      bottomNavigationBar:
          order == null ||
              (order.status.next == null &&
                  !isOwner &&
                  order.paymentStatus.isPaid)
          ? null
          : OrderActionsBar(
              order: order,
              isOwner: isOwner,
              busy: _busy,
              onAdvance: () => _advance(order),
              onMarkPaid: () => _run(
                () => ref
                    .read(orderRepositoryProvider)
                    .changePayment(order.id, PaymentStatus.paid),
              ),
              onEdit: () => context.push(AppRoutes.orderEdit(order.id)),
              onChangeStatus: () => _changeStatus(order),
              onUnpay: () => _unpay(order),
              onDelete: () => _delete(order),
            ),
      body: order == null
          ? detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () =>
                    ref.invalidate(orderDetailProvider(widget.orderId)),
              ),
              data: (_) => const SizedBox.shrink(),
            )
          : RefreshIndicator(
              onRefresh: refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            OrderStatusChip(status: order.status),
                            PaymentStatusChip(status: order.paymentStatus),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (order.outlet != null && isOwner)
                          Text(
                            '${l10n.orderDetailOutlet}: ${order.outlet!.code} · ${order.outlet!.name}',
                          ),
                        Text(
                          '${l10n.orderDetailReceivedAt}: ${formatDateTime(order.createdAt, locale)}',
                        ),
                        Text(
                          '${l10n.orderDetailSpeed}: ${order.speed.label(context)}',
                        ),
                        if (order.createdByName != null)
                          Text(
                            '${l10n.orderDetailCreatedBy}: ${order.createdByName}',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: l10n.orderDetailCustomer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customer.name),
                        if ((order.customer.phone ?? '').trim().isNotEmpty)
                          Text(order.customer.phone!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: l10n.orderDetailProgress,
                    child: StatusTimeline(order: order),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: l10n.orderDetailItems,
                    child: OrderItemsTable(order: order),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: l10n.orderDetailPayment,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaymentStatusChip(status: order.paymentStatus),
                        if (order.paidAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.orderDetailPaidAt}: ${formatDateTime(order.paidAt!, locale)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (order.notes != null) ...[
                    const SizedBox(height: 12),
                    SectionCard(
                      title: l10n.orderDetailNotes,
                      child: Text(order.notes!),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
