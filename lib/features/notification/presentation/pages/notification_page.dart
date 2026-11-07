import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  /// Notifikasi yang belum dibaca saat halaman dibuka (untuk sorotan).
  late final Set<String> _unreadAtOpen;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<NotificationCubit>();
    _unreadAtOpen = {
      for (final n in cubit.state.items)
        if (!n.isRead) n.id,
    };
    // Tandai dibaca setelah halaman tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) => cubit.markAllRead());
  }

  String _time(DateTime d) =>
      '${Formatter.date(d)} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('Belum ada notifikasi'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = state.items[i];
              final highlight = _unreadAtOpen.contains(n.id);
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: highlight ? AppColors.successSoft : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.sandBeige,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(n.body),
                          const SizedBox(height: 6),
                          Text(
                            _time(n.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}