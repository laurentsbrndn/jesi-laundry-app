import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../outlets/presentation/outlets_provider.dart';
import '../../outlets/presentation/widgets/outlet_filter_dropdown.dart';
import '../data/models/laundry_service.dart';
import 'services_provider.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  String? _selectedOutletId;

  /// Service ids with a request in flight (switch disabled meanwhile).
  final Set<String> _busy = {};

  Future<void> _setActive(LaundryService service, bool active) async {
    setState(() => _busy.add(service.id));
    try {
      await ref.read(catalogRepositoryProvider).update(service.id, {
        'is_active': active,
      });
      ref.invalidate(servicesProvider);
    } catch (e) {
      if (mounted) showAppSnackBar(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy.remove(service.id));
    }
  }

  Future<void> _delete(LaundryService service) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.servicesDeleteTitle,
      message: l10n.servicesDeleteBody(service.name),
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy.add(service.id));
    try {
      await ref.read(catalogRepositoryProvider).delete(service.id);
      ref.invalidate(servicesProvider);
      if (mounted) showAppSnackBar(context, l10n.servicesDeleted);
    } catch (e) {
      if (mounted) showAppSnackBar(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy.remove(service.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final outlets = ref.watch(outletsProvider);

    // Selected outlet, defaulting to the first active one.
    final list = outlets.value;
    final outletId =
        _selectedOutletId ??
        list?.where((o) => o.isActive).firstOrNull?.id ??
        list?.firstOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servicesTitle),
        actions: [
          OutletFilterDropdown(
            value: outletId,
            onChanged: (id) => setState(() => _selectedOutletId = id),
          ),
        ],
      ),
      floatingActionButton: outletId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.serviceNewFor(outletId)),
              icon: const Icon(Icons.add),
              label: Text(l10n.servicesAddUnit),
            ),
      body: outlets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(outletsProvider),
        ),
        data: (_) => outletId == null
            ? EmptyView(title: l10n.outletsEmpty)
            : _ServicesBody(
                outletId: outletId,
                busy: _busy,
                onToggle: _setActive,
                onDelete: _delete,
              ),
      ),
    );
  }
}

class _ServicesBody extends ConsumerWidget {
  const _ServicesBody({
    required this.outletId,
    required this.busy,
    required this.onToggle,
    required this.onDelete,
  });

  final String outletId;
  final Set<String> busy;
  final Future<void> Function(LaundryService, bool) onToggle;
  final Future<void> Function(LaundryService) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = (outletId: outletId, includeInactive: true);
    final services = ref.watch(servicesProvider(query));

    Future<void> refresh() async {
      ref.invalidate(servicesProvider(query));
      try {
        await ref.read(servicesProvider(query).future);
      } catch (_) {
        // The error state is rendered by the screen itself.
      }
    }

    return services.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(servicesProvider(query)),
      ),
      data: (items) {
        final kilo = items.where((s) => s.category.isKilo).toList();
        final units = items.where((s) => !s.category.isKilo).toList();
        final theme = Theme.of(context);
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              _SectionHeader(title: l10n.servicesSectionKilo),
              for (final service in kilo)
                _ServiceTile(
                  service: service,
                  outletId: outletId,
                  trailing: const Icon(Icons.chevron_right),
                ),
              _SectionHeader(title: l10n.servicesSectionUnit),
              if (units.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    l10n.servicesUnitEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final service in units)
                _ServiceTile(
                  service: service,
                  outletId: outletId,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: service.isActive,
                        onChanged: busy.contains(service.id)
                            ? null
                            : (value) => onToggle(service, value),
                      ),
                      PopupMenuButton<String>(
                        enabled: !busy.contains(service.id),
                        onSelected: (_) => onDelete(service),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.commonDelete),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.outletId,
    required this.trailing,
  });

  final LaundryService service;
  final String outletId;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final unit = service.pricingUnit.label(context);
    final badges = [
      if (service.isSystem) l10n.servicesBadgeSystem,
      if (!service.isActive) l10n.commonInactive,
    ];
    return Opacity(
      opacity: service.isActive ? 1 : 0.55,
      child: ListTile(
        isThreeLine: true,
        title: Text(
          badges.isEmpty
              ? service.name
              : '${service.name}  ·  ${badges.join(' · ')}',
        ),
        subtitle: Text(
          '${l10n.serviceSpeedRegular}: ${formatCurrency(service.regularPrice)}/$unit · ${l10n.commonDays(service.regularDurationDays)}\n'
          '${l10n.serviceSpeedExpress}: ${formatCurrency(service.expressPrice)}/$unit · ${l10n.commonDays(service.expressDurationDays)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: trailing,
        onTap: () => context.push(AppRoutes.serviceEdit(service.id, outletId)),
      ),
    );
  }
}
