// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:noteflow/main.dart';

void main() {
  testWidgets('Shell shows home and navigates to search', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NoteFlowApp());
    await tester.pumpAndSettle(); // waits for navigation animations

    //Home is shown first
    expect(find.text('Your notes will appear here'), findsOneWidget);

    //All four nav destinations are shown
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Search')); // taps the nav destination label
    await tester.pumpAndSettle(); // waits for navigation animations

    expect(find.text('Search Screen'), findsOneWidget);
  });
}
