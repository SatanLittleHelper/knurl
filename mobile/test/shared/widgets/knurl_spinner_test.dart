import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/widgets/knurl_spinner.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: appTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('KnurlSpinner', () {
    testWidgets('sm is 16x16', (tester) async {
      await tester.pumpWidget(wrap(
        const KnurlSpinner(size: KnurlSpinnerSize.sm),
      ));
      final size = tester.getSize(find.byType(KnurlSpinner));
      expect(size.width, 16.0);
      expect(size.height, 16.0);
    });

    testWidgets('lg is 32x32', (tester) async {
      await tester.pumpWidget(wrap(
        const KnurlSpinner(size: KnurlSpinnerSize.lg),
      ));
      final size = tester.getSize(find.byType(KnurlSpinner));
      expect(size.width, 32.0);
      expect(size.height, 32.0);
    });

    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(wrap(const KnurlSpinner()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
