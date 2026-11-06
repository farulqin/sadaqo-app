import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/program_image.dart';
import 'package:sadaqo/core/widgets/round_icon_button.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_detail_page.dart';
import 'package:sadaqo/features/campaign/presentation/widgets/campaign_card.dart';
import 'package:sadaqo/features/donation/presentation/pages/donation_page.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';

/// Halaman baca berita + tombol donasi ke program terkait.
class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key, required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final paragraphs = article.content
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      body: BlocBuilder<CampaignCubit, CampaignState>(
        builder: (context, state) {
          final Campaign? related = (state is CampaignLoaded)
              ? state.campaigns
                  .where((c) => c.id == article.campaignId)
                  .firstOrNull
              : null;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ProgramImage(
                            category: article.category,
                            imageAsset: article.imageAsset,
                            height: 220,
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
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.limeGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                article.category.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${article.author}  •  ${Formatter.date(article.publishedAt)}  •  '
                              '${article.readMinutes} menit baca',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (final p in paragraphs)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Text(
                                  p,
                                  style: const TextStyle(fontSize: 15, height: 1.65),
                                ),
                              ),
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
                                      'Berita ini adalah konten contoh (demo) untuk '
                                      'pengembangan aplikasi, bukan laporan peristiwa nyata.',
                                      style: TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (related != null) ...[
                              const SizedBox(height: 22),
                              const Text(
                                'Program Terkait',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              CampaignCard(
                                campaign: related,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CampaignDetailPage(campaign: related),
                                  ),
                                ),
                              ),
                            ],
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
                    onPressed: related == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DonationPage(campaign: related),
                              ),
                            ),
                    child: const Text('Donasi Sekarang  →'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
