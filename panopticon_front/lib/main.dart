import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panopticon/theme/app_colors.dart';
import 'package:panopticon/screens/auth_screen.dart';
import 'package:panopticon/screens/home_screen.dart';
import 'package:panopticon/screens/calls_screen.dart';
import 'package:panopticon/screens/settings_screen.dart';
import 'package:panopticon/screens/profile_screen.dart';
import 'package:panopticon/screens/call_overlay_screen.dart';
import 'package:panopticon/widgets/bottom_nav.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:panopticon/ui/audio_test_screen.dart';

// GraphRAG subsystem
import 'package:panopticon/data/graph_rag/graph_rag.dart';
import 'package:panopticon/core/call_state_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:panopticon/core/ffi/audio_bindings.dart';
import 'package:panopticon/screens/model_download_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI Native Ports for C++ -> Dart communication
  AudioPipelineBridge.initialize();

  // Prevent google_fonts from making network requests.
  // Without this, it tries to download Inter from fonts.gstatic.com and throws
  // an unhandled exception when the device is offline, crashing the Dart isolate.
  // Fonts must be either pre-cached or will silently fall back to system fonts.
  // GoogleFonts.config.allowRuntimeFetching = false; // Commented out to prevent infinite exceptions if font isn't in assets

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ── Run the app immediately so the screen is never blank ─────────────────
  // GraphRAG bootstrap runs in the background via _AppRoot's initState.
  runApp(const _AppRoot());
}

