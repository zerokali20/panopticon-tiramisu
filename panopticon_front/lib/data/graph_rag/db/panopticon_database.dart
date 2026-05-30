// ============================================================
// panopticon/data/graph_rag/db/panopticon_database.dart
//
// Drift (SQLite) schema definition for the local Knowledge Graph.
//
// Code-generation step (run once after any schema change):
//   dart run build_runner build --delete-conflicting-outputs
//
// Required pubspec.yaml additions:
// dependencies:
//   drift: ^2.18.0
//   sqlite3_flutter_libs: ^0.5.0
//   path_provider: ^2.0.0
//   path: ^1.9.0
//
// dev_dependencies:
//   drift_dev: ^2.18.0
//   build_runner: ^2.4.0
// ============================================================

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'graph_dao.dart';

// ---------------------------------------------------------------------------
// Part directive wires in the generated code produced by drift_dev.
// ---------------------------------------------------------------------------
part 'panopticon_database.g.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  TABLE DEFINITIONS                                                       ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// Nodes of the local knowledge graph.
///
/// Each row represents a distinct real-world entity whose identity the
/// Sentry Agent can assert or challenge during a live call.
class Entities extends Table {
  /// Auto-incremented surrogate key.
  IntColumn get id => integer().autoIncrement()();

  /// Canonical display name (e.g. "Commercial Bank of Ceylon PLC").
  TextColumn get name => text().withLength(min: 1, max: 512)();

  /// Serialised [EntityType] enum value (string, never null).
  TextColumn get type => text().withLength(min: 1, max: 64)();

  /// ISO-8601 timestamp of when this node was ingested / last refreshed.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Lookup indicators anchored to an [Entity] node.
///
/// The [value] column carries a B-Tree index so that phone-number look-ups
/// during an active call execute in O(log n) time rather than a full scan.
class Identifiers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key back to the owning [Entity].
  IntColumn get entityId =>
      integer().references(Entities, #id, onDelete: KeyAction.cascade)();

  /// Serialised [IdentifierType] (string).
  TextColumn get type => text().withLength(min: 1, max: 64)();

  /// The concrete value being stored, e.g. "+94112345678".
  /// Indexed for millisecond-class lookup during live calls.
  /// (Index is created manually in PanopticonDatabase._createIndexes.)
  TextColumn get value => text().withLength(min: 1, max: 512)();

  /// Optional human-readable label, e.g. "Fraud Hotline".
  TextColumn get label => text().withLength(max: 256).nullable()();
}

/// Directed relationship edges of the graph.
///
/// Models predicates such as EMPLOYED_BY, ACCOUNTS_AT, FAMILY_MEMBER_OF.
/// Both [sourceId] and [targetId] carry an index to support fast traversal
/// in both directions without a secondary lookup.
class Relationships extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The originating node.
  IntColumn get sourceId =>
      integer().references(Entities, #id, onDelete: KeyAction.cascade)();

  /// The destination node.
  IntColumn get targetId =>
      integer().references(Entities, #id, onDelete: KeyAction.cascade)();

  /// Predicate label in SCREAMING_SNAKE_CASE.
  TextColumn get relationshipType =>
      text().withLength(min: 1, max: 128)();

  /// Optional metadata JSON blob (confidence score, source, etc.).
  TextColumn get metadata => text().nullable()();
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  TYPE CONVERTERS                                                         ║
// ╚══════════════════════════════════════════════════════════════════════════╝

// NOTE: Drift's generated code handles primitive types automatically.
// For custom enums we use raw TextColumn + manual mapping in the DAO
// to avoid requiring the converter to live in the generated part file,
// which keeps the schema file self-contained and easier to audit.

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  DATABASE CLASS                                                          ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// Singleton Drift database.  Access via [PanopticonDatabase.instance].
@DriftDatabase(
  tables: [Entities, Identifiers, Relationships],
  daos: [GraphDao],
)
class PanopticonDatabase extends _$PanopticonDatabase {
  // Private named constructor prevents direct instantiation.
  PanopticonDatabase._internal() : super(_openConnection());

  /// Test-only constructor that accepts an in-memory executor.
  /// Never call this in production code.
  @visibleForTesting
  PanopticonDatabase.forTesting(super.executor);

  static final PanopticonDatabase instance = PanopticonDatabase._internal();

  /// Schema version — bump this whenever you add/alter a table.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          // Future migration steps go here.
        },
      );

  /// Creates explicit B-Tree indexes that Drift's annotation system does
  /// not yet emit automatically via @ReferencedColumnIndex on non-FK cols.
  Future<void> _createIndexes() async {
    // Fast lookup index on Identifiers.value — critical hot-path.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_identifiers_value '
      'ON identifiers (value);',
    );
    // Secondary index for entity-scoped identifier look-ups.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_identifiers_entity_id '
      'ON identifiers (entity_id);',
    );
    // Traversal indexes on Relationships for both directions.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_relationships_source '
      'ON relationships (source_id);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_relationships_target '
      'ON relationships (target_id);',
    );
  }
}

// ---------------------------------------------------------------------------
// Lazy database connector — resolves the on-device file path at runtime.
// ---------------------------------------------------------------------------
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'panopticon_graph.sqlite'));
    return NativeDatabase(
      file,
      // Enable WAL mode for concurrent reads during voice processing.
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA foreign_keys=ON;');
        // Keep frequently-accessed index pages in memory.
        db.execute('PRAGMA cache_size=-8000;'); // ~8 MB page cache
        db.execute('PRAGMA synchronous=NORMAL;');
      },
    );
  });
}
