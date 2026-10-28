import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_state.dart';
import '../../outlets/presentation/widgets/outlet_filter_dropdown.dart';
import '../data/models/dashboard_summary.dart';
import 'dashboard_providers.dart';
import 'widgets/category_breakdown.dart';
import 'widgets/operational_cards.dart';
import 'widgets/range_selector.dart';
import 'widgets/series_chart.dart';
import 'widgets/status_breakdown.dart';
import 'widgets/summary_cards.dart';
import 'widgets/unit_service_breakdown.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Last loaded summary, kept on screen while a new range or outlet loads so
  /// the page does not blink empty.
  DashboardSummary? _previous;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final selection = ref.watch(dashboardSelectionProvider);
    final query = ref.watch(dashboardQueryProvider);
    final async = ref.watch(dashboardProvider(query));
    final auth = ref.watch(authControllerProvider).value;
    final isOwner = auth is Authenticated && auth.user.isOwner;

    if (async.hasValue) _previous = async.value;
    final summary = async.value ?? (async.hasError ? null : _previous);
    // Revenue is shown only to owners and only when the server sent it.
    final showRevenue = isOwner && (summary?.hasRevenue ?? false);

    Future<void> refresh() async {
      ref.invalidate(dashboardProvider(query));
      try {
        await ref.read(dashboardProvider(query).future);
      } catch (_) {
        // The error state is rendered by the screen itself.
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          if (isOwner)
            OutletFilterDropdown(
              value: selection.outletId,
              allowAll: true,
              onChanged: (id) =>
                  ref.read(dashboardSelectionProvider.notifier).setOutlet(id),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SizedBox(height: 8),
            RangeSelector(
              value: selection.range,
              onChanged: (range) =>
                  ref.read(dashboardSelectionProvider.notifier).setRange(range),
            ),
            SizedBox(
              height: 4,
              child: async.isLoading
                  ? const LinearProgressIndicator(minHeight: 2)
                  : null,
            ),
            if (async.hasError && summary == null)
              SizedBox(
                height: 360,
                child: ErrorView(
                  error: async.error!,
                  onRetry: () => ref.invalidate(dashboardProvider(query)),
                ),
              )
            else if (summary == null)
              const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.dashboardPeriod(
                        formatDateTime(summary.from, locale),
                        formatDateTime(summary.to, locale),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OperationalCards(
                      stat: summary.operational,
                      showAmount: isOwner,
                    ),
                    const SizedBox(height: 16),
                    if (summary.totals.orders == 0)
                      SizedBox(
                        height: 240,
                        child: EmptyView(
                          icon: Icons.insights_outlined,
                          title: l10n.dashboardEmpty,
                        ),
                      )
                    else ...[
                      SummaryCards(summary: summary, showRevenue: showRevenue),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: l10n.dashboardChartTitle,
                        child: SeriesChart(
                          summary: summary,
                          showRevenue: showRevenue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        title: l10n.dashboardByCategory,
                        child: CategoryBreakdown(
                          summary: summary,
                          showRevenue: showRevenue,
                        ),
                      ),
                      if (summary.byUnitService.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SectionCard(
                          title: l10n.dashboardByUnitService,
                          child: UnitServiceBreakdown(
                            stats: summary.byUnitService,
                            showRevenue: showRevenue,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SectionCard(
                        title: l10n.dashboardByStatus,
                        child: StatusBreakdown(stats: summary.byStatus),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
