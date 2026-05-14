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
