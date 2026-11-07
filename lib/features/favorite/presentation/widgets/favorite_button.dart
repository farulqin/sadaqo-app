import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/favorite/presentation/cubit/favorite_cubit.dart';

/// Tombol hati bulat untuk menandai program favorit.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.campaignId, this.size = 36});

  final String campaignId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteCubit, FavoriteState>(
      builder: (context, state) {
        final fav = state.isFavorite(campaignId);
        return Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              context.read<FavoriteCubit>().toggle(campaignId);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    duration: const Duration(milliseconds: 1200),
                    content: Text(fav ? 'Dihapus dari favorit' : 'Ditambahkan ke favorit'),
                  ),
                );
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                size: size * 0.55,
                color: fav ? const Color(0xFFD94B4B) : AppColors.forestGreen,
              ),
            ),
          ),
        );
      },
    );
  }
}