// ============================================================
// panopticon/data/graph_rag/objectbox/objectbox_store.dart
//
// Initialises and exposes the singleton ObjectBox Store.
//
// The Store is opened once at app startup and kept open for
// the duration of the process.  It is safe to share across
// Dart isolates by passing the Store.directoryPath or by
// using Store.attach() in a worker isolate.
// ============================================================

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'document_chunk.dart';

// The generated ObjectBox model descriptor.
// Produced by: dart run build_runner build
import '../../../objectbox.g.dart';

/// Singleton wrapper around the ObjectBox [Store].
///
/// Usage:
/// ```dart
/// final store = await ObjectBoxStore.instance;
/// final box  = store.documentChunkBox;
/// ```
class ObjectBoxStore {
  final Store _store;

  ObjectBoxStore._(this._store);

  static ObjectBoxStore? _instance;

  /// Returns (or lazily creates) the singleton [ObjectBoxStore].
  ///
  /// Must be called from an async context at least once before any
  /// other ObjectBox operation — typically in [main()] or an app
  /// lifecycle hook.
  static Future<ObjectBoxStore> get instance async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();
    final storePath = p.join(dir.path, 'panopticon_vector_store');

    // Ensure the directory exists (ObjectBox requires it pre-existing).
    await Directory(storePath).create(recursive: true);

    final store = await openStore(directory: storePath);
    _instance = ObjectBoxStore._(store);
    return _instance!;
  }

  // ── Box Accessors ──────────────────────────────────────────────

  /// The primary box for storing and querying [DocumentChunk] entities.
  Box<DocumentChunk> get documentChunkBox =>
      Box<DocumentChunk>(_store);

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Closes the underlying [Store].  Call this only during app shutdown
  /// (e.g., in a [WidgetsBindingObserver.didChangeAppLifecycleState]
  /// handler when the state is [AppLifecycleState.detached]).
  void close() {
    _store.close();
    _instance = null;
  }

  /// Exposes the raw [Store] for advanced use-cases (e.g., Queries
  /// built outside this wrapper, or passing to a background isolate).
  Store get rawStore => _store;
}
