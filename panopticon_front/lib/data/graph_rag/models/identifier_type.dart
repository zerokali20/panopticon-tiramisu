// ============================================================
// panopticon/data/graph_rag/models/identifier_type.dart
//
// Enumerates the concrete lookup-key types stored in the
// Identifiers table.  These are the values extracted from
// incoming call metadata and matched against the known graph.
// ============================================================

/// The concrete type of a lookup indicator tied to an [Entity].
enum IdentifierType {
  /// E.164-formatted telephone number, e.g. "+94112345678".
  phoneNumber,

  /// RFC-5322 email address, e.g. "fraud@commercialbank.lk".
  emailAddress,

  /// Partial or full account / card number, e.g. "XXXX-1234".
  accountNumber,

  /// Website domain / URL fragment, e.g. "commercialbank.lk".
  domain,

  /// Full legal name or alias, used for soft-matching.
  displayName,
}

extension IdentifierTypeExtension on IdentifierType {
  String toDbValue() => name;

  static IdentifierType fromDbValue(String raw) =>
      IdentifierType.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => throw ArgumentError('Unknown IdentifierType: $raw'),
      );
}
