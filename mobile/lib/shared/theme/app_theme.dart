import 'package:flutter/material.dart';
import 'knurl_theme.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF6B35),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F0F0F),
  useMaterial3: true,
  extensions: const [KnurlTheme.defaults],
);
