@Tags(['ai'])
/// Tests for automation widgets.
///
/// Agent AI-12: AI Dashboard & UI Components
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_scheduler/ai/automation/automation_rule.dart';
import 'package:the_scheduler/ai/widgets/automation/automation_widgets.dart';

void main() {
  AutomationRule _createRule({
    String name = 'Test Rule',
    bool isEnabled = true,
    AutomationTriggerType triggerType = AutomationTriggerType.noShowRisk,
    double threshold = 0.7,
    AutomationPriority priority = AutomationPriority.medium,
    int triggerCount = 10,
    int successCount = 8,
    int failureCount = 2,
  }) {
    return AutomationRule(
      id: 'rule-123',
      businessId: 'business-123',
      name: name,
      isEnabled: isEnabled,
      priority: priority,
      trigger: AutomationTriggerConfig(
        type: triggerType,
        threshold: threshold,
      ),
      actions: const [
        AutomationActionConfig(type: AutomationActionType.createTask),
      ],
      triggerCount: triggerCount,
      successCount: successCount,
      failureCount: failureCount,
      createdAt: DateTime.now(),
      createdBy: 'user-123',
    );
  }

  group('AutomationRuleCard', () {
    testWidgets('displays rule name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(name: 'High Risk Reminder'),
            ),
          ),
        ),
      );

      expect(find.text('High Risk Reminder'), findsOneWidget);
    });

    testWidgets('displays trigger type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(triggerType: AutomationTriggerType.noShowRisk),
            ),
          ),
        ),
      );

      expect(find.text('No-Show Risk'), findsOneWidget);
    });

    testWidgets('displays trigger count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(triggerCount: 25),
            ),
          ),
        ),
      );

      expect(find.textContaining('25 triggers'), findsOneWidget);
    });

    testWidgets('displays success rate', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(successCount: 8, failureCount: 2),
            ),
          ),
        ),
      );

      expect(find.textContaining('80% success'), findsOneWidget);
    });

    testWidgets('shows enabled toggle when onToggle provided', (tester) async {
      bool? toggleValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(isEnabled: true),
              onToggle: (value) => toggleValue = value,
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(toggleValue, isFalse);
    });

    testWidgets('responds to tap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });

    testWidgets('shows edit button when onEdit provided', (tester) async {
      var editPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(),
              onEdit: () => editPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Edit'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      expect(editPressed, isTrue);
    });

    testWidgets('shows delete button when onDelete provided', (tester) async {
      var deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(),
              onDelete: () => deletePressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(deletePressed, isTrue);
    });

    testWidgets('shows compact view', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(),
              compact: true,
            ),
          ),
        ),
      );

      // Should not show detailed stats in compact mode
      expect(find.textContaining('triggers'), findsNothing);
    });

    testWidgets('displays priority badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationRuleCard(
              rule: _createRule(priority: AutomationPriority.high),
            ),
          ),
        ),
      );

      expect(find.text('High'), findsWidgets);
    });
  });

  group('AutomationStatsCard', () {
    testWidgets('displays total rules', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutomationStatsCard(
              totalRules: 15,
              enabledRules: 10,
              totalTriggers: 100,
              successRate: 85.0,
            ),
          ),
        ),
      );

      expect(find.text('15'), findsOneWidget);
      expect(find.text('Total Rules'), findsOneWidget);
    });

    testWidgets('displays enabled rules', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutomationStatsCard(
              totalRules: 15,
              enabledRules: 10,
              totalTriggers: 100,
              successRate: 85.0,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('displays total triggers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutomationStatsCard(
              totalRules: 15,
              enabledRules: 10,
              totalTriggers: 100,
              successRate: 85.0,
            ),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget);
      expect(find.text('Triggers'), findsOneWidget);
    });

    testWidgets('displays success rate', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutomationStatsCard(
              totalRules: 15,
              enabledRules: 10,
              totalTriggers: 100,
              successRate: 85.0,
            ),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);
    });
  });

  group('AutomationEmptyState', () {
    testWidgets('displays empty state message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationEmptyState(
              onCreateRule: () {},
            ),
          ),
        ),
      );

      expect(find.text('No Automation Rules'), findsOneWidget);
    });

    testWidgets('shows create button', (tester) async {
      var createPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomationEmptyState(
              onCreateRule: () => createPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Create Rule'), findsOneWidget);

      await tester.tap(find.text('Create Rule'));
      expect(createPressed, isTrue);
    });
  });
}
