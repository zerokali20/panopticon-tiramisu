// ============================================================
// panopticon/data/graph_rag/graph_rag.dart
//
// Barrel export file for the graph_rag subsystem.
//
// Import this single file to get access to all public API
// surfaces of the GraphRAG engine:
//
//   import 'package:panopticon/data/graph_rag/graph_rag.dart';
// ============================================================

// Models
export 'models/entity_type.dart';
export 'models/identifier_type.dart';
export 'models/graph_query_result.dart';

// Database (Drift)
export 'db/panopticon_database.dart';
export 'db/graph_dao.dart';

// ObjectBox
export 'objectbox/document_chunk.dart';
export 'objectbox/objectbox_store.dart';
export 'objectbox/vector_search_service.dart';

// Ingestion pipeline
export 'ingestion/document_chunking_pipeline.dart';
export 'ingestion/embedding_bridge.dart';
export 'ingestion/graph_seeder.dart';
export 'ingestion/vector_seeder.dart';

// Services
export 'services/discrepancy_report.dart';
export 'services/context_retrieval_service.dart';
export 'services/call_session_manager.dart';
