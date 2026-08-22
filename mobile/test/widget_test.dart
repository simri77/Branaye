import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:branaye/main.dart';

void main() {
  testWidgets('Home shows notes from the mock repository', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: BranayeApp()));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Alex'), findsOneWidget);
    expect(find.text('Project Branaye Vision'), findsOneWidget);
  });

  testWidgets('Bottom nav navigates between tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BranayeApp()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Search your notes...'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsWidgets);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Good morning, Alex'), findsOneWidget);
  });
}
