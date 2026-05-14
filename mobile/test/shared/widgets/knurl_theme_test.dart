import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/theme/knurl_theme.dart';

void main() {
  group('KnurlTheme', () {
    testWidgets('of() returns accent from theme extension', (tester) async {
      late KnurlTheme captured;
      await tester.pumpWidget(MaterialApp(
        theme: appTheme,
        home: Builder(builder: (context) {
          captured = KnurlTheme.of(context);
          return const SizedBox();
        }),
      ));
      expect(captured.accent, const Color(0xFFFF6B35));
    });

    testWidgets('of() returns surface from theme extension', (tester) async {
      late KnurlTheme captured;
      await tester.pumpWidget(MaterialApp(
        theme: appTheme,
        home: Builder(builder: (context) {
          captured = KnurlTheme.of(context);
          return const SizedBox();
        }),
      ));
      expect(captured.surface, const Color(0xFF1E1E1E));
    });

    testWidgets('of() falls back to defaults when extension is absent', (tester) async {
      late KnurlTheme captured;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          captured = KnurlTheme.of(context);
          return const SizedBox();
        }),
      ));
      expect(captured.accent, const Color(0xFFFF6B35));
    });

    testWidgets('of() returns correct radius from theme extension', (tester) async {
      late KnurlTheme captured;
      await tester.pumpWidget(MaterialApp(
        theme: appTheme,
        home: Builder(builder: (context) {
          captured = KnurlTheme.of(context);
          return const SizedBox();
        }),
      ));
      expect(captured.radius, const BorderRadius.all(Radius.circular(6)));
    });
  });
}
