// ============================================================
// panopticon/data/graph_rag/ingestion/graph_seeder.dart
//
// Mock ingestion seeder — Phase 1, Task 1.3.
//
// Seeds the local SQLite Knowledge Graph with a deterministic,
// realistic dataset modelling Sri Lankan financial institutions,
// their known hotline numbers, and key relationship edges.
//
// This seeder is idempotent: running it multiple times will NOT
// create duplicate rows (uses insertOnConflictUpdate).
//
// IMPORTANT: This seeder reads ONLY from hard-coded constants.
// It does NOT make network calls or read from external files.
// In production, replace the constants with an extraction layer
// that reads local Android Contacts / Calendar data via platform
// channels (also zero-egress).
// ============================================================

import '../db/graph_dao.dart';
import '../models/entity_type.dart';
import '../models/identifier_type.dart';

/// Populates the local Knowledge Graph with verified baseline data.
///
/// Call once during app first-launch or database migration:
/// ```dart
/// await GraphSeeder(PanopticonDatabase.instance.graphDao).seed();
/// ```
class GraphSeeder {
  final GraphDao _dao;

  GraphSeeder(this._dao);

  /// Runs the full seeding pipeline.
  Future<void> seed() async {
    await _seedInstitutions();
    await _seedPersons();
    await _seedRelationships();
  }

  // ── Institutions ──────────────────────────────────────────────

  Future<void> _seedInstitutions() async {
    // ── Commercial Bank of Ceylon ──────────────────────────────
    final cbId = await _dao.upsertEntity(
      name: 'Commercial Bank of Ceylon PLC',
      type: EntityType.institution,
    );
    await _dao.attachIdentifier(
      entityId: cbId,
      type: IdentifierType.phoneNumber,
      value: '+94112353353',
      label: 'Customer Service',
    );
    await _dao.attachIdentifier(
      entityId: cbId,
      type: IdentifierType.phoneNumber,
      value: '+94112445566',
      label: 'Fraud Hotline',
    );
    await _dao.attachIdentifier(
      entityId: cbId,
      type: IdentifierType.emailAddress,
      value: 'fraudalert@combank.lk',
      label: 'Fraud Alert Email',
    );
    await _dao.attachIdentifier(
      entityId: cbId,
      type: IdentifierType.domain,
      value: 'combank.lk',
    );

    // ── Bank of Ceylon ─────────────────────────────────────────
    final bocId = await _dao.upsertEntity(
      name: 'Bank of Ceylon',
      type: EntityType.institution,
    );
    await _dao.attachIdentifier(
      entityId: bocId,
      type: IdentifierType.phoneNumber,
      value: '+94112446790',
      label: 'Customer Care',
    );
    await _dao.attachIdentifier(
      entityId: bocId,
      type: IdentifierType.phoneNumber,
      value: '+94112481481',
      label: 'BOC Helpline',
    );
    await _dao.attachIdentifier(
      entityId: bocId,
      type: IdentifierType.domain,
      value: 'boc.lk',
    );

    // ── Sampath Bank ───────────────────────────────────────────
    final sampathId = await _dao.upsertEntity(
      name: 'Sampath Bank PLC',
      type: EntityType.institution,
    );
    await _dao.attachIdentifier(
      entityId: sampathId,
      type: IdentifierType.phoneNumber,
      value: '+94115333333',
      label: 'Sampath Vishwa',
    );
    await _dao.attachIdentifier(
      entityId: sampathId,
      type: IdentifierType.domain,
      value: 'sampath.lk',
    );

    // ── Sri Lanka Police — Fraud Bureau ────────────────────────
    final policeId = await _dao.upsertEntity(
      name: 'Sri Lanka Police – Cyber & Economic Crime Division',
      type: EntityType.institution,
    );
    await _dao.attachIdentifier(
      entityId: policeId,
      type: IdentifierType.phoneNumber,
      value: '+94112421111',
      label: 'Main Hotline',
    );
    await _dao.attachIdentifier(
      entityId: policeId,
      type: IdentifierType.phoneNumber,
      value: '119',
      label: 'Emergency',
    );

    // Store entity IDs as class-level fields for relationship seeding.
    _entityIds = {
      'commercial_bank': cbId,
      'bank_of_ceylon': bocId,
      'sampath_bank': sampathId,
      'sl_police': policeId,
    };
  }

  Map<String, int> _entityIds = {};

  // ── Persons ───────────────────────────────────────────────────

  Future<void> _seedPersons() async {
    // Mock personal contacts — simulates user's Android/iOS contact list.
    final momId = await _dao.upsertEntity(
      name: 'Mom',
      type: EntityType.person,
    );
    await _dao.attachIdentifier(
      entityId: momId,
      type: IdentifierType.phoneNumber,
      value: '+94771234567',
      label: 'Mobile',
    );

    final drId = await _dao.upsertEntity(
      name: 'Dr. Priya Perera',
      type: EntityType.person,
    );
    await _dao.attachIdentifier(
      entityId: drId,
      type: IdentifierType.phoneNumber,
      value: '+94112678901',
      label: 'Clinic',
    );

    _entityIds['mom'] = momId;
    _entityIds['dr_perera'] = drId;
  }

  // ── Relationships ─────────────────────────────────────────────

  Future<void> _seedRelationships() async {
    final cbId = _entityIds['commercial_bank'];
    final bocId = _entityIds['bank_of_ceylon'];
    final policeId = _entityIds['sl_police'];
    final momId = _entityIds['mom'];

    if (cbId == null || bocId == null || policeId == null || momId == null) {
      return; // Seeding order mismatch — should not happen.
    }

    // Commercial Bank is regulated by the Central Bank.
    // (Central Bank entity not seeded here for brevity — add as needed.)

    // Police coordinates with Commercial Bank on fraud cases.
    await _dao.createRelationship(
      sourceId: policeId,
      targetId: cbId,
      relationshipType: 'COORDINATES_WITH',
      metadata: '{"reason": "financial_fraud_response"}',
    );

    // Bank of Ceylon is a state bank — parent is the Government of SL.
    // Omitting the government entity here; add as a separate institution.

    // Mom has a savings account at Commercial Bank (mock).
    await _dao.createRelationship(
      sourceId: momId,
      targetId: cbId,
      relationshipType: 'ACCOUNTS_AT',
      metadata: '{"account_type": "savings"}',
    );
  }
}
