// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/community_feed/data/community_feed_api.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/presentation/widgets/community_widgets.dart';
import 'package:sadaqo/injection_container.dart';

String _timeRange(CommunityEvent e) {
  final f = DateFormat('HH.mm', 'id_ID');
  return e.endsAt == null
      ? '${f.format(e.startsAt)} WIB'
      : '${f.format(e.startsAt)} - ${f.format(e.endsAt!)} WIB';
}

/// Agenda kegiatan komunitas: lihat, dan tandai "Tertarik".
class CommunityAgendaPage extends StatefulWidget {
  const CommunityAgendaPage({super.key});

  @override
  State<CommunityAgendaPage> createState() => _CommunityAgendaPageState();
}

class _CommunityAgendaPageState extends State<CommunityAgendaPage> {
  final _api = sl<CommunityFeedApi>();

  List<CommunityEvent> _events = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.events();
      if (!mounted) return;
      setState(() {
        _events = list;
        _loading = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleInterest(CommunityEvent e) async {
    if (!await ensureJoined(context)) return;
    if (!mounted) return;
    try {
      final r = await _api.toggleInterest(e.id);
      if (!mounted) return;
      setState(() {
        _events = [
          for (final x in _events)
            x.id == e.id ? x.copyWith(interested: r.interested, interestedCount: r.count) : x,
        ];
      });
    } on ServerException catch (err) {
      if (mounted) showCommunitySnack(context, err.message);
    }
  }

  CommunityEvent _current(CommunityEvent e) =>
      _events.firstWhere((x) => x.id == e.id, orElse: () => e);

  void _openDetail(CommunityEvent e) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _EventDetail(
          event: _current(e),
          onInterest: () async {
            await _toggleInterest(e);
            setSheet(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _events.where((e) => !e.isPast).toList();
    final past = _events.where((e) => e.isPast).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: const Text('Agenda Komunitas'),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_events.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Text(
                              'Belum ada agenda. Pantau terus ya!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      if (upcoming.isNotEmpty) ...[
                        const Text('Akan Datang',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        for (final e in upcoming)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: e,
                              onTap: () => _openDetail(e),
                              onInterest: () => _toggleInterest(e),
                            ),
                          ),
                      ],
                      if (past.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Baru Selesai',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        for (final e in past)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _EventCard(
                              event: e,
                              onTap: () => _openDetail(e),
                              onInterest: null,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap, required this.onInterest});

  final CommunityEvent event;
  final VoidCallback onTap;
  final VoidCallback? onInterest;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final day = DateFormat('d', 'id_ID').format(e.startsAt);
    final month = DateFormat('MMM', 'id_ID').format(e.startsAt).toUpperCase();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: e.isPast ? 0.65 : 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBeige),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        month,
                        style: const TextStyle(
                          color: AppColors.limeGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.25),
                      ),
                      const SizedBox(height: 6),
                      _InfoLine(icon: Icons.schedule_rounded, text: _timeRange(e)),
                      const SizedBox(height: 3),
                      _InfoLine(
                        icon: e.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                        text: e.location,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${e.interestedCount} tertarik',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          if (!e.isPast)
                            e.interested
                                ? FilledButton.icon(
                                    onPressed: onInterest,
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Tertarik'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.forestGreen,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: onInterest,
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: AppColors.brandInk,
                                    ),
                                    child: const Text('Tertarik'),
                                  ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _EventDetail extends StatelessWidget {
  const _EventDetail({required this.event, required this.onInterest});

  final CommunityEvent event;
  final VoidCallback onInterest;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(e.startsAt);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          if (e.image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: RemoteImage(e.image, width: double.infinity, height: 170),
              ),
            ),
          Text(e.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.25)),
          const SizedBox(height: 12),
          _InfoLine(icon: Icons.event_rounded, text: date),
          const SizedBox(height: 6),
          _InfoLine(icon: Icons.schedule_rounded, text: _timeRange(e)),
          const SizedBox(height: 6),
          _InfoLine(
            icon: e.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
            text: e.location,
          ),
          if (e.description != null && e.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Tentang Acara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(e.description!, style: const TextStyle(height: 1.5)),
          ],
          if (e.creator != null) ...[
            const SizedBox(height: 14),
            Text('Diselenggarakan oleh ${e.creator}',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 16),
          Text(
            '${e.interestedCount} orang tertarik',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
          ),
          const SizedBox(height: 14),
          if (!e.isPast)
            SizedBox(
              height: 48,
              child: e.interested
                  ? FilledButton.icon(
                      onPressed: onInterest,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Kamu tertarik. Ketuk untuk batal'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.forestGreen),
                    )
                  : OutlinedButton(
                      onPressed: onInterest,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandInk),
                      child: const Text('Saya Tertarik'),
                    ),
            )
          else
            Text('Acara ini sudah selesai.',
                style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}