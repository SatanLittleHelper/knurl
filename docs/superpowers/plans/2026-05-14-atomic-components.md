# Atomic Components Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Реализовать библиотеку из 7 атомарных Flutter-компонентов в стиле Athletic/Dark с единой темой через ThemeExtension, и перевести существующий экран авторизации на новые компоненты.

**Architecture:** `KnurlTheme` (ThemeExtension) — единая точка хранения цветов и радиусов. Каждый компонент — `StatelessWidget`, читающий тему через `KnurlTheme.of(context)`. Компоненты живут в `lib/shared/widgets/`, тема в `lib/shared/theme/`.

**Tech Stack:** Flutter, Material 3, Dart pattern matching (switch expressions), flutter_test (widget tests).

---

## File Map

**Создать:**
- `mobile/lib/shared/theme/knurl_theme.dart` — `KnurlTheme` ThemeExtension
- `mobile/lib/shared/widgets/knurl_button.dart` — `KnurlButton`, `KnurlButtonVariant`, `KnurlButtonSize`
- `mobile/lib/shared/widgets/knurl_text_field.dart` — `KnurlTextField`
- `mobile/lib/shared/widgets/knurl_chip.dart` — `KnurlChip`
- `mobile/lib/shared/widgets/knurl_badge.dart` — `KnurlBadge`
- `mobile/lib/shared/widgets/knurl_spinner.dart` — `KnurlSpinner`, `KnurlSpinnerSize`
- `mobile/lib/shared/widgets/knurl_avatar.dart` — `KnurlAvatar`, `KnurlAvatarSize`
- `mobile/lib/shared/widgets/knurl_status_tag.dart` — `KnurlStatusTag`, `KnurlTagStatus`
- `mobile/test/shared/widgets/knurl_theme_test.dart`
- `mobile/test/shared/widgets/knurl_button_test.dart`
- `mobile/test/shared/widgets/knurl_text_field_test.dart`
- `mobile/test/shared/widgets/knurl_chip_test.dart`
- `mobile/test/shared/widgets/knurl_badge_test.dart`
- `mobile/test/shared/widgets/knurl_spinner_test.dart`
- `mobile/test/shared/widgets/knurl_avatar_test.dart`
- `mobile/test/shared/widgets/knurl_status_tag_test.dart`

**Изменить:**
- `mobile/lib/shared/theme/app_theme.dart` — добавить тёмную тему и `KnurlTheme.defaults`
- `mobile/lib/features/auth/presentation/auth_screen.dart` — заменить `FilledButton`/`TextFormField` на `KnurlButton`/`KnurlTextField`, удалить `_SubmitButton`, `_EmailField`, `_PasswordField`

---

## Task 1: KnurlTheme + обновление app_theme.dart

**Files:**
- Create: `mobile/lib/shared/theme/knurl_theme.dart`
- Modify: `mobile/lib/shared/theme/app_theme.dart`
- Test: `mobile/test/shared/widgets/knurl_theme_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/theme/knurl_theme.dart`**

```dart
import 'package:flutter/material.dart';

class KnurlTheme extends ThemeExtension<KnurlTheme> {
  const KnurlTheme({
    required this.accent,
    required this.surface,
    required this.background,
    required this.border,
    required this.error,
    required this.radius,
  });

  final Color accent;
  final Color surface;
  final Color background;
  final Color border;
  final Color error;
  final BorderRadius radius;

  static const defaults = KnurlTheme(
    accent: Color(0xFFFF6B35),
    surface: Color(0xFF1E1E1E),
    background: Color(0xFF0F0F0F),
    border: Color(0xFF2A2A2A),
    error: Color(0xFFEF5350),
    radius: BorderRadius.all(Radius.circular(6)),
  );

  static KnurlTheme of(BuildContext context) =>
      Theme.of(context).extension<KnurlTheme>() ?? defaults;

  @override
  KnurlTheme copyWith({
    Color? accent,
    Color? surface,
    Color? background,
    Color? border,
    Color? error,
    BorderRadius? radius,
  }) =>
      KnurlTheme(
        accent: accent ?? this.accent,
        surface: surface ?? this.surface,
        background: background ?? this.background,
        border: border ?? this.border,
        error: error ?? this.error,
        radius: radius ?? this.radius,
      );

  @override
  KnurlTheme lerp(KnurlTheme? other, double t) {
    if (other == null) return this;
    return KnurlTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      radius: BorderRadius.lerp(radius, other.radius, t)!,
    );
  }
}
```

