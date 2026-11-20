// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/community_agenda_page.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/post_detail_page.dart';
import 'package:sadaqo/features/notification/domain/entities/app_notification.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  /// Notifikasi yang belum dibaca saat halaman dibuka (untuk sorotan).
  late final Set<String> _unreadAtOpen;
  String _tab = 'all'; // all | activity | system

  static const _tabs = [
    ('all', 'Semua'),
    ('activity', 'Aktivitas'),
    ('system', 'Sistem'),
  ];

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

  IconData _icon(AppNotification n) {
    switch (n.refType) {
      case 'post':
        return Icons.forum_rounded;
      case 'event':
        return Icons.event_rounded;
    }
    return n.type == 'activity'
        ? Icons.notifications_active_outlined
        : Icons.info_outline_rounded;
  }

  void _open(BuildContext context, AppNotification n) {
    final id = n.refId;
    if (id == null) return;
    switch (n.refType) {
      case 'post':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => PostDetailPage(postId: id)),
        );
      case 'event':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CommunityAgendaPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          final items = state.items
              .where((n) => _tab == 'all' || n.type == _tab)
              .toList();

          return Column(
            children: [
              SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  children: [
                    for (final t in _tabs)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t.$2),
                          selected: _tab == t.$1,
                          showCheckmark: false,
                          selectedColor: AppColors.forestGreen,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _tab == t.$1 ? Colors.white : AppColors.textDark,
                          ),
                          onSelected: (_) => setState(() => _tab = t.$1),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none, size: 56, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text('Belum ada notifikasi'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = items[i];
                          final highlight = _unreadAtOpen.contains(n.id);
                          final tappable = n.refId != null;
                          return Material(
                            color: highlight ? AppColors.successSoft : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: tappable ? () => _open(context, n) : null,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.sandBeige,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_icon(n), size: 20, color: AppColors.brandInk),
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
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (tappable)
                                      Icon(Icons.chevron_right_rounded,
                                          color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}