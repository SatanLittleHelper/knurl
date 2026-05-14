import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/widgets/knurl_button.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: appTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('KnurlButton', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlButton(label: 'Начать', onPressed: () {}),
      ));
      expect(find.text('Начать'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        KnurlButton(label: 'Tap', onPressed: () => tapped = true),
      ));
      await tester.tap(find.byType(KnurlButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onPressed when onPressed is null', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        KnurlButton(label: 'Tap', onPressed: null),
      ));
      await tester.tap(find.byType(KnurlButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets('shows CircularProgressIndicator when isLoading', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlButton(label: 'Tap', onPressed: () {}, isLoading: true),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Tap'), findsNothing);
    });

    testWidgets('does not call onPressed when isLoading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        KnurlButton(label: 'Tap', onPressed: () => tapped = true, isLoading: true),
      ));
      await tester.tap(find.byType(KnurlButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets('all variants render without error', (tester) async {
      for (final v in KnurlButtonVariant.values) {
        await tester.pumpWidget(wrap(
          KnurlButton(label: 'Test', onPressed: () {}, variant: v),
        ));
        expect(find.text('Test'), findsOneWidget);
      }
    });

    testWidgets('sm size renders without error', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlButton(label: 'Small', onPressed: () {}, size: KnurlButtonSize.sm),
      ));
      expect(find.text('Small'), findsOneWidget);
    });
  });
}
