import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_extension.dart';

enum UserRole {
  owner('owner'),
  staff('staff');

  const UserRole(this.value);

  final String value;

  bool get isOwner => this == UserRole.owner;
  bool get isStaff => this == UserRole.staff;

  /// An unknown value falls back to [staff], the least privileged role.
  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.staff,
    );
  }

  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      UserRole.owner => l10n.userRoleOwner,
      UserRole.staff => l10n.userRoleStaff,
    };
  }
}
