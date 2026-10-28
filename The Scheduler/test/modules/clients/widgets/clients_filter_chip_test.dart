import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/modules/clients/presentation/widgets/clients_filter_chip.dart';

void main() {
  group('ClientsFilterChip Widget', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Active',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Active',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(ClientsFilterChip),
          matching: find.byType(AnimatedContainer),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders unselected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Inactive',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final element = tester.element(find.byType(ClientsFilterChip));
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(ClientsFilterChip),
          matching: find.byType(AnimatedContainer),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNull);
      expect(decoration.color, Theme.of(element).colorScheme.surface);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Test',
              isSelected: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(ClientsFilterChip),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('uses custom color when provided', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Test',
              isSelected: true,
              onTap: () {},
              color: customColor,
            ),
          ),
        ),
      );

      final decoration = (tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(ClientsFilterChip),
          matching: find.byType(AnimatedContainer),
        ),
      ).decoration as BoxDecoration);

      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.first, customColor);
    });

    testWidgets('uses theme color when no custom color provided', (tester) async {
      const themeColor = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: themeColor),
          ),
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Test',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final decoration = (tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(ClientsFilterChip),
          matching: find.byType(AnimatedContainer),
        ),
      ).decoration as BoxDecoration);

      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.first, themeColor);
    });

    testWidgets('displays different labels correctly', (tester) async {
      final labels = ['All', 'New', 'Active', 'Inactive', 'Churned'];

      for (final label in labels) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClientsFilterChip(
                label: label,
                isSelected: false,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text(label), findsOneWidget);

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('selected chip has bold font weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Selected',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      final label = tester.widget<Text>(find.text('Selected'));
      expect(label.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('unselected chip has normal font weight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Unselected',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final label = tester.widget<Text>(find.text('Unselected'));
      expect(label.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('multiple chips can coexist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ClientsFilterChip(
                  label: 'All',
                  isSelected: true,
                  onTap: () {},
                ),
                ClientsFilterChip(
                  label: 'Active',
                  isSelected: false,
                  onTap: () {},
                ),
                ClientsFilterChip(
                  label: 'Inactive',
                  isSelected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.byType(ClientsFilterChip), findsNWidgets(3));
    });

    testWidgets('can toggle selection', (tester) async {
      var isSelected = false;

      Future<void> buildWidget() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClientsFilterChip(
                label: 'Toggle',
                isSelected: isSelected,
                onTap: () {
                  isSelected = !isSelected;
                },
              ),
            ),
          ),
        );
      }

      // Initial state: not selected
      await buildWidget();
      var hasCheck = find.byIcon(Icons.check);
      expect(hasCheck, findsNothing);

      // Tap to select
      await tester.tap(
        find.descendant(
          of: find.byType(ClientsFilterChip),
          matching: find.byType(InkWell),
        ),
      );
      await buildWidget();
      hasCheck = find.byIcon(Icons.check);
      expect(hasCheck, findsOneWidget);

      // Tap to deselect
      await tester.tap(
        find.descendant(
          of: find.byType(ClientsFilterChip),
          matching: find.byType(InkWell),
        ),
      );
      await buildWidget();
      hasCheck = find.byIcon(Icons.check);
      expect(hasCheck, findsNothing);
    });

    testWidgets('widget respects MaterialApp theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Dark Mode',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should render without errors in dark mode
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('widget is accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClientsFilterChip(
              label: 'Accessible',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final inkWellFinder = find.descendant(
        of: find.byType(ClientsFilterChip),
        matching: find.byType(InkWell),
      );
      expect(inkWellFinder, findsOneWidget);

      await tester.tap(inkWellFinder);
      await tester.pumpAndSettle();
    });
  });
}