- [ ] **Step 2: Обновить `mobile/lib/shared/theme/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'knurl_theme.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F0F0F),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F0F),
  useMaterial3: true,
  extensions: const [KnurlTheme.defaults],
);
```

- [ ] **Step 3: Написать тест `mobile/test/shared/widgets/knurl_theme_test.dart`**

```dart
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
  });
}
```

- [ ] **Step 4: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_theme_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 2: KnurlButton

**Files:**
- Create: `mobile/lib/shared/widgets/knurl_button.dart`
- Test: `mobile/test/shared/widgets/knurl_button_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/widgets/knurl_button.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

enum KnurlButtonVariant { primary, secondary, ghost, destructive }

enum KnurlButtonSize { md, sm }

class KnurlButton extends StatelessWidget {
  const KnurlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KnurlButtonVariant.primary,
    this.size = KnurlButtonSize.md,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KnurlButtonVariant variant;
  final KnurlButtonSize size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    final disabled = onPressed == null && !isLoading;
    final (bg, fg, border) = _colors(theme, disabled);
    final (vPad, hPad, fontSize) = _dims();

    return GestureDetector(
      onTap: (disabled || isLoading) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: theme.radius,
          border: border != null
              ? Border.all(color: border, width: 1.5)
              : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  (Color, Color, Color?) _colors(KnurlTheme theme, bool disabled) {
    if (disabled) {
      return (const Color(0xFF1E1E1E), const Color(0xFF444444), null);
    }
    return switch (variant) {
      KnurlButtonVariant.primary     => (theme.accent, Colors.white, null),
      KnurlButtonVariant.secondary   => (theme.surface, theme.accent, theme.border),
      KnurlButtonVariant.ghost       => (Colors.transparent, const Color(0xFFBBBBBB), null),
      KnurlButtonVariant.destructive => (const Color(0xFFC62828), Colors.white, null),
    };
  }

  (double, double, double) _dims() => switch (size) {
    KnurlButtonSize.md => (11.0, 24.0, 14.0),
    KnurlButtonSize.sm => (7.0, 16.0, 12.0),
  };
}
```

- [ ] **Step 2: Написать тест `mobile/test/shared/widgets/knurl_button_test.dart`**

```dart
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
```

- [ ] **Step 3: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_button_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 3: KnurlTextField

**Files:**
- Create: `mobile/lib/shared/widgets/knurl_text_field.dart`
- Test: `mobile/test/shared/widgets/knurl_text_field_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/widgets/knurl_text_field.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

class KnurlTextField extends StatelessWidget {
  const KnurlTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFF1C1C1C),
          labelStyle: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          floatingLabelStyle: TextStyle(
            color: theme.accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          errorStyle: TextStyle(color: theme.error, fontSize: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: theme.radius,
            borderSide: BorderSide(color: theme.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: theme.radius,
            borderSide: BorderSide(color: theme.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: theme.radius,
            borderSide: BorderSide(color: theme.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: theme.radius,
            borderSide: BorderSide(color: theme.error, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: theme.radius,
            borderSide: BorderSide(color: theme.border, width: 1.5),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Написать тест `mobile/test/shared/widgets/knurl_text_field_test.dart`**

```dart
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
```

- [ ] **Step 3: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_text_field_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 4: KnurlChip

**Files:**
- Create: `mobile/lib/shared/widgets/knurl_chip.dart`
- Test: `mobile/test/shared/widgets/knurl_chip_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/widgets/knurl_chip.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

