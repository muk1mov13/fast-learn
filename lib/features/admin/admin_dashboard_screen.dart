import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/app_user.dart';
import '../../state/admin_providers.dart';
import '../../state/auth_providers.dart';
import 'widgets/admin_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
    return Scaffold(
      backgroundColor: context.appBgColor,
      appBar: AppBar(
        title: const Text('Admin panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Chiqish',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: '$e'),
        data: (users) => _buildBody(users),
      ),
    );
  }

  Widget _buildBody(List<AppUser> all) {
    // Statistika
    final total = all.length;
    final avg = all.isEmpty
        ? 0
        : (all.map((u) => u.overallPercent).reduce((a, b) => a + b) /
                all.length)
            .round();
    final certCount = all.where((u) => u.certificateEarned).length;
    final activeCount = all.where(_isActive).length;

    // Qidiruv + saralash
    final q = _query.trim().toLowerCase();
    var list = q.isEmpty
        ? [...all]
        : all
            .where((u) =>
                u.fullName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q))
            .toList();
    list.sort((a, b) => b.overallPercent.compareTo(a.overallPercent));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Statistika kartalari
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.group_rounded,
                value: '$total',
                label: 'Jami userlar',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.trending_up_rounded,
                value: '$avg%',
                label: "O'rtacha o'zlashtirish",
                color: AppColors.stageReinforce,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.workspace_premium_rounded,
                value: '$certCount',
                label: 'Sertifikat olgan',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.bolt_rounded,
                value: '$activeCount',
                label: 'Faol (7 kun)',
                color: AppColors.stageAssess,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Foydalanuvchilar',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        // Qidiruv
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Ism yoki email bo\'yicha qidirish',
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            filled: true,
            fillColor: context.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.lineColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: context.lineColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyHint(
              icon: Icons.person_search_rounded,
              text: 'Foydalanuvchi topilmadi',
            ),
          )
        else
          ...list.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: UserTile(
                  user: u,
                  active: _isActive(u),
                  onTap: () => context.push('/admin/user/${u.uid}'),
                ),
              )),
      ],
    );
  }

  bool _isActive(AppUser u) {
    final la = u.lastActive;
    if (la == null) return false;
    return DateTime.now().difference(la).inDays < 7;
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Hisobingizdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authRepoProvider).signOut();
            },
            child: const Text('Chiqish',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 46, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              "Ma'lumotlarni yuklab bo'lmadi.\n$message",
              textAlign: TextAlign.center,
              style: TextStyle(color: context.mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
