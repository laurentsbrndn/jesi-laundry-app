import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/catalog_repository.dart';
import '../data/models/laundry_service.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(dioProvider)),
);

/// Key of [servicesProvider]. Records have value equality, so equal queries
/// share one provider instance.
typedef ServicesQuery = ({String outletId, bool includeInactive});

/// Services of one outlet. The order form (F5) uses `includeInactive: false`;
/// the owner's management screens use `true`.
final servicesProvider = FutureProvider.autoDispose
    .family<List<LaundryService>, ServicesQuery>(
      (ref, query) => ref
          .watch(catalogRepositoryProvider)
          .list(
            outletId: query.outletId,
            includeInactive: query.includeInactive,
          ),
      retry: (_, _) => null,
    );
