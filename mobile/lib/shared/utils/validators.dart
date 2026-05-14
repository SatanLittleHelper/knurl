String? validateEmail(String? value) {
  final email = value?.trim();

  if (email == null || email.isEmpty) {
    return 'Введите email';
  }

  if (!email.contains('@')) {
    return 'Введите корректный email';
  }

  return null;
}

String? validatePassword(String? value) {
  final password = value?.trim();

  if (password == null || password.isEmpty) {
    return 'Введите пароль';
  }

  return null;
}
