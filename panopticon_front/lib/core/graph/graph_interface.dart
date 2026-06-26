/// GraphInterface
/// ─────────────────────────────────────────────────────────────────────────────
/// Abstract interface for the SQLite/Drift relationship graph engine.
///
/// The graph models entity nodes (contacts, institutions, phone numbers)
/// and edges (relationships between them) to allow queries like:
///   "Does caller number X map to institution Y in the user's contact graph?"
///
/// Implementations:
///   StubGraphInterface  — deterministic fixture data for testing
///   DriftGraphInterface — (Track D/E) real Drift/SQLite graph queries
/// ─────────────────────────────────────────────────────────────────────────────
library;

class PhoneNumberNode {
  final String number;
  final String? institution;
  final String? countryCode;
  final bool isVerifiedContact;

  const PhoneNumberNode({
    required this.number,
    this.institution,
    this.countryCode,
    this.isVerifiedContact = false,
  });
}

abstract class GraphInterface {
  /// Resolves a phone number to its graph node, if known.
  /// Returns null if the number is not in the user's contact/institution graph.
  Future<PhoneNumberNode?> resolvePhoneNumber(String number);

  /// Returns a human-readable context sentence about the caller based on
  /// graph traversal — passed directly into the Context Agent prompt.
  Future<String?> getCallerContext(String callerNumber);

  Future<void> dispose();
}

class StubGraphInterface implements GraphInterface {
  // Simulated graph of trusted numbers the user's device "knows about"
  static const _knownNumbers = {
    '+94112480480': PhoneNumberNode(
      number: '+94112480480',
      institution: 'Commercial Bank of Ceylon',
      countryCode: 'LK',
      isVerifiedContact: true,
    ),
    '+94112221221': PhoneNumberNode(
      number: '+94112221221',
      institution: 'Dialog Axiata',
      countryCode: 'LK',
      isVerifiedContact: true,
    ),
  };

  @override
  Future<PhoneNumberNode?> resolvePhoneNumber(String number) async {
    await Future.delayed(const Duration(milliseconds: 40));
    return _knownNumbers[number];
  }

  @override
  Future<String?> getCallerContext(String callerNumber) async {
    await Future.delayed(const Duration(milliseconds: 40));
    final node = _knownNumbers[callerNumber];
    if (node == null) {
      return 'Caller number $callerNumber is NOT present in the user\'s '
          'verified contact graph. Origin is unknown.';
    }
    return 'Caller number $callerNumber resolves to ${node.institution} '
        '(${node.countryCode}), a verified contact.';
  }

  @override
  Future<void> dispose() async {}
}
