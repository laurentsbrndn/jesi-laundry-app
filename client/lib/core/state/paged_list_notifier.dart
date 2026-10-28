import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/paginated.dart';
import 'paged_list_state.dart';

/// Base for searchable, paginated lists (20 per page). Subclasses implement
/// [fetchPage]; register them with `AsyncNotifierProvider.autoDispose`.
abstract class PagedListNotifier<T> extends AsyncNotifier<PagedListState<T>> {
  static const int pageSize = 20;
  static const Duration searchDebounce = Duration(milliseconds: 400);

  String _search = '';
  String? _outletId;
  Timer? _debounce;

  /// Incremented on every reload so a slow, outdated response is dropped.
  int _generation = 0;

  Future<Paginated<T>> fetchPage(
    int page, {
    required String search,
    String? outletId,
  });

  @override
  Future<PagedListState<T>> build() {
    ref.onDispose(() => _debounce?.cancel());
    return _loadFirst();
  }

  Future<PagedListState<T>> _loadFirst() async {
    final result = await fetchPage(1, search: _search, outletId: _outletId);
    return PagedListState(
      items: result.items,
      page: 1,
      hasMore: result.hasMore,
    );
  }

  /// Reloads from page 1 while keeping the current list visible (pull-to-refresh).
  Future<void> refresh() async {
    final generation = ++_generation;
    final next = await AsyncValue.guard(_loadFirst);
    if (!ref.mounted || generation != _generation) return;
    state = next;
  }

  /// Reloads from page 1 with a loading state. Subclasses call this after
  /// changing their own filters.
  Future<void> reload() async {
    final generation = ++_generation;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_loadFirst);
    if (!ref.mounted || generation != _generation) return;
    state = next;
  }

  /// Applies [query] after a short pause in typing.
  void setSearch(String query) {
    final text = query.trim();
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (text == _search) return;
      _search = text;
      reload();
    });
  }

  void setOutlet(String? outletId) {
    if (outletId == _outletId) return;
    _outletId = outletId;
    _debounce?.cancel();
    reload();
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    final generation = _generation;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final result = await fetchPage(
        current.page + 1,
        search: _search,
        outletId: _outletId,
      );
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        PagedListState(
          items: [...current.items, ...result.items],
          page: current.page + 1,
          hasMore: result.hasMore,
        ),
      );
    } catch (_) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
}
