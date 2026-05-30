// ============================================================
// panopticon/data/graph_rag/ingestion/vector_seeder.dart
//
// Mock vector store seeder — Phase 2.
//
// Populates ObjectBox with pre-chunked, embedding-ready truth
// documents representing:
//   • Corporate fraud advisories
//   • Bank security SMS templates
//   • Known phishing script patterns
//
// Zero-egress: all text is hard-coded constants.  In production,
// replace with an extraction layer that reads local email/calendar
// data via platform channels.
// ============================================================

import '../objectbox/document_chunk.dart';
import '../objectbox/vector_search_service.dart';
import 'document_chunking_pipeline.dart';
import 'embedding_bridge.dart';

/// Seeds the ObjectBox vector store with baseline truth documents.
///
/// Usage:
/// ```dart
/// final seeder = VectorSeeder(
///   vectorService: vectorService,
///   embeddingBridge: DeterministicStubEmbeddingBridge(),
/// );
/// await seeder.seed();
/// ```
class VectorSeeder {
  final VectorSearchService _vectorService;
  final EmbeddingBridge _embeddingBridge;

  const VectorSeeder({
    required VectorSearchService vectorService,
    required EmbeddingBridge embeddingBridge,
  })  : _vectorService = vectorService,
        _embeddingBridge = embeddingBridge;

  Future<void> seed() async {
    await _seedFraudAdvisories();
    await _seedBankCommunicationTemplates();
    await _seedPhishingPatterns();
  }

  // ── Fraud Advisories ──────────────────────────────────────────

  Future<void> _seedFraudAdvisories() async {
    const advisoryText = '''
COMMERCIAL BANK OF CEYLON PLC — SECURITY ADVISORY (Ref: CBSL/FA/2024/011)

Dear Valued Customer,

We wish to inform you of an increased pattern of voice phishing (vishing) 
attacks targeting Commercial Bank customers. Fraudsters are impersonating 
our fraud department using local mobile numbers beginning with +9477 and +9476.

IMPORTANT: Commercial Bank will NEVER call you from a mobile number. 
All official calls originate from our landline numbers beginning with +9411.

We will NEVER ask you to:
  • Confirm your OTP (One-Time Password) over the phone.
  • Provide your full credit card number, CVV, or expiry date.
  • Transfer funds to a "safe account" for security purposes.
  • Install remote access software.

If you receive a suspicious call claiming to be from Commercial Bank, 
please immediately hang up and call our official Fraud Hotline: +94112445566.

Report all suspicious calls to the Sri Lanka Police Cyber Crime Division: +94112421111.

Issued by: Commercial Bank of Ceylon PLC Security Operations Centre.
''';

    await _chunkAndStore(
      rawText: advisoryText,
      sourceType: DocumentSourceType.fraudAdvisory,
      sourceTitle: 'Commercial Bank Vishing Advisory 2024',
      config: ChunkingConfig.fraudAdvisory,
    );
  }

  // ── Bank Communication Templates ──────────────────────────────

  Future<void> _seedBankCommunicationTemplates() async {
    const smsTemplates = [
      '''
Your Commercial Bank credit card ending in 1234 has been temporarily 
blocked due to suspicious activity. To unblock, please visit your 
nearest branch or call +94112353353. Do not share your OTP with anyone.
Commercial Bank will never ask for your PIN or OTP.
''',
      '''
Bank of Ceylon: Your account has a pending transaction of Rs. 45,000 
from an unrecognised device. If this was not you, call BOC immediately 
on +94112446790. Our staff will NEVER request your card details by phone.
''',
      '''
Sampath Bank: Scheduled system maintenance on 15 Dec 2024, 02:00–04:00 AM.
Online banking services will be temporarily unavailable. 
We apologise for the inconvenience. Sampath Vishwa: +94115333333.
''',
    ];

    for (var i = 0; i < smsTemplates.length; i++) {
      await _chunkAndStore(
        rawText: smsTemplates[i],
        sourceType: DocumentSourceType.sms,
        sourceTitle: 'Bank SMS Template #${i + 1}',
        config: ChunkingConfig.sms,
      );
    }
  }

  // ── Phishing Pattern Library ──────────────────────────────────

  Future<void> _seedPhishingPatterns() async {
    const phishingPatterns = '''
KNOWN VISHING SCRIPT PATTERNS (Sri Lanka Financial Fraud Unit – 2024)

The following verbal patterns have been extracted from confirmed vishing calls:

Pattern 1 – Urgency/Freeze Trigger:
"Your account has been frozen due to suspicious activity. 
To prevent permanent closure, you must verify your OTP immediately."

Pattern 2 – Authority Impersonation:
"This is the fraud prevention team from [Bank Name]. 
We have detected a Rs. 150,000 unauthorized transfer from your account."

Pattern 3 – Safe Account Scam:
"For your security, we need you to transfer your funds to a temporary 
protected account. We will restore them once the investigation is complete."

Pattern 4 – Remote Access Request:
"Please download AnyDesk/TeamViewer so our technician can secure your device."

Pattern 5 – OTP Harvesting:
"A verification code has been sent to your phone. 
Please read it to me to confirm your identity."

All of the above are confirmed social engineering tactics. 
Legitimate financial institutions will never request OTPs, 
card details, or fund transfers over an unsolicited phone call.
''';

    await _chunkAndStore(
      rawText: phishingPatterns,
      sourceType: DocumentSourceType.fraudAdvisory,
      sourceTitle: 'Vishing Script Pattern Library 2024',
      config: ChunkingConfig.fraudAdvisory,
    );
  }

  // ── Private helper ────────────────────────────────────────────

  Future<void> _chunkAndStore({
    required String rawText,
    required int sourceType,
    required String sourceTitle,
    ChunkingConfig config = const ChunkingConfig(),
  }) async {
    final pipeline = DocumentChunkingPipeline(config: config);
    final chunks = pipeline.chunk(
      rawText: rawText,
      sourceType: sourceType,
      sourceTitle: sourceTitle,
    );

    // Fill embeddings using the bridge (stub or real model).
    final embeddedChunks = await _embeddingBridge.embedChunks(chunks);

    _vectorService.putChunks(embeddedChunks);
  }
}
