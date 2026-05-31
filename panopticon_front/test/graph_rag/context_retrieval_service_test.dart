// ============================================================
// test/graph_rag/context_retrieval_service_test.dart
//
// Deterministic unit tests for the GraphRAG subsystem.
//
// These tests run entirely in-process with:
//   • An in-memory Drift database (NativeDatabase.memory())
//   • The DeterministicStubEmbeddingBridge (no model required)
//   • An in-memory ObjectBox store
//
// Covers the two verification scenarios from implementation.md §4:
//   Scenario A — True Corporate Identity (expected: LOW RISK / verified)
//   Scenario B — Impersonation Spoof     (expected: HIGH RISK / impersonation)
// ============================================================

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panopticon/data/graph_rag/graph_rag.dart';

// ── Helpers ────────────────────────────────────────────────────

/// Opens an isolated in-memory Drift database for testing.
PanopticonDatabase _openTestDatabase() {
  // Override the singleton with a test-scoped in-memory instance.
  return PanopticonDatabase.forTesting(NativeDatabase.memory());
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  late PanopticonDatabase testDb;
  late GraphDao dao;

  setUp(() async {
    testDb = _openTestDatabase();
    dao = testDb.graphDao;

    // Seed the test database with Commercial Bank data (mirrors GraphSeeder).
    final cbId = await dao.upsertEntity(
      name: 'Commercial Bank of Ceylon PLC',
      type: EntityType.institution,
    );
    await dao.attachIdentifier(
      entityId: cbId,
      type: IdentifierType.phoneNumber,
      value: '+94112345678', // Scenario A's trusted number
      label: 'Fraud Hotline',
    );

    // Seed a different, unrelated entity to own the spoofed number.
    final telecomId = await dao.upsertEntity(
      name: 'Dialog Axiata PLC',
      type: EntityType.institution,
    );
    await dao.attachIdentifier(
      entityId: telecomId,
      type: IdentifierType.phoneNumber,
      value: '+94779876543', // Scenario B's spoofed mobile number
      label: 'Dialog Customer Care',
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  // ── Scenario A ─────────────────────────────────────────────────

  group('Scenario A — True Corporate Identity', () {
    test('verified status when number maps to claimed institution', () async {
      final result = await dao.verifyIncomingMetadata(
        '+94112345678',
        'Commercial Bank',
      );

      expect(result.status, VerificationStatus.verified);
      expect(result.resolvedCallerEntity?.name,
          contains('Commercial Bank'));
      expect(result.structuralSummary, contains('VERIFIED'));
    });

    test('structuralSummary includes phone number', () async {
      final result = await dao.verifyIncomingMetadata(
        '+94112345678',
        'Commercial Bank of Ceylon PLC',
      );
      expect(result.structuralSummary, contains('+94112345678'));
    });
  });

  // ── Scenario B ─────────────────────────────────────────────────

  group('Scenario B — Impersonation Spoof', () {
    test('impersonationDetected when number belongs to a different entity',
        () async {
      final result = await dao.verifyIncomingMetadata(
        '+94779876543', // Dialog number
        'Commercial Bank', // But claims to be Commercial Bank
      );

      expect(result.status, VerificationStatus.impersonationDetected);
      expect(result.resolvedCallerEntity?.name, contains('Dialog'));
      expect(result.claimedEntity?.name, contains('Commercial Bank'));
      expect(result.structuralSummary, contains('IMPERSONATION'));
    });
  });

  // ── Unknown Caller ─────────────────────────────────────────────

  group('Unknown caller', () {
    test('returns unknownCaller for a number not in the graph', () async {
      final result = await dao.verifyIncomingMetadata(
        '+94700000000', // Not seeded
        'Commercial Bank',
      );
      expect(result.status, VerificationStatus.unknownCaller);
    });
  });

  // ── Phone number normalisation ──────────────────────────────────

  group('Phone number normalisation', () {
    test('strips formatting characters before lookup', () async {
      // "+94 11 234-5678" → "+94112345678" (matches Scenario A seed)
      final result = await dao.verifyIncomingMetadata(
        '+94 11 234-5678',
        'Commercial Bank',
      );
      expect(result.status, VerificationStatus.verified);
    });
  });

  // ── Graph traversal ────────────────────────────────────────────

  group('Graph traversal', () {
    test('traverseGraph returns empty list from isolated node', () async {
      final cbId = (await (testDb.select(testDb.entities)
                ..where((t) => t.name.equals('Commercial Bank of Ceylon PLC')))
              .getSingleOrNull())
          ?.id;

      expect(cbId, isNotNull);
      final reachable =
          await dao.traverseGraph(cbId!, maxHops: 2);
      // No relationships seeded in this test — expect empty.
      expect(reachable, isEmpty);
    });
  });
}
