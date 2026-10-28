import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n_extension.dart';
import '../state/paged_list_state.dart';
import 'error_view.dart';

/// Infinite-scroll list with pull-to-refresh for a [PagedListState].
class PagedAsyncList<T> extends StatefulWidget {
  const PagedAsyncList({
    super.key,
    required this.value,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRetry,
    required this.empty,
  });

  final AsyncValue<PagedListState<T>> value;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final Widget empty;

  @override
  State<PagedAsyncList<T>> createState() => _PagedAsyncListState<T>();
}

class _PagedAsyncListState<T> extends State<PagedAsyncList<T>> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.hasClients && _controller.position.extentAfter < 300) {
        widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(error: error, onRetry: widget.onRetry),
      data: (data) {
        if (data.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: widget.empty,
                ),
              ),
            ),
          );
        }
        final hasFooter = data.isLoadingMore || data.loadMoreFailed;
        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView.builder(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: data.items.length + (hasFooter ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < data.items.length) {
                return widget.itemBuilder(context, data.items[index]);
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: data.loadMoreFailed
                      ? TextButton(
                          onPressed: widget.onLoadMore,
                          child: Text(context.l10n.commonRetry),
                        )
                      : const CircularProgressIndicator(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
