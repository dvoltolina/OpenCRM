import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/core/providers/providers.dart';
import 'package:the_scheduler/core/ui/components/gradient_button.dart';
import 'package:the_scheduler/modules/auth/presentation/join_with_code_page.dart';

import '../../../helpers/test_data_factories.dart';

void main() {
  group('JoinWithCodePage Widget', () {
    testWidgets('shows code input field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Should show join code input
      expect(find.text('Join Code'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows all required input fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Should show all input fields
      expect(find.text('Join Code'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows title and subtitle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.text('Join a Business'), findsOneWidget);
      expect(
        find.textContaining('Enter the join code provided'),
        findsOneWidget,
      );
    });

    testWidgets('shows join button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.text('Join Business'), findsOneWidget);
      expect(find.byType(GradientButton), findsOneWidget);
    });

    testWidgets('shows back button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.text('Back to Login'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('submit button is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Should have the submit button
      final joinButton = find.text('Join Business');
      expect(joinButton, findsOneWidget);
    });

    testWidgets('allows text entry in all fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Enter text in code field
      final codeField = find.widgetWithText(TextFormField, 'Join Code');
      await tester.enterText(codeField, 'ABC123');
      await tester.pump();

      // Enter text in email field
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Enter text in name field
      final nameField = find.widgetWithText(TextFormField, 'Full Name');
      await tester.enterText(nameField, 'Test User');
      await tester.pump();

      // Enter text in password field
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Verify text was entered (visible in fields)
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('password field has visibility toggle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Find visibility toggle icons
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Find and tap visibility toggle
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Icon should change to visibility_off after toggle
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('code field has proper helper text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Check for helper text
      expect(find.text('6-8 character code'), findsOneWidget);
    });

    testWidgets('displays info card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(
        find.textContaining('Your join code was provided by your business'),
        findsOneWidget,
      );
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('shows helper text for code field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.text('6-8 character code'), findsOneWidget);
    });

    testWidgets('shows helper text for password field', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.text('Required if creating a new account'), findsOneWidget);
    });

    testWidgets('has proper icon decorations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Check for field icons
      expect(find.byIcon(Icons.vpn_key_outlined), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('shows header icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.byIcon(Icons.group_add_rounded), findsOneWidget);
    });

    testWidgets('form is scrollable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has gesture detector for keyboard dismissal', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Page should have gesture detection capability
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('respects theme configuration', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Should render without errors in dark mode
      expect(find.text('Join a Business'), findsOneWidget);
    });

    testWidgets('has app bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Join with Code'), findsOneWidget);
    });

    testWidgets('form has layout constraints', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      // Page should have constrained layout
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('all fields are enabled by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      final textFields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );

      for (final field in textFields) {
        expect(field.enabled, true);
      }
    });

    testWidgets('join button is enabled by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      final joinButton = tester.widget<GradientButton>(
        find.widgetWithText(GradientButton, 'Join Business'),
      );

      expect(joinButton.onPressed, isNotNull);
    });

    testWidgets('back button is enabled by default', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      final backButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Back to Login'),
      );

      expect(backButton.onPressed, isNotNull);
    });

    testWidgets('renders with proper padding', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('has scaffold layout', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(TestData.createTestConfig()),
          ],
          child: MaterialApp(
            home: const JoinWithCodePage(),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
