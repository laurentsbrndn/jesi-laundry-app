/// One entry of `error.details` in a VALIDATION_ERROR response.
class FieldError {
  const FieldError({required this.field, required this.rule});

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field'] as String? ?? '',
      rule: json['rule'] as String? ?? '',
    );
  }

  final String field;
  final String rule;
}
