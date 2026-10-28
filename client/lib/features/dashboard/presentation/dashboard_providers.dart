import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../data/dashboard_repository.dart';
import '../data/models/dashboard_range.dart';
import '../data/models/dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

/// Key of [dashboardProvider]. Records have value equality.
typedef DashboardQuery = ({DashboardRange range, String? outletId});

/// The range and outlet the user picked. Lives as long as the app (so it
/// survives tab changes) and resets when another user signs in or out.
final dashboardSelectionProvider =
    NotifierProvider<DashboardSelection, DashboardQuery>(
      DashboardSelection.new,
    );

class DashboardSelection extends Notifier<DashboardQuery> {
  @override
  DashboardQuery build() {
    // Watching the user id rebuilds (and so resets) this state on login/logout.
    ref.watch(
      authControllerProvider.select((auth) {
        final value = auth.value;
        return value is Authenticated ? value.user.id : null;
      }),
    );
    return (range: DashboardRange.hours24, outletId: null);
  }

  void setRange(DashboardRange range) =>
      state = (range: range, outletId: state.outletId);

  /// Null means all outlets.
  void setOutlet(String? outletId) =>
      state = (range: state.range, outletId: outletId);
}

/// The query actually sent: staff never filter by outlet.
final dashboardQueryProvider = Provider<DashboardQuery>((ref) {
  final selection = ref.watch(dashboardSelectionProvider);
  final auth = ref.watch(authControllerProvider).value;
  final isOwner = auth is Authenticated && auth.user.isOwner;
  return isOwner ? selection : (range: selection.range, outletId: null);
});

final dashboardProvider = FutureProvider.autoDispose
    .family<DashboardSummary, DashboardQuery>(
      (ref, query) => ref
          .watch(dashboardRepositoryProvider)
          .get(query.range, outletId: query.outletId),
      retry: (_, _) => null,
    );
