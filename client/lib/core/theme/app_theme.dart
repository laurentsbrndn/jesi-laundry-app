import 'package:material_ui/material_ui.dart';

typedef StatusColorPair = ({Color background, Color foreground});

/// Status and payment chip colors, defined once per brightness.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.received,
    required this.processing,
    required this.done,
    required this.pickedUp,
    required this.unpaid,
    required this.paid,
  });

  /// Maps statuses onto the color scheme; only [paid] (green) is custom.
  factory StatusColors.fromScheme(
    ColorScheme scheme, {
    required StatusColorPair paid,
  }) {
    return StatusColors(
      received: (
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      processing: (
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      done: (
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
      pickedUp: (
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
      unpaid: (
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
      paid: paid,
    );
  }

  final StatusColorPair received;
  final StatusColorPair processing;
  final StatusColorPair done;
  final StatusColorPair pickedUp;
  final StatusColorPair unpaid;
  final StatusColorPair paid;

  @override
  StatusColors copyWith({
    StatusColorPair? received,
    StatusColorPair? processing,
    StatusColorPair? done,
    StatusColorPair? pickedUp,
    StatusColorPair? unpaid,
    StatusColorPair? paid,
  }) {
    return StatusColors(
      received: received ?? this.received,
      processing: processing ?? this.processing,
      done: done ?? this.done,
      pickedUp: pickedUp ?? this.pickedUp,
      unpaid: unpaid ?? this.unpaid,
      paid: paid ?? this.paid,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    StatusColorPair mix(StatusColorPair a, StatusColorPair b) => (
      background: Color.lerp(a.background, b.background, t)!,
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
    );
    return StatusColors(
      received: mix(received, other.received),
      processing: mix(processing, other.processing),
      done: mix(done, other.done),
      pickedUp: mix(pickedUp, other.pickedUp),
      unpaid: mix(unpaid, other.unpaid),
      paid: mix(paid, other.paid),
    );
  }
}

abstract final class AppTheme {
  static const Color _seed = Color(0xFF0277BD);
  static const double _radius = 12;

  static const StatusColorPair _paidLight = (
    background: Color(0xFFC8E6C9),
    foreground: Color(0xFF1B5E20),
  );
  static const StatusColorPair _paidDark = (
    background: Color(0xFF1B5E20),
    foreground: Color(0xFFC8E6C9),
  );

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
      ),
      cardTheme: CardThemeData(shape: shape),
      extensions: [
        StatusColors.fromScheme(
          scheme,
          paid: brightness == Brightness.light ? _paidLight : _paidDark,
        ),
      ],
    );
  }
}
