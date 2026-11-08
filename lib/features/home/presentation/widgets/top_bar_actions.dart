import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/features/notification/presentation/pages/notification_page.dart';
import 'package:sadaqo/features/profile/presentation/pages/profile_page.dart';
import 'package:sadaqo/features/profile/presentation/widgets/user_avatar.dart';

/// Bagian kanan atas: lonceng notifikasi + foto profil (membuka halaman Profil).
/// Bisa dipasang di AppBar halaman lain: `actions: const [TopBarActions()]`.
class TopBarActions extends StatelessWidget {
  const TopBarActions({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = context.watch<AuthCubit>().user?.initial ?? '?';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) => IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
            icon: Badge(
              isLabelVisible: state.unread > 0,
              label: Text('${state.unread}'),
              child: Icon(Icons.notifications_none, color: color),
            ),
          ),
        ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: UserAvatar(initial: initial, radius: 16),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}