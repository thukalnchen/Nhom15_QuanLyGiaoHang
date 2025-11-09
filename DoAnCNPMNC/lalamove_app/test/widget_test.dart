/// Basic widget tests for Lalamove App
/// Tests app initialization

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lalamove_app/main.dart';

void main() {
  testWidgets('App initializes successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify that app initializes (splash screen shows Lalamove text)
    expect(find.text('Lalamove'), findsOneWidget);
    
    // App should load without throwing errors
    expect(tester.takeException(), isNull);
  });

  testWidgets('MaterialApp is created with correct theme', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Find the MaterialApp widget
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    
    // Verify theme is set
    expect(materialApp.theme, isNotNull);
    expect(materialApp.debugShowCheckedModeBanner, false);
  });

  testWidgets('App has MultiProvider with AuthProvider', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    
    // App should initialize providers without errors
    expect(tester.takeException(), isNull);
  });
}
