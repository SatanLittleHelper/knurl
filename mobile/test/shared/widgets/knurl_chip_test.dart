import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/widgets/knurl_chip.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: appTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('KnurlChip', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlChip(label: 'Грудь', selected: false, onTap: () {}),
      ));
      expect(find.text('Грудь'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        KnurlChip(label: 'Грудь', selected: false, onTap: () => tapped = true),
      ));
      await tester.tap(find.byType(KnurlChip));
      expect(tapped, isTrue);
    });

    testWidgets('selected chip renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlChip(label: 'Грудь', selected: true, onTap: () {}),
      ));
      expect(find.text('Грудь'), findsOneWidget);
    });

    testWidgets('unselected chip renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlChip(label: 'Спина', selected: false, onTap: () {}),
      ));
      expect(find.text('Спина'), findsOneWidget);
    });
  });
}
