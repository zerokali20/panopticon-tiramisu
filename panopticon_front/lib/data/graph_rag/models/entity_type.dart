// ============================================================
// panopticon/data/graph_rag/models/entity_type.dart
//
// Enumerates the node types modelled in the local knowledge graph.
// Any change here must be mirrored in the Drift TextColumn converter
// below and in the ObjectBox schema if you add a cross-reference.
// ============================================================

/// Represents the semantic class of a graph node (entity).
enum EntityType {
  /// A financial institution, telecom operator, government body, or
  /// any corporate entity that can own identifiers.
  institution,

  /// A natural person – employee, contact, or family member.
  person,

  /// A financial account (bank account, credit card, wallet).
  account,

  /// A scheduled meeting, appointment, or calendar occurrence.
  event,
}

/// Typed converter: persists [EntityType] as a plain string in SQLite
/// so that the DB remains human-readable without an integer mapping.
extension EntityTypeExtension on EntityType {
  String toDbValue() => name; // e.g. 'institution'

  static EntityType fromDbValue(String raw) => EntityType.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => throw ArgumentError('Unknown EntityType: $raw'),
      );
}
