import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/theme/app_theme.dart';
import 'package:knurl/shared/widgets/knurl_text_field.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: appTheme,
      home: Scaffold(body: Center(child: Form(child: child))),
    );

void main() {
  group('KnurlTextField', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlTextField(controller: TextEditingController(), label: 'Email'),
      ));
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(wrap(
        KnurlTextField(controller: ctrl, label: 'Email'),
      ));
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      expect(ctrl.text, 'user@example.com');
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(wrap(
        KnurlTextField(
          controller: TextEditingController(),
          label: 'Пароль',
          obscureText: true,
        ),
      ));
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.obscureText, isTrue);
    });

    testWidgets('shows error text when validator returns error', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(MaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: KnurlTextField(
              controller: TextEditingController(),
              label: 'Email',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Обязательное поле' : null,
            ),
          ),
        ),
      ));
      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Обязательное поле'), findsOneWidget);
    });

    testWidgets('disabled field is not interactive', (tester) async {
      final ctrl = TextEditingController(text: 'initial');
      await tester.pumpWidget(wrap(
        KnurlTextField(controller: ctrl, label: 'Email', enabled: false),
      ));
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.enabled, isFalse);
    });
  });
}