class KnurlChip extends StatelessWidget {
  const KnurlChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? theme.accent : theme.surface,
          borderRadius: theme.radius,
          border: selected ? null : Border.all(color: theme.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF777777),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Написать тест `mobile/test/shared/widgets/knurl_chip_test.dart`**

```dart
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
```

- [ ] **Step 3: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_chip_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 5: KnurlBadge

**Files:**
- Create: `mobile/lib/shared/widgets/knurl_badge.dart`
- Test: `mobile/test/shared/widgets/knurl_badge_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/widgets/knurl_badge.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

class KnurlBadge extends StatelessWidget {
  const KnurlBadge({
    super.key,
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return child;

    final theme = KnurlTheme.of(context);
    final label = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -6,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: BoxDecoration(
              color: theme.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Написать тест `mobile/test/shared/widgets/knurl_badge_test.dart`**

```dart
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
      expect(find.byType(Stack), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
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
```

- [ ] **Step 3: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_badge_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 6: KnurlSpinner

**Files:**
- Create: `mobile/lib/shared/widgets/knurl_spinner.dart`
- Test: `mobile/test/shared/widgets/knurl_spinner_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/widgets/knurl_spinner.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

enum KnurlSpinnerSize { sm, lg }

class KnurlSpinner extends StatelessWidget {
  const KnurlSpinner({
    super.key,
    this.size = KnurlSpinnerSize.lg,
  });

  final KnurlSpinnerSize size;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    final (diameter, strokeWidth) = switch (size) {
      KnurlSpinnerSize.sm => (16.0, 2.0),
      KnurlSpinnerSize.lg => (32.0, 3.0),
    };
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        backgroundColor: theme.border,
        color: theme.accent,
      ),
    );
  }
}
```

- [ ] **Step 2: Написать тест `mobile/test/shared/widgets/knurl_spinner_test.dart`**

```dart
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
```

- [ ] **Step 3: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_spinner_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 7: KnurlAvatar

**Files:**
- Create: `mobile/lib/shared/widgets/knurl_avatar.dart`
- Test: `mobile/test/shared/widgets/knurl_avatar_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/widgets/knurl_avatar.dart`**

```dart
import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

enum KnurlAvatarSize { sm, md, lg }

class KnurlAvatar extends StatelessWidget {
  const KnurlAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = KnurlAvatarSize.md,
  });

  final String initials;
  final String? imageUrl;
  final KnurlAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    final (dimension, fontSize) = switch (size) {
      KnurlAvatarSize.sm => (28.0, 11.0),
      KnurlAvatarSize.md => (40.0, 15.0),
      KnurlAvatarSize.lg => (56.0, 20.0),
    };
    final url = imageUrl;
    return ClipRRect(
      borderRadius: theme.radius,
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: url != null
            ? Image.network(url, fit: BoxFit.cover)
            : ColoredBox(
                color: theme.accent,
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
```

- [ ] **Step 2: Написать тест `mobile/test/shared/widgets/knurl_avatar_test.dart`**

```dart
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
      await tester.pumpWidget(wrap(
        const KnurlAvatar(
          initials: 'АФ',
          imageUrl: 'https://example.com/photo.jpg',
        ),
      ));
      expect(find.text('АФ'), findsNothing);
    });
  });
}
```

- [ ] **Step 3: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_avatar_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 8: KnurlStatusTag

**Files:**
- Create: `mobile/lib/shared/widgets/knurl_status_tag.dart`
- Test: `mobile/test/shared/widgets/knurl_status_tag_test.dart`

- [ ] **Step 1: Создать `mobile/lib/shared/widgets/knurl_status_tag.dart`**

```dart
import 'package:flutter/material.dart';

enum KnurlTagStatus { active, rest, warning, done, pr }

class KnurlStatusTag extends StatelessWidget {
  const KnurlStatusTag({super.key, required this.status})
      : _label = null,
        _color = null;

  const KnurlStatusTag.custom({
    super.key,
    required String label,
    required Color color,
  })  : status = null,
        _label = label,
        _color = color;

