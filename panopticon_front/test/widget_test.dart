// ============================================================
// test/widget_test.dart
//
// Smoke test — verifies the AuthScreen mounts without crashing.
//
// The full app (PanopticonApp) requires ObjectBox + SQLite to be
// initialised asynchronously before runApp(), so it is not
// directly testable with pumpWidget.  This test exercises the
// first widget the user ever sees — the AuthScreen — in isolation.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:panopticon/screens/auth_screen.dart';
import 'package:panopticon/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('AuthScreen mounts without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            surface: AppColors.background,
            primary: Colors.white,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: AuthScreen(onUnlock: () {}),
      ),
    );

    // Auth screen should appear — it is the entry point before login.
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
