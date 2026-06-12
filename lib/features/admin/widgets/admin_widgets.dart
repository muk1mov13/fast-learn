import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/app_user.dart';
import '../../../widgets/common.dart';

/// "lastActive" ni o'zbekcha nisbiy matnga aylantiradi.
String relativeLastActive(DateTime? d) {
  if (d == null) return 'Faollik yo\'q';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Hozir';
  if (diff.inMinutes < 60) return '${diff.inMinutes} daqiqa oldin';
  if (diff.inHours < 24) return '${diff.inHours} soat oldin';
  if (diff.inDays == 1) return 'Kecha';
  if (diff.inDays < 30) return '${diff.inDays} kun oldin';
  return '${(diff.inDays / 30).floor()} oy oldin';
}

/// Statistika kartasi (admin dashboard yuqorisida).
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                color: context.mutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Foydalanuvchi qatori (ro'yxatda).
class UserTile extends StatelessWidget {
  final AppUser user;
  final bool active;
  final VoidCallback onTap;
  const UserTile({
    super.key,
    required this.user,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';
    final pctColor = user.overallPercent >= 90
        ? AppColors.ok
        : user.overallPercent >= 50
            ? AppColors.primary
            : AppColors.accent;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
              if (active)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.ok,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surfaceColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName.isEmpty ? 'Ismsiz' : user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      const StageTag(text: 'admin', color: AppColors.stageAssess),
                    ],
                    if (user.certificateEarned) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.workspace_premium_rounded,
                          size: 15, color: AppColors.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.mutedColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.completedTopics}/8 mavzu · ${user.totalPoints} ball · ${relativeLastActive(user.lastActive)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.mutedColor, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ProgressRing(
            percent: user.overallPercent / 100,
            size: 46,
            stroke: 5,
            color: pctColor,
            trackColor: context.softFillColor,
            center: Text(
              '${user.overallPercent}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bo'sh holat ko'rsatkichi.
class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: context.mutedColor),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: context.mutedColor)),
        ],
      ),
    );
  }
}
