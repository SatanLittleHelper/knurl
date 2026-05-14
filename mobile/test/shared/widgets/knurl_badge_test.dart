import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/widgets/knurl_badge.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: appTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('KnurlBadge', () {
    testWidgets('shows count when count > 0', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlBadge(count: 3, child: const Icon(Icons.notifications)),
      ));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides badge when count is 0', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlBadge(count: 0, child: const Icon(Icons.notifications)),
      ));
      // When count is 0, KnurlBadge returns just the child, not a Stack
      expect(find.byType(Icon), findsOneWidget);
      // Should not find any badge text
      expect(find.text('0'), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('shows 99+ when count exceeds 99', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlBadge(count: 150, child: const Icon(Icons.notifications)),
      ));
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('shows exactly 99 for count == 99', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlBadge(count: 99, child: const Icon(Icons.notifications)),
      ));
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('child is always rendered', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlBadge(count: 5, child: const Icon(Icons.notifications)),
      ));
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
