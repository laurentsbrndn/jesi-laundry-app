import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/models/outlet.dart';
import '../data/outlet_repository.dart';

final outletRepositoryProvider = Provider<OutletRepository>(
  (ref) => OutletRepository(ref.watch(dioProvider)),
);

/// All outlets, including inactive ones. Invalidate after every mutation.
final outletsProvider = FutureProvider.autoDispose<List<Outlet>>(
  (ref) => ref.watch(outletRepositoryProvider).list(),
  retry: (_, _) => null,
);
