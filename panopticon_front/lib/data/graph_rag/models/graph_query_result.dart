// ============================================================
// panopticon/data/graph_rag/models/graph_query_result.dart
//
// Plain-data transfer objects produced by the Graph DAO and
// consumed by the ContextRetrievalService.  These types are
// intentionally kept dependency-free (no Drift, no ObjectBox)
// so that upper layers can be unit-tested in isolation.
// ============================================================

import 'entity_type.dart';
import 'identifier_type.dart';

/// A matched entity node returned from a graph lookup.
class EntityNode {
  /// Stable surrogate primary key (auto-increment integer from SQLite).
  final int id;

  /// Human-readable canonical name, e.g. "Commercial Bank of Ceylon".
  final String name;

  /// Semantic class of this node.
  final EntityType type;

  const EntityNode({
    required this.id,
    required this.name,
    required this.type,
  });

  @override
  String toString() =>
      'EntityNode(id=$id, name="$name", type=${type.name})';
}

/// A directed relationship edge between two [EntityNode]s.
class RelationshipEdge {
  /// The originating node's ID.
  final int sourceEntityId;

  /// The target node's ID.
  final int targetEntityId;

  /// Human-readable predicate, e.g. "EMPLOYED_BY", "ACCOUNTS_AT".
  final String relationshipType;

  const RelationshipEdge({
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.relationshipType,
  });

  @override
  String toString() =>
      'RelationshipEdge($sourceEntityId --[$relationshipType]--> $targetEntityId)';
}

/// Identifier hit: a concrete lookup key that was found in the graph.
class IdentifierHit {
  final int entityId;
  final IdentifierType type;
  final String value;

  const IdentifierHit({
    required this.entityId,
    required this.type,
    required this.value,
  });
}

// ---------------------------------------------------------------------------
// The main result envelope returned by verifyIncomingMetadata().
// ---------------------------------------------------------------------------

/// Describes the structural validity of an incoming call's claimed identity.
enum VerificationStatus {
  /// The phone number maps to the claimed institution — low risk.
  verified,

  /// The phone number resolves to a DIFFERENT entity than claimed — high risk.
  impersonationDetected,

  /// The phone number is completely unknown to the local graph.
  unknownCaller,

  /// The institution name itself is unrecognised.
  unknownInstitution,
}

/// Top-level result produced by [GraphDao.verifyIncomingMetadata].
class GraphVerificationResult {
  /// Structural verdict.
  final VerificationStatus status;

  /// Entity the phone number actually maps to (null if unknown).
  final EntityNode? resolvedCallerEntity;

  /// Entity the caller *claimed* to be (null if claim unrecognised).
  final EntityNode? claimedEntity;

  /// Outgoing edges from [resolvedCallerEntity] for contextual display.
  final List<RelationshipEdge> callerRelationships;

  /// Human-readable explanation for the LLM prompt injection.
  final String structuralSummary;

  const GraphVerificationResult({
    required this.status,
    required this.structuralSummary,
    this.resolvedCallerEntity,
    this.claimedEntity,
    this.callerRelationships = const [],
  });
}
