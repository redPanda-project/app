import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redpanda/main.dart';

void main() {
  group('NodeId Group Tests', () {
    setUp(() {});

    test('Perform simple dart test (no GUI)', () {
      expect(1, 1);
    });

    testWidgets('Test the widget without data from redpanda light client lib',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(MyApp());

      expect(find.byIcon(Icons.add), findsOneWidget);

      // Tap the '+' icon and trigger a frame.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify that our counter has incremented.
//    expect(find.text('Test1'), findsWidgets);
      expect(find.text('1'), findsNothing);
    });
  });
}
