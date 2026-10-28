import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/loading_button.dart';

/// Sticky bar of the order form: estimated total and the save button.
class OrderTotalBar extends StatelessWidget {
  const OrderTotalBar({
    super.key,
    required this.total,
    required this.saving,
    required this.onSave,
  });

  final int total;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.orderFormEstimatedTotal,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      formatCurrency(total),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              LoadingButton(
                onPressed: onSave,
                isLoading: saving,
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
