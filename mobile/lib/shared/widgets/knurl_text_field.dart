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
          floatingLabelBehavior: FloatingLabelBehavior.always,
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
