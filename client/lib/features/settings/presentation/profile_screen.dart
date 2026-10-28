import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/error_message.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/server_field_errors.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/auth_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _serverErrors = ServerFieldErrors();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider).value;
    _name = TextEditingController(
      text: auth is Authenticated ? auth.user.name : '',
    );
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool _canSave(String currentName) {
    final text = _name.text.trim();
    return !_saving &&
        text.isNotEmpty &&
        text.length <= 100 &&
        text != currentName;
  }

  Future<void> _save() async {
    if (_saving) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .updateProfile(_name.text);
      ref.read(authControllerProvider.notifier).updateUser(user);
      if (!mounted) return;
      _name.text = user.name;
      showAppSnackBar(context, context.l10n.profileSaved);
    } catch (e) {
      if (!mounted) return;
      _serverErrors.replace(fieldErrorMessages(context, e));
      _formKey.currentState!.validate();
      showAppSnackBar(context, errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider).value;
    final user = auth is Authenticated ? auth.user : null;
    if (user == null) return const Scaffold();

    final outlet = user.outlet;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    onFieldSubmitted: (_) {
                      if (_canSave(user.name)) _save();
                    },
                    validator: _serverErrors.wrap(
                      'name',
                      FormValidators.all([
                        FormValidators.required(l10n),
                        FormValidators.maxLength(l10n, 100),
                      ]),
                    ),
                    decoration: InputDecoration(labelText: l10n.authNameLabel),
                  ),
                  const SizedBox(height: 16),
                  LoadingButton(
                    onPressed: _canSave(user.name) ? _save : null,
                    isLoading: _saving,
                    child: Text(l10n.profileSave),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                children: [
                  _InfoRow(label: l10n.authEmailLabel, value: user.email),
                  _InfoRow(
                    label: l10n.profileRoleLabel,
                    value: user.role.label(context),
                  ),
                  _InfoRow(
                    label: l10n.profileOutletLabel,
                    value: outlet == null
                        ? l10n.profileAllOutlets
                        : '${outlet.code} · ${outlet.name}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
