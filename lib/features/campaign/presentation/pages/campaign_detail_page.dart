import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/percent_chip.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';

class CampaignDetailPage extends StatelessWidget {
  const CampaignDetailPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ProgramImage(
                        category: campaign.category,
                        imageAsset: campaign.imageAsset,
                        height: 230,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: top + 8,
                        left: 12,
                        child: _RoundButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: top + 8,
                        right: 12,
                        child: _RoundButton(
                          icon: Icons.share_outlined,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fitur bagikan menyusul')),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 12,
                        child: PercentChip(percent: campaign.progressPercent),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.flag_outlined,
                          label: 'Target Dana',
                          value: Formatter.rupiah(campaign.targetAmount),
                        ),
                        _InfoRow(
                          icon: Icons.savings_outlined,
                          label: 'Terkumpul',
                          value: Formatter.rupiah(campaign.collectedAmount),
                        ),
                        _InfoRow(
                          icon: Icons.schedule,
                          label: 'Sisa Waktu',
                          value: '${campaign.daysLeft} Hari lagi',
                        ),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: campaign.location,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tentang Program',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          campaign.description,
                          style: const TextStyle(height: 1.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DonationPage(campaign: campaign),
                  ),
                ),
                child: const Text('Donasi Sekarang  →'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: AppColors.forestGreen),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sandBeige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.forestGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
