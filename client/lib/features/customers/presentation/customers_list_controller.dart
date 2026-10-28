import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/paginated.dart';
import '../../../core/state/paged_list_notifier.dart';
import '../../../core/state/paged_list_state.dart';
import '../data/customer_repository.dart';
import '../data/models/customer.dart';

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.watch(dioProvider)),
);

final customersListControllerProvider =
    AsyncNotifierProvider.autoDispose<
      CustomersListController,
      PagedListState<Customer>
    >(CustomersListController.new, retry: (_, _) => null);

class CustomersListController extends PagedListNotifier<Customer> {
  @override
  Future<Paginated<Customer>> fetchPage(
    int page, {
    required String search,
    String? outletId,
  }) {
    return ref
        .read(customerRepositoryProvider)
        .list(page: page, limit: PagedListNotifier.pageSize, search: search);
  }
}

/// A single customer, loaded with `GET /customers/:id`.
final customerDetailProvider = FutureProvider.autoDispose
    .family<Customer, String>(
      (ref, id) => ref.watch(customerRepositoryProvider).get(id),
      retry: (_, _) => null,
    );
