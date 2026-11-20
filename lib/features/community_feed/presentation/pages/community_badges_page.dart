// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';

/// Apresiasi dan Badge Kebaikan: ringkasan aktivitas dan badge yang sudah diraih.
class CommunityBadgesPage extends StatefulWidget {
  const CommunityBadgesPage({super.key});

  @override
  State<CommunityBadgesPage> createState() => _CommunityBadgesPageState();
}

class _CommunityBadgesPageState extends State<CommunityBadgesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityFeedCubit>().refreshQuiet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: const Text('Apresiasi & Badge'),
      ),
      body: BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
        builder: (context, state) {
          final o = state.overview;
          if (o == null) return const LoadingView();

          final staffKeys = {'admin', 'pengelola'};
          final earnedKeys = o.myBadges.map((b) => b.key).toSet();
          final locked = o.catalog
              .where((b) => !b.earned && !staffKeys.contains(b.key))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kebaikanmu di Komunitas',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Setiap post, komentar, dan apresiasi menumbuhkan benih kebaikan.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _Stat(value: o.posts, label: 'Post'),
                        _Stat(value: o.comments, label: 'Komentar'),
                        _Stat(value: o.appreciations, label: 'Apresiasi'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Badge Saya (${earnedKeys.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (o.myBadges.isEmpty)
                Text(
                  'Belum ada badge. Berdonasi atau aktif di Komunitas untuk mendapatkannya.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              else
                for (final b in o.myBadges) _BadgeTile(badge: b, earned: true),
              if (locked.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Badge yang Bisa Diraih',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                for (final b in locked) _BadgeTile(badge: b, earned: false),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(color: AppColors.limeGreen, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.earned});

  final CommunityBadge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: earned ? 1 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: earned ? AppColors.limeGreen : AppColors.sandBeige),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: earned ? AppColors.successSoft : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: earned
                  ? Text(badge.icon, style: const TextStyle(fontSize: 24))
                  : Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    badge.description,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}