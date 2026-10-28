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
import '../../catalog/data/models/laundry_service.dart';
import '../../catalog/presentation/services_provider.dart';
import '../../customers/presentation/customer_autocomplete_field.dart';
import '../../outlets/presentation/outlets_provider.dart';
import '../../outlets/presentation/widgets/outlet_picker_field.dart';
import '../data/models/order_detail.dart';
import '../data/models/order_draft_item.dart';
import 'order_detail_provider.dart';
import 'order_form_controller.dart';
import 'order_pricing_preview.dart';
import 'orders_providers.dart';
import 'widgets/kilo_items_section.dart';
import 'widgets/order_total_bar.dart';
import 'widgets/speed_selector.dart';
import 'widgets/unit_item_picker_sheet.dart';
import 'widgets/unit_items_section.dart';

/// Create ([orderId] null) or edit (owner) an order.
class OrderFormScreen extends ConsumerWidget {
  const OrderFormScreen({super.key, this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final id = orderId;
    if (id == null) {
      return _OrderFormBody(key: const ValueKey('create'), existing: null);
    }

    final detail = ref.watch(orderDetailProvider(id));
    final order = detail.value;
    if (order != null && order.isEditable) {
      return _OrderFormBody(key: ValueKey('edit-$id'), existing: order);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderFormEditTitle)),
      body: order != null
          ? _NotEditable(onBack: () => context.pop())
          : detail.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(orderDetailProvider(id)),
              ),
              data: (_) => const SizedBox.shrink(),
            ),
    );
  }
}

class _NotEditable extends StatelessWidget {
  const _NotEditable({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.errorOrderNotEditable, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: Text(l10n.commonBack)),
          ],
        ),
      ),
    );
  }
}

class _OrderFormBody extends ConsumerStatefulWidget {
  const _OrderFormBody({super.key, required this.existing});

  final OrderDetail? existing;

  @override
  ConsumerState<_OrderFormBody> createState() => _OrderFormBodyState();
}