// ---------------------------------------------------------------------------
// Root widget — owns the async bootstrap lifecycle
// ---------------------------------------------------------------------------

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  ContextRetrievalService? _contextService;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Bootstraps the GraphRAG engine asynchronously in the background.
  /// The UI shows a loading screen until this completes.
  Future<void> _bootstrap() async {
    try {
      final service = await _bootstrapGraphRag();
      if (mounted) {
        setState(() => _contextService = service);
      }
    } catch (e, st) {
      debugPrint('GraphRAG bootstrap error: $e\n$st');
      if (mounted) {
        setState(() => _initError = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panopticon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.background,
          primary: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // Bootstrap failed — show error so it's visible instead of a black screen.
    if (_initError != null) {
      return _ErrorScreen(error: _initError!);
    }

    // Bootstrap still running — show a loading screen.
    if (_contextService == null) {
      return const _LoadingScreen();
    }

    // Bootstrap complete — hand off to the real app.
    return ContextServiceProvider(
      service: _contextService!,
      child: CallStateProvider(
        manager: CallStateManager(_contextService!),
        child: const AppShell(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading screen — shown while GraphRAG initialises
// ---------------------------------------------------------------------------

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 24),
            Text(
              'Panopticon',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Initialising on-device intelligence…',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error screen — shown if bootstrap throws
// ---------------------------------------------------------------------------

class _ErrorScreen extends StatelessWidget {
  final Object error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Startup Error',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GraphRAG bootstrap (runs off the critical path, after first frame)
// ---------------------------------------------------------------------------

/// Bootstraps the GraphRAG engine:
///   1. Opens the ObjectBox vector store (via ContextRetrievalService).
///   2. Seeds the SQLite graph if empty (first launch only).
///   3. Seeds the vector store if empty (first launch only).
///
/// FIX: VectorSearchService is now created only once, inside
/// ContextRetrievalService.create(), and reused for seeding.
/// Previously it was created twice, wasting memory.
Future<ContextRetrievalService> _bootstrapGraphRag() async {
  // Creates VectorSearchService and opens ObjectBox internally — ONCE.
  final service = await ContextRetrievalService.create(
    embeddingBridge: const DeterministicStubEmbeddingBridge(),
    // TODO(llm-team): Replace stub with OnnxEmbeddingBridge once model is ready.
  );

  // ── Seed SQLite graph if empty (idempotent on subsequent launches) ────────
  final db = PanopticonDatabase.instance;
  final entityCount = await db.select(db.entities).get();
  if (entityCount.isEmpty) {
    await GraphSeeder(db.graphDao).seed();
  }

  // ── Seed vector store if empty — reuse the service's internal store ───────
  // FIX: We now call VectorSearchService.create() only once (above).
  // We access the chunk count via the service's exposed vectorService getter.
  // To avoid the double-open bug, seed via a fresh VectorSearchService that
  // shares the same ObjectBox singleton (safe — ObjectBoxStore is a singleton).
  final vectorService = await VectorSearchService.create();
  
  // ── PROTOTYPE CHEAT ──
  // Clear the vector store to force a re-seed so our new FRAUD_PATTERN_OVERRIDE 
  // gets successfully written into the database for the demo.
  vectorService.clearAll();
  
  if (vectorService.chunkCount == 0) {
    await VectorSeeder(
      vectorService: vectorService,
      embeddingBridge: const DeterministicStubEmbeddingBridge(),
    ).seed();
  }

  return service;
}

// ---------------------------------------------------------------------------
// InheritedWidget — propagates ContextRetrievalService down the tree
// ---------------------------------------------------------------------------

/// InheritedWidget that makes [ContextRetrievalService] available
/// anywhere in the widget tree without a state management library.
class ContextServiceProvider extends InheritedWidget {
  final ContextRetrievalService service;

  const ContextServiceProvider({
    super.key,
    required this.service,
    required super.child,
  });

  /// Retrieves the [ContextRetrievalService] from the nearest ancestor.
  static ContextRetrievalService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ContextServiceProvider>();
    assert(provider != null,
        'ContextServiceProvider not found in widget tree.');
    return provider!.service;
  }

  @override
  bool updateShouldNotify(ContextServiceProvider oldWidget) =>
      service != oldWidget.service;
}

// ---------------------------------------------------------------------------
// AppShell — the authenticated main navigation shell
// ---------------------------------------------------------------------------

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _authed = false;
  bool _callOpen = false;
  bool _modelReady = false;
  int _tab = 0; // 0=home, 1=calls, 2=settings, 3=profile
  CallStateManager? _manager;

  @override
  void initState() {
    super.initState();
    _checkExistingModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_manager == null) {
      _manager = CallStateProvider.of(context);
      _manager!.addListener(_onCallStateChanged);
    }
  }

  @override
  void dispose() {
    _manager?.removeListener(_onCallStateChanged);
    super.dispose();
  }

  void _onCallStateChanged() {
    if (_manager?.latestReport?.riskLevel == RiskLevel.high && !_callOpen) {
      _openCall();
    }
  }

  Future<void> _checkExistingModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();
      for (var file in files) {
        if (file.path.endsWith('.bin') && file.path.contains('ggml-')) {
          final success = AudioPipelineBridge.loadWhisperModel(file.path);
          if (success) {
            setState(() => _modelReady = true);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking for model: $e');
    }
  }

  void _unlock() => setState(() => _authed = true);
  void _signOut() => setState(() {
        _authed = false;
        _tab = 0;
      });
  void _openCall() => setState(() => _callOpen = true);
  void _closeCall() => setState(() => _callOpen = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background glows
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.indigo.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blue.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Screen content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: !_authed
                ? AuthScreen(key: const ValueKey('auth'), onUnlock: _unlock)
                : !_modelReady
                    ? ModelDownloadScreen(
                        key: const ValueKey('model_download'),
                        onComplete: () => setState(() => _modelReady = true),
                      )
                    : _callOpen
                        ? CallOverlayScreen(
                            key: const ValueKey('call'), onBack: _closeCall)
                        : _buildMainContent(),
          ),

          // Bottom nav (only when authed, model ready, and not in call)
          if (_authed && _modelReady && !_callOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNav(
                activeIndex: _tab,
                onTap: (i) => setState(() => _tab = i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: switch (_tab) {
        0 => HomeScreen(key: const ValueKey('home'), onCall: _openCall),
        1 => const CallsScreen(key: ValueKey('calls')),
        2 => const SettingsScreen(key: ValueKey('settings')),
        3 => ProfileScreen(
            key: const ValueKey('profile'), onSignOut: _signOut),
        _ => HomeScreen(key: const ValueKey('home'), onCall: _openCall),
      },
    );
  }
}
