import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/widgets/knurl_avatar.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: appTheme,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('KnurlAvatar', () {
    testWidgets('renders initials when imageUrl is null', (tester) async {
      await tester.pumpWidget(wrap(const KnurlAvatar(initials: 'АФ')));
      expect(find.text('АФ'), findsOneWidget);
    });

    testWidgets('sm size is 28x28', (tester) async {
      await tester.pumpWidget(wrap(
        const KnurlAvatar(initials: 'АФ', size: KnurlAvatarSize.sm),
      ));
      final size = tester.getSize(find.byType(KnurlAvatar));
      expect(size.width, 28.0);
      expect(size.height, 28.0);
    });

    testWidgets('md size is 40x40', (tester) async {
      await tester.pumpWidget(wrap(
        const KnurlAvatar(initials: 'АФ', size: KnurlAvatarSize.md),
      ));
      final size = tester.getSize(find.byType(KnurlAvatar));
      expect(size.width, 40.0);
      expect(size.height, 40.0);
    });

    testWidgets('lg size is 56x56', (tester) async {
      await tester.pumpWidget(wrap(
        const KnurlAvatar(initials: 'АФ', size: KnurlAvatarSize.lg),
      ));
      final size = tester.getSize(find.byType(KnurlAvatar));
      expect(size.width, 56.0);
      expect(size.height, 56.0);
    });

    testWidgets('does not show initials when imageUrl is provided', (tester) async {
      // Suppress HTTP errors from Image.network loading in tests
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        // Ignore network image errors
        if (!details.toString().contains('NetworkImageLoadException')) {
          originalOnError?.call(details);
        }
      };

      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(wrap(
        const KnurlAvatar(
          initials: 'АФ',
          imageUrl: 'https://example.com/photo.jpg',
        ),
      ));
      // When an image URL is provided, the Image.network is rendered instead of text
      // The text widget should not be present
      expect(find.text('АФ'), findsNothing);
      // Verify that Image.network is being used
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
