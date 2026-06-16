import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(_email.text.trim(), _password.text);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _error = 'بيانات الدخول غير صحيحة');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo() {
    _email.text = 'teacher@demo.com';
    _password.text = 'demo1234';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 24),
                  Text('متعقّب معلم القرآن',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('تسجيل دخول المعلم',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('دخول'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('إنشاء حساب جديد'),
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('حساب تجريبي جاهز',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text('teacher@demo.com',
                            textDirection: TextDirection.ltr),
                        const Text('demo1234',
                            textDirection: TextDirection.ltr),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _fillDemo,
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: const Text('استخدام الحساب التجريبي'),
                        ),
                      ],
                    ),
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
