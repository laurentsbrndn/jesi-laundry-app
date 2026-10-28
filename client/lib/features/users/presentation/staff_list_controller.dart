import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/network/paginated.dart';
import '../../../core/state/paged_list_notifier.dart';
import '../../../core/state/paged_list_state.dart';
import '../../auth/data/models/app_user.dart';
import '../data/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(dioProvider)),
);

final staffListControllerProvider =
    AsyncNotifierProvider.autoDispose<
      StaffListController,
      PagedListState<AppUser>
    >(StaffListController.new, retry: (_, _) => null);

class StaffListController extends PagedListNotifier<AppUser> {
  @override
  Future<Paginated<AppUser>> fetchPage(
    int page, {
    required String search,
    String? outletId,
  }) {
    return ref
        .read(userRepositoryProvider)
        .list(
          page: page,
          limit: PagedListNotifier.pageSize,
          search: search,
          outletId: outletId,
        );
  }
}

/// A single staff member, loaded with `GET /users/:id`.
final staffDetailProvider = FutureProvider.autoDispose.family<AppUser, String>(
  (ref, id) => ref.watch(userRepositoryProvider).get(id),
  retry: (_, _) => null,
);
