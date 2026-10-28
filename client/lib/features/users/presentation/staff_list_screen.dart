import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/paged_async_list.dart';
import '../../../core/widgets/search_field.dart';
import '../../auth/data/models/app_user.dart';
import '../../outlets/presentation/widgets/outlet_filter_dropdown.dart';
import 'staff_list_controller.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  String? _outletId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(staffListControllerProvider);
    final controller = ref.read(staffListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staffTitle),
        actions: [
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
        onPressed: () => context.push(AppRoutes.staffNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.staffAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchField(
              hint: l10n.staffSearchHint,
              onChanged: controller.setSearch,
            ),
          ),
          Expanded(
            child: PagedAsyncList<AppUser>(
              value: state,
              onRefresh: controller.refresh,
              onLoadMore: controller.loadMore,
              onRetry: () => ref.invalidate(staffListControllerProvider),
              empty: EmptyView(
                icon: Icons.badge_outlined,
                title: l10n.staffEmpty,
              ),
              itemBuilder: (context, user) => _StaffTile(user: user),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final outlet = user.outlet;
    return Opacity(
      opacity: user.isActive ? 1 : 0.55,
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(user.name),
        subtitle: Text(
          [user.email, if (outlet != null) outlet.code].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: user.isActive
            ? const Icon(Icons.chevron_right)
            : Text(l10n.commonInactive),
        onTap: () => context.push(AppRoutes.staffEdit(user.id)),
      ),
    );
  }
}
