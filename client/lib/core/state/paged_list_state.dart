/// Loaded pages of an infinite-scroll list.
class PagedListState<T> {
  const PagedListState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  PagedListState<T> copyWith({bool? isLoadingMore, bool? loadMoreFailed}) {
    return PagedListState(
      items: items,
      page: page,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}
