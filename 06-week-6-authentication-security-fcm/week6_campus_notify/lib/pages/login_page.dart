// Halaman masuk.
//
// Semua string rute diambil dari `AppRoutes` (Refactoring Challenge 1), dan
// setelah login berhasil guard GoRouter yang memindahkan pengguna ke beranda —
// halaman ini tidak pernah memanggil `context.go()` sendiri.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'mahasiswa@polinema.ac.id');
  final _password = TextEditingController(text: 'rahasia123');
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authStateProvider.notifier)
        .login(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Campus Notify',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masuk untuk menerima pengumuman kampus',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Email wajib diisi';
                      if (!text.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Kata sandi minimal 6 karakter';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (auth.hasError) ...[
                    const SizedBox(height: 14),
                    _ErrorBox(message: _messageOf(auth.error)),
                  ],
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: auth.isLoading ? null : _submit,
                    icon: auth.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(auth.isLoading ? 'Memproses…' : 'Masuk'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SecurityNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _messageOf(Object? error) {
    if (error is AuthException) return error.message;
    return 'Gagal masuk. Coba lagi.';
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Catatan keamanan',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Access dan refresh token hanya disimpan di '
            'flutter_secure_storage (Keystore/Keychain). Tidak pernah di '
            'SharedPreferences, tidak di-hardcode, dan tidak dicetak penuh '
            'ke log.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
