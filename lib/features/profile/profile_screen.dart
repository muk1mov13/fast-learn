import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../state/auth_providers.dart';
import '../../state/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    final progress = ref.watch(progressProvider);
    final name = progress.studentName.isEmpty ? "Talaba" : progress.studentName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "T";
    final email = ref.watch(authProvider).email ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                    gradient: AppColors.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Text(name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                    email.isEmpty
                        ? "Texnologik ta'lim · Magistratura"
                        : email,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 20),
            _row(
              context,
              Icons.edit_rounded,
              "Ismni tahrirlash",
              onTap: () => _showEditNameDialog(context, ref, progress.studentName),
            ),
            _row(context, Icons.language_rounded, "Til", trailing: "O'zbekcha"),
            _toggleRow(context, Icons.dark_mode_rounded, "Tungi rejim",
                value: isDark,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).state =
                      v ? ThemeMode.dark : ThemeMode.light;
                }),
            _toggleRow(context, Icons.notifications_rounded, "Bildirishnomalar",
                value: true, onChanged: (_) {}),
            _toggleRow(context, Icons.download_rounded, "Offline yuklab olish",
                value: true, onChanged: (_) {}),
            const SizedBox(height: 8),
            _row(
              context,
              Icons.restart_alt_rounded,
              "Progressni tozalash",
              danger: true,
              onTap: () => _confirmReset(context, ref),
            ),
            _row(
              context,
              Icons.logout_rounded,
              "Chiqish",
              danger: true,
              onTap: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Chiqish"),
        content: const Text("Hisobingizdan chiqmoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // signOut → authState o'zgaradi → router /login ga yo'naltiradi.
              ref.read(authRepoProvider).signOut();
            },
            child: const Text("Chiqish",
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ismni tahrirlash"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: "Familiya Ism",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _saveName(ctx, ref, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor"),
          ),
          FilledButton(
            onPressed: () => _saveName(ctx, ref, controller.text),
            child: const Text("Saqlash"),
          ),
        ],
      ),
    );
  }

  void _saveName(BuildContext ctx, WidgetRef ref, String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      ref.read(progressProvider.notifier).setStudentName(trimmed);
    }
    Navigator.pop(ctx);
  }

  Widget _row(BuildContext context, IconData icon, String label,
      {String? trailing, bool danger = false, VoidCallback? onTap}) {
    final color = danger ? AppColors.danger : context.inkColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.lineColor),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: danger
                      ? AppColors.danger.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: color)),
              ),
              if (trailing != null)
                Text(trailing,
                    style:
                        TextStyle(color: context.mutedColor, fontSize: 12.5)),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: context.mutedColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(BuildContext context, IconData icon, String label,
      {required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.lineColor),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: context.inkColor),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Progressni tozalash"),
        content: const Text(
            "Barcha ball, nishon va mavzu progressi o'chiriladi. Davom etasizmi?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Bekor qilish")),
          TextButton(
            onPressed: () {
              ref.read(progressProvider.notifier).reset();
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                    const SnackBar(content: Text("↺ Progress tozalandi")));
            },
            child: const Text("Tozalash",
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
