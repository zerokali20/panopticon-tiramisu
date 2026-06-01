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
import 'package:panopticon/screens/boot_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// GraphRAG subsystem
import 'package:panopticon/data/graph_rag/graph_rag.dart';
import 'package:panopticon/core/services/model_manager.dart';
import 'package:panopticon/core/agents/agent_router.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Call runApp() immediately so Flutter renders the first frame right away.
  // GraphRAG bootstrap happens asynchronously inside AppStartup below.
  runApp(const PanopticonApp());
}

/// Bootstraps the GraphRAG engine:
///   1. Opens the ObjectBox vector store.
///   2. Creates the ContextRetrievalService with the stub embedding model.
///   3. Seeds both stores if they are empty (first launch).
Future<ContextRetrievalService> _bootstrapGraphRag() async {
  final service = await ContextRetrievalService.create(
    embeddingBridge: const DeterministicStubEmbeddingBridge(),
  );

  // Seed only if the graph is empty (idempotent on subsequent launches).
  final db = PanopticonDatabase.instance;
  final entityCount = await db.select(db.entities).get();
  if (entityCount.isEmpty) {
    await GraphSeeder(db.graphDao).seed();
  }

  // Seed the vector store if empty.
  final vectorService = await VectorSearchService.create();
  if (vectorService.chunkCount == 0) {
    await VectorSeeder(
      vectorService: vectorService,
      embeddingBridge: const DeterministicStubEmbeddingBridge(),
    ).seed();
  }

  return service;
}

class PanopticonApp extends StatelessWidget {
  const PanopticonApp({super.key});

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
      // AppStartup handles async bootstrap, then transitions to BootScreen
      home: const AppStartup(),
    );
  }
}

/// Runs GraphRAG init in the background while showing a minimal splash.
/// Once ready, transitions to BootScreen (for model download) → AppShell.
class AppStartup extends StatefulWidget {
  const AppStartup({super.key});
  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late final Future<ContextRetrievalService> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _bootstrapGraphRag();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ContextRetrievalService>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Startup error:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          // Show a branded splash while databases open
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security_rounded, size: 64, color: Color(0xFF38BDF8)),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing…',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        // Bootstrap done — hand off to BootScreen (model download check)
        // wrapped in ContextServiceProvider so the rest of the tree can access it.
        return ContextServiceProvider(
          service: snapshot.data!,
          child: const BootScreen(),
        );
      },
    );
  }
}

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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _authed = false;
  bool _callOpen = false;
  int _tab = 0; // 0=home, 1=calls, 2=settings, 3=profile

  AgentRouter? _agentRouter;

  void _unlock() => setState(() => _authed = true);
  void _signOut() => setState(() {
        _authed = false;
        _tab = 0;
      });
      
  void _openCall() async {
    final modelManager = ModelManager();
    final grammarString = await rootBundle.loadString('assets/grammars/sentry_grammar.gbnf');
    final sentryPath = await modelManager.sentryModelPath;
    final contextPath = await modelManager.contextModelPath;
    
    setState(() {
      _agentRouter = AgentRouter.create(
        sentryModelPath: sentryPath,
        contextModelPath: contextPath,
        grammarString: grammarString,
      );
      _callOpen = true;
    });
  }
  
  void _closeCall() {
    _agentRouter?.dispose();
    _agentRouter = null;
    setState(() => _callOpen = false);
  }

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
                : _callOpen
                    ? CallOverlayScreen(
                        key: const ValueKey('call'), 
                        onBack: _closeCall,
                        agentRouter: _agentRouter,
                      )
                    : _buildMainContent(),
          ),

          // Bottom nav (only when authed and not in call)
          if (_authed && !_callOpen)
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
