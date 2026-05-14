# Атомарные компоненты — дизайн-спецификация

**Дата:** 2026-05-14  
**Приложение:** Knurl Mobile (Flutter)

---

## Стилевое направление

- **Тема:** Athletic / Dark — тёмный фон, прямые углы, жирная типографика
- **Фон приложения:** `#0F0F0F` (основной), `#1C1C1C` (поверхности), `#1E1E1E` (элементы)
- **Акцентный цвет:** `#FF6B35` (оранжевый)
- **Граница элементов:** `#2A2A2A`
- **Текст:** `#FFFFFF` (основной), `#BBBBBB` (вторичный), `#666666` (приглушённый)
- **Border-radius:** `6px` для кнопок, полей, чипов; `4px` для тегов; `9px` для бейджей
- **Ошибка:** `#EF5350`
- **Шрифт:** системный (SF Pro на iOS, Roboto на Android), `fontWeight: 700` для кнопок и лейблов

---

## Архитектура

### Подход: Theme Extension + тонкие обёртки

Единая точка управления стилем — `KnurlTheme` (реализует `ThemeExtension<KnurlTheme>`). Каждый компонент — `StatelessWidget`, читающий параметры из `KnurlTheme.of(context)`.

```
lib/shared/
  theme/
    app_theme.dart        — ThemeData + KnurlTheme extension
    knurl_theme.dart      — KnurlTheme: цвета, радиусы, отступы
  widgets/
    knurl_button.dart
    knurl_text_field.dart
    knurl_chip.dart
    knurl_badge.dart
    knurl_spinner.dart
    knurl_avatar.dart
    knurl_status_tag.dart
```

`KnurlTheme` хранит:
- `accent` — `Color` (#FF6B35)
- `surface` — `Color` (#1E1E1E)
- `background` — `Color` (#0F0F0F)
- `border` — `Color` (#2A2A2A)
- `error` — `Color` (#EF5350)
- `radius` — `BorderRadius` (6px) — дефолтный радиус для кнопок, полей, чипов, аватаров; теги (4px) и бейджи (9px) используют собственные захардкоженные значения

---

## Компоненты

### Button (`KnurlButton`)

**Варианты** (`KnurlButtonVariant`):
- `primary` — фон `accent`, текст белый
- `secondary` — фон `surface` (#1E1E1E), текст `accent`, граница `border`
- `ghost` — прозрачный фон, текст `#BBBBBB`, без границы
- `destructive` — фон `#C62828`, текст белый

**Размеры** (`KnurlButtonSize`):
- `md` (по умолчанию) — padding `11×24`, font 14px
- `sm` — padding `7×16`, font 12px

**Состояния:**
- `isLoading: true` — текст заменяется на `CircularProgressIndicator` 14px
- `onPressed: null` — кнопка disabled: фон `#1E1E1E`, текст `#444444`

**API:**
```dart
KnurlButton(
  label: 'Начать',
  onPressed: _submit,
  variant: KnurlButtonVariant.primary,  // default
  size: KnurlButtonSize.md,             // default
  isLoading: false,                     // default
)
```

---

### Text Field (`KnurlTextField`)

Тонкая обёртка над `TextFormField` с кастомным `InputDecoration`.

**Состояния:**
- **Empty** — граница `border` (#2A2A2A), лейбл `#555555`
- **Focused** — граница и лейбл `accent` (#FF6B35)
- **Filled** — граница `border`, лейбл `#666666`, значение заполнено
- **Error** — граница и лейбл `#EF5350`, под полем текст ошибки
- **Disabled** — opacity 0.4, `enabled: false`

Лейбл всегда «плавающий» (floating label сверху), фон поля `#1C1C1C`.

**API:**
```dart
KnurlTextField(
  controller: _ctrl,
  label: 'Email',
  keyboardType: TextInputType.emailAddress,
  obscureText: false,
  enabled: true,
  validator: validateEmail,
)
```

---

### Chip (`KnurlChip`)

Переключаемый тег для фильтров и категорий.

**Состояния:**
- **Selected** — фон `accent`, текст белый
- **Unselected** — фон `#1E1E1E`, текст `#777777`, граница `#2A2A2A`

**API:**
```dart
KnurlChip(
  label: 'Грудь',
  selected: true,
  onTap: () => setState(() => ...),
)
```

---

### Badge (`KnurlBadge`)

Оверлей-счётчик на дочернем виджете (иконка, аватар).

- Фон `accent`, текст белый, border-radius 9px
- Позиция: правый верхний угол `child`
- Значения: число или строка. Если `> 99` — показывает `99+`
- Если `count == 0` — бейдж скрыт

**API:**
```dart
KnurlBadge(
  count: 3,
  child: Icon(Icons.notifications),
)
```

---

### Spinner (`KnurlSpinner`)

**Варианты** (`KnurlSpinnerSize`):
- `sm` — 16px, stroke 2px; используется inline (внутри кнопки, строки)
- `lg` — 32px, stroke 3px; используется как page-level индикатор

Цвет трека: `#2A2A2A`, цвет активной дуги: `accent`.

**API:**
```dart
KnurlSpinner(size: KnurlSpinnerSize.lg)
```

---

### Avatar (`KnurlAvatar`)

Фото пользователя или инициалы-заглушка.

**Размеры** (`KnurlAvatarSize`):
- `sm` — 28px, font 11px
- `md` — 40px, font 15px
- `lg` — 56px, font 20px

- Форма: `border-radius: 6px` (квадрат со скруглением, не круг)
- Заглушка: фон `accent`, инициалы белые, `fontWeight: 700`
- С фото: `Image.network` / `Image.file` в `ClipRRect`

**API:**
```dart
KnurlAvatar(
  initials: 'АФ',
  imageUrl: null,       // если null — показывает инициалы
  size: KnurlAvatarSize.md,
)
```

---

### Status Tag (`KnurlStatusTag`)

Цветной тег статуса с точкой-иконкой.

**Варианты** (`KnurlTagStatus`):

| Статус    | Фон (opacity 15%)       | Текст     |
|-----------|-------------------------|-----------|
| `active`  | `#4CAF50`               | `#66BB6A` |
| `rest`    | `#FF6B35`               | `#FF6B35` |
| `warning` | `#FFC107`               | `#FFC107` |
| `done`    | `#646464`               | `#777777` |
| `pr`      | `#AB47BC`               | `#CE93D8` |

- Форма: border-radius 4px, padding `4×10`
- Типографика: 11px, `fontWeight: 700`, `letterSpacing: 0.5`, uppercase

**API:**
```dart
KnurlStatusTag(status: KnurlTagStatus.active)
KnurlStatusTag.custom(label: 'Warmup', color: Colors.blue)
```

---

## Тестирование

Каждый компонент покрывается виджет-тестами:
- Рендерится без ошибок в каждом состоянии / варианте
- Колбэки вызываются при взаимодействии
- Disabled/loading блокируют нажатие
- `KnurlBadge` скрывается при `count == 0` и показывает `99+` при переполнении
