import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../data/models/outlet.dart';
import 'outlets_provider.dart';

class OutletsScreen extends ConsumerWidget {
  const OutletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final outlets = ref.watch(outletsProvider);

    Future<void> refresh() async {
      ref.invalidate(outletsProvider);
      try {
        await ref.read(outletsProvider.future);
      } catch (_) {
        // The error state is rendered by the screen itself.
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.outletsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.outletNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.outletsAdd),
      ),
      body: outlets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(outletsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: refresh,
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 360,
                      child: EmptyView(title: l10n.outletsEmpty),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _OutletTile(outlet: items[index]),
                ),
        ),
      ),
    );
  }
}

class _OutletTile extends StatelessWidget {
  const _OutletTile({required this.outlet});

  final Outlet outlet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final address = outlet.address?.trim() ?? '';
    return Opacity(
      opacity: outlet.isActive ? 1 : 0.55,
      child: ListTile(
        leading: const Icon(Icons.store_outlined),
        title: Text('${outlet.code} · ${outlet.name}'),
        subtitle: address.isEmpty
            ? null
            : Text(address, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: outlet.isActive
            ? const Icon(Icons.chevron_right)
            : Text(l10n.commonInactive),
        onTap: () => context.push(AppRoutes.outletEdit(outlet.id)),
      ),
    );
  }
}