  final KnurlTagStatus? status;
  final String? _label;
  final Color? _color;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('● ', style: TextStyle(color: fg, fontSize: 8)),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _resolve() {
    final s = status;
    if (s == null) return (_color!, _color!, _label!);
    return switch (s) {
      KnurlTagStatus.active  => (const Color(0xFF4CAF50), const Color(0xFF66BB6A), 'Active'),
      KnurlTagStatus.rest    => (const Color(0xFFFF6B35), const Color(0xFFFF6B35), 'Rest'),
      KnurlTagStatus.warning => (const Color(0xFFFFC107), const Color(0xFFFFC107), 'Warning'),
      KnurlTagStatus.done    => (const Color(0xFF646464), const Color(0xFF777777), 'Done'),
      KnurlTagStatus.pr      => (const Color(0xFFAB47BC), const Color(0xFFCE93D8), 'PR'),
    };
  }
}
```

- [ ] **Step 2: Написать тест `mobile/test/shared/widgets/knurl_status_tag_test.dart`**

```dart
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
```

- [ ] **Step 3: Запустить тест**

```bash
cd mobile && flutter test test/shared/widgets/knurl_status_tag_test.dart
```
Ожидаем: `All tests passed!`

---

## Task 9: Миграция auth_screen.dart + финальный коммит

**Files:**
- Modify: `mobile/lib/features/auth/presentation/auth_screen.dart`

- [ ] **Step 1: Запустить все тесты — убедиться что зелёные перед миграцией**

```bash
cd mobile && flutter test
```
Ожидаем: `All tests passed!`

- [ ] **Step 2: Заменить содержимое `mobile/lib/features/auth/presentation/auth_screen.dart`**

Удаляем `_SubmitButton`, `_EmailField`, `_PasswordField` и заменяем на `KnurlButton` / `KnurlTextField`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/features/auth/presentation/auth_controller.dart';
import 'package:knurl/shared/utils/validators.dart';
import 'package:knurl/shared/widgets/knurl_app_bar.dart';
import 'package:knurl/shared/widgets/knurl_button.dart';
import 'package:knurl/shared/widgets/knurl_text_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(authControllerProvider.notifier);
    final isSignIn = ref.read(authControllerProvider).mode == AuthMode.signIn;
    if (isSignIn) {
      await controller.signIn(_emailController.text, _passwordController.text);
    } else {
      await controller.signUp(_emailController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final isLoading = state.status == AuthStatus.loading;

    return Scaffold(
      appBar: const KnurlAppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModeToggle(
                    mode: state.mode,
                    enabled: !isLoading,
                    onChanged: (mode) {
                      ref.read(authControllerProvider.notifier).setMode(mode);
                      _formKey.currentState?.reset();
                    },
                  ),
                  const SizedBox(height: 24),
                  KnurlTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  KnurlTextField(
                    controller: _passwordController,
                    label: 'Пароль',
                    obscureText: true,
                    enabled: !isLoading,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 16),
                  if (state.errorMessage != null) ...[
                    Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  KnurlButton(
                    label: state.mode == AuthMode.signIn
                        ? 'Войти'
                        : 'Создать аккаунт',
                    onPressed: _submit,
                    isLoading: isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  final AuthMode mode;
  final bool enabled;
  final void Function(AuthMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AuthMode>(
      segments: const [
        ButtonSegment(value: AuthMode.signIn, label: Text('Вход')),
        ButtonSegment(value: AuthMode.signUp, label: Text('Регистрация')),
      ],
      selected: {mode},
      onSelectionChanged: enabled ? (s) => onChanged(s.first) : null,
    );
  }
}
```

- [ ] **Step 3: Запустить все тесты**

```bash
cd mobile && flutter test
```
Ожидаем: `All tests passed!`

- [ ] **Step 4: Финальный коммит**

```bash
git add . && git commit -m "feat: атомарные компоненты — KnurlTheme, Button, TextField, Chip, Badge, Spinner, Avatar, StatusTag; миграция auth_screen"
```
