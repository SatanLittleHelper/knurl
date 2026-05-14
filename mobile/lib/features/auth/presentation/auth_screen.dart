// mobile/lib/features/auth/presentation/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/features/auth/presentation/auth_controller.dart';
import 'package:knurl/shared/utils/validators.dart';
import 'package:knurl/shared/widgets/knurl_app_bar.dart';

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
                  _EmailField(
                    controller: _emailController,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  _PasswordField(
                    controller: _passwordController,
                    enabled: !isLoading,
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
                  _SubmitButton(
                    isLoading: isLoading,
                    label: state.mode == AuthMode.signIn
                        ? 'Войти'
                        : 'Создать аккаунт',
                    onPressed: _submit,
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
      onSelectionChanged:
          enabled ? (s) => onChanged(s.first) : null,
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: 'Email'),
      validator: validateEmail,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'Пароль'),
      validator: validatePassword,
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
