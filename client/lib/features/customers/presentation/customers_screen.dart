import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/paged_async_list.dart';
import '../../../core/widgets/search_field.dart';
import '../data/models/customer.dart';
import 'customers_list_controller.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(customersListControllerProvider);
    final controller = ref.read(customersListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customersTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchField(
              hint: l10n.customersSearchHint,
              onChanged: controller.setSearch,
            ),
          ),
          Expanded(
            child: PagedAsyncList<Customer>(
              value: state,
              onRefresh: controller.refresh,
              onLoadMore: controller.loadMore,
              onRetry: () => ref.invalidate(customersListControllerProvider),
              empty: EmptyView(
                icon: Icons.people_outline,
                title: l10n.customersEmptyTitle,
                message: l10n.customersEmptyMessage,
              ),
              itemBuilder: (context, customer) =>
                  _CustomerTile(customer: customer),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final lastOrderAt = customer.lastOrderAt;
    final phone = customer.phone?.trim() ?? '';
    return ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(customer.name),
      subtitle: Text(
        [
          if (phone.isNotEmpty) phone,
          if (lastOrderAt != null)
            l10n.customersLastOrder(
              formatRelativeTime(lastOrderAt, l10n, locale),
            ),
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.customerEdit(customer.id)),
    );
  }
}
