import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/features/profile/presentation/cubit/profile_cubit.dart';

/// Foto profil bulat: foto galeri, avatar, atau huruf awal nama jika belum dipilih.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initial, this.radius = 22});

  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final photo = state.photo;
        ImageProvider? image;
        if (photo?.bytes != null) {
          image = MemoryImage(photo!.bytes!);
        } else if (photo?.avatarAsset != null) {
          image = AssetImage(photo!.avatarAsset!);
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.sandBeige,
          backgroundImage: image,
          child: image == null
              ? Text(
                  initial,
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forestGreen,
                  ),
                )
              : null,
        );
      },
    );
  }
}