import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/widgets/knurl_status_tag.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: appTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('KnurlStatusTag', () {
    testWidgets('all statuses render without error', (tester) async {
      for (final s in KnurlTagStatus.values) {
        await tester.pumpWidget(wrap(KnurlStatusTag(status: s)));
        expect(find.byType(KnurlStatusTag), findsOneWidget);
      }
    });

    testWidgets('active shows ACTIVE label', (tester) async {
      await tester.pumpWidget(wrap(
        const KnurlStatusTag(status: KnurlTagStatus.active),
      ));
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('done shows DONE label', (tester) async {
      await tester.pumpWidget(wrap(
        const KnurlStatusTag(status: KnurlTagStatus.done),
      ));
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('custom renders provided label in uppercase', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlStatusTag.custom(label: 'Warmup', color: Colors.blue),
      ));
      expect(find.text('WARMUP'), findsOneWidget);
    });
  });
}
