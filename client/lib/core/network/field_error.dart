/// One entry of `error.details` in a VALIDATION_ERROR response.
class FieldError {
  const FieldError({required this.field, required this.rule, this.param});

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field']?.toString() ?? '',
      rule: json['rule']?.toString() ?? '',
      param: json['param']?.toString(),
    );
  }

  final String field;
  final String rule;

  /// Rule argument (e.g. the `8` of `min=8`). Optional; added by the server in B6.
  final String? param;
}
