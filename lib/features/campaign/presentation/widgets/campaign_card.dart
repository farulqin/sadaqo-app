import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/percent_chip.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/favorite/presentation/widgets/favorite_button.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({super.key, required this.campaign, required this.onTap});

  final Campaign campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProgramImage(
                  category: campaign.category,
                  imageAsset: campaign.imageAsset,
                  height: 150,
                  width: double.infinity,
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: PercentChip(percent: campaign.progressPercent),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: FavoriteButton(campaignId: campaign.id, size: 34),
                ),
                if (campaign.subType != null)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        campaign.subType!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          campaign.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: campaign.progress,
                      minHeight: 8,
                      backgroundColor: AppColors.sandBeige,
                      color: AppColors.limeGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Amount(
                        label: 'Terkumpul',
                        value: Formatter.rupiah(campaign.collectedAmount),
                      ),
                      _Amount(
                        label: 'Target',
                        value: Formatter.rupiah(campaign.targetAmount),
                        alignEnd: true,
                      ),
                    ],
                  ),
                  if (campaign.isSlotBased) ...[
                    const SizedBox(height: 8),
                    Text(
                      campaign.isFull
                          ? 'Kuota penuh'
                          : 'Slot terisi ${campaign.slotFilled ?? 0}/${campaign.slotTotal}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: campaign.isFull ? AppColors.error : AppColors.forestGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.label, required this.value, this.alignEnd = false});

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}