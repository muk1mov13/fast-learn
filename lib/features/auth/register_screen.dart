import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'widgets/auth_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fullName = _fullName.text.trim();
      await ref.read(authRepoProvider).register(
            email: _email.text,
            password: _password.text,
            fullName: fullName,
          );
      // Sertifikat va profil uchun ismni lokal progressga ham yozamiz.
      ref.read(progressProvider.notifier).setStudentName(fullName);
      // Muvaffaqiyatda router redirect avtomatik yo'naltiradi.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(
                    icon: Icons.person_add_alt_1_rounded,
                    title: "Ro'yxatdan o'tish",
                    subtitle: 'Yangi hisob yarating va kursni boshlang',
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthField(
                            controller: _fullName,
                            label: 'To\'liq ism',
                            hint: 'Familiya Ism',
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Ism kamida 3 belgidan iborat bo\'lsin'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _email,
                            label: 'Email',
                            hint: 'misol@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _password,
                            label: 'Parol',
                            hint: 'Kamida 6 belgi',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Parol kamida 6 belgi bo\'lsin'
                                : null,
                            suffix: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              color: AppColors.muted,
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _confirm,
                            label: 'Parolni tasdiqlang',
                            hint: 'Parolni qayta kiriting',
                            icon: Icons.lock_reset_rounded,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => (v != _password.text)
                                ? 'Parollar mos kelmadi'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          GradientButton(
                            label:
                                _loading ? 'Kuting...' : "Ro'yxatdan o'tish",
                            gradient: AppColors.heroGradient,
                            enabled: !_loading,
                            onPressed: _loading ? null : _submit,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.25),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hisobingiz bormi?',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      TextButton(
                        onPressed: _loading ? null : () => context.pop(),
                        child: const Text(
                          'Kirish',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
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

String? _emailValidator(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Email kiriting';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  return ok ? null : "Email noto'g'ri formatda";
}