class _OrderFormBodyState extends ConsumerState<_OrderFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();
  bool _ready = false;
  bool _saving = false;
  bool _allowPop = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// Fills the draft once the first frame is done (providers must not change
  /// while the tree is building).
  void _initialize() {
    if (!mounted) return;
    final controller = ref.read(orderFormControllerProvider.notifier);
    final existing = widget.existing;
    if (existing != null) {
      controller.loadFrom(existing);
      _notes.text = existing.notes ?? '';
    } else {
      final auth = ref.read(authControllerProvider).value;
      if (auth is Authenticated && !auth.user.isOwner) {
        final outletId = auth.user.outlet?.id;
        if (outletId != null) controller.presetOutlet(outletId);
      }
    }
    setState(() => _ready = true);
  }

  bool get _isOwner {
    final auth = ref.read(authControllerProvider).value;
    return auth is Authenticated && auth.user.isOwner;
  }

  Future<void> _changeOutlet(String outletId) async {
    final draft = ref.read(orderFormControllerProvider);
    if (outletId == draft.outletId) return;
    if (draft.items.isNotEmpty) {
      final confirmed = await showConfirmDialog(
        context,
        title: context.l10n.orderFormChangeOutletTitle,
        message: context.l10n.orderFormChangeOutletBody,
      );
      if (!confirmed || !mounted) return;
    }
    ref.read(orderFormControllerProvider.notifier).setOutlet(outletId);
  }

  Future<void> _addUnitItem(List<LaundryService> unitServices) async {
    final draft = ref.read(orderFormControllerProvider);
    final input = await showUnitItemPickerSheet(
      context,
      services: unitServices,
      speed: draft.speed,
    );
    if (input == null || !mounted) return;
    if (draft.items.length >= maxOrderItems) {
      showAppSnackBar(context, context.l10n.orderFormTooManyItems);
      return;
    }
    ref
        .read(orderFormControllerProvider.notifier)
        .addUnitItem(
          input.service,
          quantity100: input.quantity100,
          length100: input.length100,
          width100: input.width100,
        );
  }

  Future<void> _editUnitItem(
    OrderDraftItem item,
    LaundryService service,
    List<LaundryService> unitServices,
  ) async {
    final draft = ref.read(orderFormControllerProvider);
    final input = await showUnitItemPickerSheet(
      context,
      services: unitServices,
      speed: draft.speed,
      service: service,
      existing: item,
    );
    if (input == null || !mounted) return;
    ref
        .read(orderFormControllerProvider.notifier)
        .updateUnitItem(
          item.uid,
          quantity100: input.quantity100,
          length100: input.length100,
          width100: input.width100,
        );
  }

  Future<void> _save(Map<String, LaundryService> servicesById) async {
    if (_saving) return;
    final l10n = context.l10n;
    final draft = ref.read(orderFormControllerProvider);

    if (!_formKey.currentState!.validate()) return;
    if (draft.outletId == null) {
      showAppSnackBar(context, l10n.orderFormOutletRequired);
      return;
    }
    if (draft.items.isEmpty) {
      showAppSnackBar(context, l10n.orderFormItemsRequired);
      return;
    }
    if (draft.items.length > maxOrderItems) {
      showAppSnackBar(context, l10n.orderFormTooManyItems);
      return;
    }
    final preview = previewOrder(draft, servicesById);
    if (draft.items.any((item) => !servicesById.containsKey(item.serviceId))) {
      showAppSnackBar(context, l10n.orderFormRemoveInactive);
      return;
    }
    if (preview.lines.values.any((line) => !line.isValid)) {
      showAppSnackBar(context, l10n.orderFormItemsInvalid);
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(orderRepositoryProvider);
      final existing = widget.existing;
      final OrderDetail saved;
      if (existing == null) {
        saved = await repository.create(draft, includeOutletId: _isOwner);
      } else {
        saved = await repository.update(existing.id, draft);
      }
      if (!mounted) return;
      _allowPop = true;
      invalidateOrderData(ref, updated: existing == null ? null : saved);
      final messenger = ScaffoldMessenger.of(context);
      final message = existing == null
          ? l10n.orderFormCreated(saved.orderNumber)
          : l10n.orderFormSaved;
      if (existing == null) {
        context.pushReplacement(AppRoutes.orderDetail(saved.id));
      } else {
        context.pop();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) _handleSaveError(e, draft.items, !_isEdit);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleSaveError(
    Object error,
    List<OrderDraftItem> items,
    bool creating,
  ) {
    final l10n = context.l10n;
    if (creating &&
        error is ApiException &&
        error.code == ApiErrorCode.networkError) {
      // The order may have been saved before the connection dropped.
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.orderFormCreateUnknownTitle),
          content: Text(l10n.orderFormCreateUnknownBody),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonOk),
            ),
          ],
        ),
      );
      return;
    }
    if (error is ApiException && error.code == ApiErrorCode.validationError) {
      // Details look like `items[2].quantity`: name the offending line.
      for (final detail in error.details) {
        final match = RegExp(r'items\[(\d+)\]').firstMatch(detail.field);
        final index = match == null ? null : int.tryParse(match.group(1)!);
        if (index != null && index < items.length) {
          showAppSnackBar(
            context,
            l10n.orderFormItemError(items[index].serviceName),
          );
          return;
        }
      }
    }
    showAppSnackBar(context, errorMessage(context, error));
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.l10n.orderFormDiscardTitle,
      message: context.l10n.orderFormDiscardBody,
      confirmLabel: context.l10n.orderFormDiscardConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit ? l10n.orderFormEditTitle : l10n.orderFormNewTitle,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final controller = ref.read(orderFormControllerProvider.notifier);
    final draft = ref.watch(orderFormControllerProvider);
    final outlets = ref.watch(outletsProvider);
    final isOwner = _isOwner;

    // Owners with exactly one active outlet get it automatically.
    final activeOutlets =
        outlets.value?.where((o) => o.isActive).toList() ?? const [];
    if (!_isEdit &&
        isOwner &&
        draft.outletId == null &&
        activeOutlets.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.presetOutlet(activeOutlets.first.id);
      });
    }

    final outletId = draft.outletId;
    final servicesAsync = outletId == null
        ? null
        : ref.watch(
            servicesProvider((outletId: outletId, includeInactive: false)),
          );
    final services = servicesAsync?.value ?? const <LaundryService>[];
    final servicesById = {for (final s in services) s.id: s};
    final kiloServices = services.where((s) => s.category.isKilo).toList();
    final unitServices = services.where((s) => !s.category.isKilo).toList();
    final preview = previewOrder(draft, servicesById);
    final estimate = preview.estimatedDoneAt(DateTime.now());

    // Edit mode: lines whose service is no longer active must be removed.
    final servicesReady = servicesAsync?.hasValue ?? false;
    final orphanItems = servicesReady
        ? draft.items
              .where((item) => !servicesById.containsKey(item.serviceId))
              .toList()
        : const <OrderDraftItem>[];
    final kiloItems = [
      for (final item in draft.items)
        if (servicesById[item.serviceId]?.category.isKilo ?? false) item,
    ];
    final unitItems = [
      for (final item in draft.items)
        if (servicesById.containsKey(item.serviceId) &&
            !(servicesById[item.serviceId]!.category.isKilo))
          item,
    ];

    final showOutletPicker = !_isEdit && isOwner && activeOutlets.length > 1;
    final dirty = controller.touched;

    return PopScope(
      canPop: _allowPop || (!dirty && !_saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit ? l10n.orderFormEditTitle : l10n.orderFormNewTitle,
          ),
        ),
        bottomNavigationBar: OrderTotalBar(
          total: preview.total,
          saving: _saving,
          onSave: () => _save(servicesById),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_isEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.orderFormEditNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (!_isEdit &&
                  isOwner &&
                  outlets.hasError &&
                  !outlets.hasValue) ...[
                ErrorView(
                  error: outlets.error!,
                  onRetry: () => ref.invalidate(outletsProvider),
                ),
                const SizedBox(height: 16),
              ],
              if (showOutletPicker) ...[
                OutletPickerField(
                  value: draft.outletId,
                  enabled: !_saving,
                  onChanged: _changeOutlet,
                ),
                const SizedBox(height: 16),
              ],
              SectionCard(
                title: l10n.orderFormCustomerSection,
                child: CustomerAutocompleteField(
                  customerId: draft.customerId,
                  name: draft.customerName,
                  phone: draft.customerPhone,
                  enabled: !_saving,
                  onSelectExisting: (customer) => controller.selectCustomer(
                    id: customer.id,
                    name: customer.name,
                    phone: customer.phone ?? '',
                  ),
                  onNewCustomer: (name, phone) =>
                      controller.setNewCustomer(name: name, phone: phone),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: l10n.orderFormSpeedSection,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SpeedSelector(
                      value: draft.speed,
                      enabled: !_saving,
                      onChanged: controller.setSpeed,
                    ),
                    if (estimate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.orderFormEstimatedDone(
                          formatDateTime(estimate, locale),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (outletId == null)
                SectionCard(child: Text(l10n.orderFormPickOutlet))
              else if (servicesAsync!.isLoading && !servicesReady)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (servicesAsync.hasError && !servicesReady)
                ErrorView(
                  error: servicesAsync.error!,
                  onRetry: () => ref.invalidate(servicesProvider),
                )
              else ...[
                if (orphanItems.isNotEmpty) ...[
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.orderFormInactiveWarning,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                          for (final item in orphanItems)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.warning_amber,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              title: Text(
                                item.serviceName,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: l10n.orderFormRemoveItem,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    controller.removeItem(item.uid),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SectionCard(
                  title: l10n.orderFormKiloSection,
                  child: kiloServices.isEmpty
                      ? Text(l10n.orderFormNoKiloServices)
                      : KiloItemsSection(
                          key: ValueKey('kilo-$outletId'),
                          services: kiloServices,
                          items: kiloItems,
                          speed: draft.speed,
                          enabled: !_saving,
                          onChanged: controller.setKiloQuantity,
                        ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: l10n.orderFormUnitSection,
                  child: UnitItemsSection(
                    items: unitItems,
                    servicesById: servicesById,
                    preview: preview,
                    enabled: !_saving,
                    onAdd: () => _addUnitItem(unitServices),
                    onEdit: (item) => _editUnitItem(
                      item,
                      servicesById[item.serviceId]!,
                      unitServices,
                    ),
                    onRemove: (item) => controller.removeItem(item.uid),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SectionCard(
                title: l10n.orderFormNotesSection,
                child: TextField(
                  controller: _notes,
                  enabled: !_saving,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: controller.setNotes,
                  decoration: InputDecoration(
                    hintText: l10n.orderFormNotesHint,
                  ),
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.orderFormPaidSwitch),
                  value: draft.isPaid,
                  onChanged: _saving ? null : controller.setPaid,
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
