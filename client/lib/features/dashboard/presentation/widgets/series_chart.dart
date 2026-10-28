import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/quantity_format.dart';
import '../../data/models/dashboard_bucket.dart';
import '../../data/models/dashboard_range.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/models/series_point.dart';
import 'dashboard_metric.dart';

/// Bar chart of orders, kg or revenue over the range's buckets.
class SeriesChart extends StatefulWidget {
  const SeriesChart({
    super.key,
    required this.summary,
    required this.showRevenue,
  });

  final DashboardSummary summary;

  /// Owners only: offers the revenue metric.
  final bool showRevenue;

  @override
  State<SeriesChart> createState() => _SeriesChartState();
}

class _SeriesChartState extends State<SeriesChart> {
  static const double _leftReserved = 44;

  DashboardMetric _metric = DashboardMetric.orders;

  DashboardMetric get _effectiveMetric =>
      _metric == DashboardMetric.revenue && !widget.showRevenue
      ? DashboardMetric.orders
      : _metric;

  double _valueOf(SeriesPoint point, DashboardMetric metric) {
    return switch (metric) {
      DashboardMetric.orders => point.orders.toDouble(),
      DashboardMetric.weight => point.weightKg,
      DashboardMetric.revenue => (point.revenue ?? 0).toDouble(),
    };
  }

  /// Short X axis label for the bucket size.
  String _axisLabel(SeriesPoint point, Locale locale) {
    final tag = locale.languageCode;
    final time = point.wallClock;
    return switch (widget.summary.bucket) {
      DashboardBucket.fiveMinutes ||
      DashboardBucket.hour => DateFormat('HH:mm', tag).format(time),
      DashboardBucket.day => DateFormat('dd/MM', tag).format(time),
      DashboardBucket.month =>
        widget.summary.range == DashboardRange.all
            ? DateFormat('MMM yy', tag).format(time)
            : DateFormat.MMM(tag).format(time),
      DashboardBucket.year => DateFormat('yyyy', tag).format(time),
    };
  }

  /// Full label for the tooltip.
  String _tooltipLabel(SeriesPoint point, Locale locale) {
    final tag = locale.languageCode;
    final time = point.wallClock;
    return switch (widget.summary.bucket) {
      DashboardBucket.fiveMinutes ||
      DashboardBucket.hour => formatDateTime(time, locale),
      DashboardBucket.day => formatDate(time, locale),
      DashboardBucket.month => DateFormat.yMMMM(tag).format(time),
      DashboardBucket.year => DateFormat('yyyy', tag).format(time),
    };
  }

  String _valueText(double value, DashboardMetric metric, Locale locale) {
    final l10n = context.l10n;
    return switch (metric) {
      DashboardMetric.orders => l10n.dashboardOrdersCount(value.round()),
      DashboardMetric.weight =>
        '${formatQuantity(value, locale)} ${l10n.unitKg}',
      DashboardMetric.revenue => formatCurrency(value.round()),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final metric = _effectiveMetric;
    final points = widget.summary.series;
    final compact = NumberFormat.compact(locale: locale.languageCode);

    final values = [for (final p in points) _valueOf(p, metric)];
    final rawMax = values.fold<double>(0, (a, b) => a > b ? a : b);
    // Four even grid steps; all-zero data still draws the axis (0..4).
    final interval = (rawMax / 4).ceilToDouble().clamp(1.0, double.infinity);
    final maxY = interval * 4;
    // Show every n-th label once there are more than 12 bars.
    final labelStep = points.length > 12 ? (points.length / 8).ceil() : 1;
    final labelStyle = theme.textTheme.labelSmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DashboardMetric>(
          segments: [
            for (final value in DashboardMetric.values)
              if (value != DashboardMetric.revenue || widget.showRevenue)
                ButtonSegment(value: value, label: Text(value.label(context))),
          ],
          selected: {metric},
          onSelectionChanged: (selection) =>
              setState(() => _metric = selection.first),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = points.isEmpty
                  ? 12.0
                  : (constraints.maxWidth - _leftReserved) / points.length;
              final barWidth = (slot * 0.6).clamp(3.0, 22.0);
              return BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: scheme.outlineVariant, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _leftReserved,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(compact.format(value), style: labelStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= points.length ||
                              index % labelStep != 0) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _axisLabel(points[index], locale),
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = points[groupIndex];
                        return BarTooltipItem(
                          '${_tooltipLabel(point, locale)}\n${_valueText(rod.toY, metric, locale)}',
                          TextStyle(
                            color: scheme.onInverseSurface,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            width: barWidth,
                            color: scheme.primary,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(barWidth / 4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
