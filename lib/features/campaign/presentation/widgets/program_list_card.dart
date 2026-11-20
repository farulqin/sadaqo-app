// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/favorite/presentation/widgets/favorite_button.dart';
import 'package:sadaqo/core/widgets/interactive_card.dart';
import 'package:sadaqo/core/widgets/pressable_scale.dart';
import 'package:sadaqo/core/widgets/animated_progress_bar.dart';

/// Kartu program untuk daftar di tab Program: gambar dengan lencana,
/// info singkat, progres, dan tombol donasi.
class ProgramListCard extends StatelessWidget {
  const ProgramListCard({
    super.key,
    required this.campaign,
    required this.onTap,
    required this.onDonate,
    this.badge,
  });

  final Campaign campaign;
  final VoidCallback onTap;
  final VoidCallback onDonate;

  /// Lencana di pojok gambar: 'Program Unggulan', 'Mendesak', atau 'Terbaru'.
  final String? badge;

  static (Color, IconData) _badgeStyle(String label) {
    switch (label) {
      case 'Mendesak':
        return (const Color(0xFFE5532D), Icons.local_fire_department_rounded);
      case 'Terbaru':
        return (AppColors.success, Icons.eco_rounded);
      default:
        return (const Color(0xFF6FA82B), Icons.star_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return InteractiveCard(radius: 20, child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 118,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProgramImage(category: c.category, imageAsset: c.imageAsset, height: 150, width: 118),
                      if (badge != null)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _badgeStyle(badge!).$1,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_badgeStyle(badge!).$2, size: 12, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  badge == 'Program Unggulan' ? 'Unggulan' : badge!,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(right: 6, top: 6, child: FavoriteButton(campaignId: c.id, size: 28)),
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('${c.daysLeft} hari lagi', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppColors.brandInk),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(c.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.3, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedProgressBar(
                            value: c.progress,
                            minHeight: 7,
                            radius: 6,
                            backgroundColor: AppColors.sandBeige,
                            color: AppColors.limeGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${c.progressPercent}%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.brandInk)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${Formatter.rupiah(c.collectedAmount)} / ${Formatter.rupiah(c.targetAmount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: c.isFull ? null : onDonate,
                        icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
                        label: Text(c.isFull ? 'Kuota penuh' : 'Donasi Sekarang  →'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.forestGreen,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ).pressable(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
