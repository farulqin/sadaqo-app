import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_cubit.dart';
import 'package:sadaqo/features/campaign/presentation/cubit/campaign_state.dart';
import 'package:sadaqo/features/campaign/presentation/pages/campaign_detail_page.dart';
import 'package:sadaqo/features/campaign/presentation/widgets/campaign_card.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Program Favorit')),
      body: BlocBuilder<FavoriteCubit, FavoriteState>(
        builder: (context, fav) {
          final campaignState = context.watch<CampaignCubit>().state;
          if (campaignState is! CampaignLoaded) return const LoadingView();

          final items =
              campaignState.campaigns.where((c) => fav.ids.contains(c.id)).toList();

          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 56, color: AppColors.textMuted),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada program favorit',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ketuk ikon hati pada sebuah program untuk menyimpannya di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, i) => CampaignCard(
              campaign: items[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CampaignDetailPage(campaign: items[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}