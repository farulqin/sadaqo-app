import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/percent_chip.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/core/widgets/round_icon_button.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';
import 'package:sadaqo/features/zakat/presentation/pages/zakat_page.dart';
import 'package:sadaqo/features/favorite/presentation/widgets/favorite_button.dart';

class CampaignDetailPage extends StatelessWidget {
  const CampaignDetailPage({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    // Pakai data terbaru (dana dan kuota berubah setelah donasi).
    final state = context.watch<CampaignCubit>().state;
    var c = campaign;
    if (state is CampaignLoaded) {
      for (final x in state.campaigns) {
        if (x.id == campaign.id) c = x;
      }
    }

    final isQurbanUnit = c.category == ProgramCategory.qurban && c.isFixedPrice;
    final unit = c.unitLabel ?? 'unit';

    String actionLabel;
    VoidCallback? onAction;
    if (c.isZakat) {
      actionLabel = 'Hitung & Bayar Zakat  →';
      onAction = () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ZakatPage()));
    } else if (c.isFull) {
      actionLabel = 'Kuota Penuh';
      onAction = null;
    } else {
      actionLabel = isQurbanUnit ? 'Ikut Qurban  →' : 'Donasi Sekarang  →';
      onAction = () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => DonationPage(campaign: c)));
    }

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
                        category: c.category,
                        imageAsset: c.imageAsset,
                        height: 250,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: top + 8,
                        left: 12,
                        child: RoundIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: top + 8,
                        right: 12,
                        child: RoundIconButton(
                          icon: Icons.share_outlined,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fitur bagikan menyusul')),
                          ),
                        ),
                      ),
                      Positioned(
                        top: top + 8,
                        right: 58,
                        child: FavoriteButton(campaignId: c.id),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 12,
                        child: PercentChip(percent: c.progressPercent),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: 'Kategori',
                          value: c.subType == null
                              ? c.category.label
                              : '${c.category.label} • ${c.subType}',
                        ),
                        if (c.isFixedPrice)
                          _InfoRow(
                            icon: Icons.sell_outlined,
                            label: 'Harga per $unit',
                            value: Formatter.rupiah(c.unitPrice!),
                          ),
                        if (c.isSlotBased)
                          _InfoRow(
                            icon: Icons.event_seat_outlined,
                            label: 'Kuota slot',
                            value: c.isFull
                                ? 'Penuh (${c.slotTotal} dari ${c.slotTotal})'
                                : 'Terisi ${c.slotFilled ?? 0} dari ${c.slotTotal} (sisa ${c.slotsLeft})',
                          ),
                        _InfoRow(
                          icon: Icons.flag_outlined,
                          label: 'Target Dana',
                          value: Formatter.rupiah(c.targetAmount),
                        ),
                        _InfoRow(
                          icon: Icons.savings_outlined,
                          label: 'Terkumpul',
                          value: Formatter.rupiah(c.collectedAmount),
                        ),
                        _InfoRow(
                          icon: Icons.schedule,
                          label: 'Sisa Waktu',
                          value: c.isZakat ? 'Dibuka sepanjang tahun' : '${c.daysLeft} Hari lagi',
                        ),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Lokasi',
                          value: c.location,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tentang Program',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.description,
                          style: const TextStyle(height: 1.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.sandBeige,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.forestGreen),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Program ini adalah data contoh (demo) untuk pengembangan '
                                  'aplikasi. Nama, lokasi, dan angka bukan program nyata.',
                                  style: TextStyle(fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
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
              child: ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ),
          ),
        ],
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
                Text(label,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}