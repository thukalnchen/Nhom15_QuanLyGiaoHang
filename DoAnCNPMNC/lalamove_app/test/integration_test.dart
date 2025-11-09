import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lalamove_app/main.dart';

/// Integration Test Suite (Simplified)
/// 
/// NOTE: Full integration tests require a running backend and are
/// best performed manually. Use test_all_flows.ps1 for guided testing.
/// 
/// These are smoke tests to ensure the app initializes correctly.
void main() {
  group('APP INITIALIZATION', () {
    testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
      // Build app
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      // Verify splash screen
      expect(find.text('Lalamove'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('App has correct theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('MultiProvider is configured', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      
      // Providers should initialize without errors
      expect(tester.takeException(), isNull);
    });
  });

  group('ROUTING', () {
    testWidgets('Routes are defined', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.routes, isNotNull);
      expect(materialApp.routes!.isNotEmpty, true);
    });
  });

  group('SCREEN RENDERING', () {
    testWidgets('Splash screen renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      
      expect(find.text('Lalamove'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

// NOTE: For comprehensive flow testing, use:
// .\test_all_flows.ps1
//
// This script tests:
// - Authentication (Customer & Intake Staff login)
// - Customer order creation and management
// - Intake staff order processing
// - Navigation and routing
// - Profile management
// - Search and filtering
// - Error handling
//
// Run with backend server active for full functionality.
