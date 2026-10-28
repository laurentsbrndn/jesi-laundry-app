import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n_extension.dart';
import '../../../core/widgets/empty_view.dart';

// PLACEHOLDER (F3): replaced by the real order list in F5.
class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ordersPlaceholderTitle)),
      body: EmptyView(
        icon: Icons.receipt_long_outlined,
        title: l10n.ordersPlaceholderMessage,
      ),
    );
  }
}
