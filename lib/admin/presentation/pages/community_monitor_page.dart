import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/admin/presentation/pages/moderation_dialogs.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/features/community/data/datasources/community_admin_datasource.dart';
import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/usecases/community_usecases.dart';
import 'package:sadaqo/injection_container.dart';

enum _Tab { live, reports, banned, log }

/// Pantau Komunitas secara real-time: pesan masuk, laporan pengguna, daftar banned,
/// dan log moderasi (otomatis maupun oleh admin).
class CommunityMonitorPage extends StatefulWidget {
  const CommunityMonitorPage({super.key});

  @override
  State<CommunityMonitorPage> createState() => _CommunityMonitorPageState();
}

class _CommunityMonitorPageState extends State<CommunityMonitorPage> {
  final _ds = sl<CommunityAdminDataSource>();
  final _users = sl<AdminUserStore>();
  _Tab _tab = _Tab.live;
  Timer? _tick;
  Timer? _sim;
  bool _simulate = false;
  final _rnd = Random();

  static const List<String> _normal = [
    'Alhamdulillah, donasi untuk masjid terus bertambah, semoga berkah 🤲',
    'Semoga semua donatur diberi rezeki yang berlimpah ya ❤️',
    'Ada yang tahu cara hitung zakat maal? Makasih infonya 😊',
    'Barusan ikut qurban kolektif, tinggal sedikit slot lagi!',
    'Mantap programnya, semangat berbagi 🌱',
    'Terima kasih admin, aplikasinya makin mudah dipakai',
    'Semoga korban bencana segera mendapat bantuan 🙏',
    'Jazakumullahu khairan untuk semua yang berdonasi',
  ];
  static const List<String> _violating = [
    'slot gacor, klik link hadiah gratis ini sekarang',
    'sebarkan sebelum dihapus, ada berita rahasia',
    'dasar kafir laknat semuanya',
    'transfer dulu ya baru hadiahnya dikirim',
    'kirim otp kamu untuk klaim donasi',
  ];

  @override
  void initState() {
    super.initState();
    // Sisa waktu banned dan "x menit lalu" diperbarui berkala.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _sim?.cancel();
    super.dispose();
  }

  void _toggleSim(bool on) {
    setState(() => _simulate = on);
    _sim?.cancel();
    if (!on) return;
    _sim = Timer.periodic(const Duration(seconds: 5), (_) => _simulateOne());
    _simulateOne();
  }

  /// Mengirim pesan contoh lewat usecase SendMessage yang SAMA dengan aplikasi,
  /// sehingga penyaringan otomatis, peringatan, dan banned otomatis ikut berjalan.
  Future<void> _simulateOne() async {
    final pool = _users.all.where((u) => u.isDemo && u.id != 'seed-3').toList();
    if (pool.isEmpty) return;
    final u = pool[_rnd.nextInt(pool.length)];
    final bad = _rnd.nextDouble() < 0.28;
    final text = bad
        ? _violating[_rnd.nextInt(_violating.length)]
        : _normal[_rnd.nextInt(_normal.length)];
    await sl<SendMessage>()(
      SendMessageParams(userId: u.id, userName: u.name, text: text, avatarAsset: u.avatarAsset),
    );
  }

  String _nameOf(String userId, {String? fallback}) =>
      _users.byId(userId)?.name ?? fallback ?? userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _ds.changes,
      builder: (context, _) => ListenableBuilder(
        listenable: _users,
        builder: (context, _) {
          final messages = _ds.messages;
          final reports = _ds.reports;
          final statuses = _ds.allStatuses;
          final banned = statuses.entries.where((e) => e.value.isBanned()).toList();
          final warned = statuses.entries.where((e) => !e.value.isBanned() && e.value.strikes > 0).toList();
          final events = _ds.events;
          final today = DateTime.now();
          final todayCount = messages
              .where((m) => m.createdAt.year == today.year && m.createdAt.month == today.month && m.createdAt.day == today.day)
              .length;
          final reportedIds = <String, int>{};
          for (final r in reports) {
            reportedIds[r.messageId] = (reportedIds[r.messageId] ?? 0) + 1;
          }

          return LayoutBuilder(
            builder: (context, c) {
              final pad = c.maxWidth < 600 ? 14.0 : 24.0;
              final cols = c.maxWidth >= 1000 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
              const gap = 12.0;
              final w = (c.maxWidth - pad * 2 - gap * (cols - 1)) / cols;
              return ListView(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                children: [
                  PageHeader(
                    title: 'Komunitas',
                    subtitle: 'Pantau percakapan secara real-time, beri peringatan, dan kelola banned.',
                    actions: [
                      const _LivePill(),
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: AdminColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Simulasi pesan masuk', style: TextStyle(fontSize: 13)),
                            Switch(
                              value: _simulate,
                              activeThumbColor: AdminColors.green,
                              onChanged: _toggleSim,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(width: w, child: _mini(Icons.chat_bubble_outline_rounded, '$todayCount', 'Pesan hari ini', AdminColors.green)),
                      SizedBox(width: w, child: _mini(Icons.flag_outlined, '${reportedIds.length}', 'Pesan dilaporkan', AdminColors.warn)),
                      SizedBox(width: w, child: _mini(Icons.block_rounded, '${banned.length}', 'Pengguna dibanned', AdminColors.danger)),
                      SizedBox(
                        width: w,
                        child: _mini(
                          Icons.security_rounded,
                          '${events.where((e) => e.action.isAuto).length}',
                          'Pelanggaran terdeteksi otomatis',
                          AdminColors.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('Live Chat', _Tab.live),
                        _chip('Laporan (${reportedIds.length})', _Tab.reports),
                        _chip('Banned (${banned.length})', _Tab.banned),
                        _chip('Log Moderasi', _Tab.log),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  switch (_tab) {
                    _Tab.live => _liveTab(messages, reportedIds),
                    _Tab.reports => _reportsTab(messages, reportedIds),
                    _Tab.banned => _bannedTab(banned, warned),
                    _Tab.log => _logTab(events),
                  },
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _mini(IconData icon, String value, String label, Color color) {
    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(fontSize: 12, color: AdminColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Tab t) {
    final selected = _tab == t;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AdminColors.green,
        backgroundColor: AdminColors.card,
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _tab = t),
      ),
    );
  }

  // ---------------- Live chat ----------------
  Widget _liveTab(List<ChatMessage> messages, Map<String, int> reported) {
    if (messages.isEmpty) {
      return const AdminCard(child: EmptyState(icon: Icons.forum_outlined, text: 'Belum ada pesan'));
    }
    final list = messages.reversed.take(60).toList();
    return Column(
      children: [
        for (final m in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MessageTile(
              message: m,
              reportCount: reported[m.id] ?? 0,
              banned: _ds.statusOf(m.userId).isBanned(),
              onAction: (a) => _handle(a, m),
            ),
          ),
      ],
    );
  }

  // ---------------- Laporan ----------------
  Widget _reportsTab(List<ChatMessage> messages, Map<String, int> reported) {
    final items = [
      for (final m in messages.reversed)
        if (reported.containsKey(m.id)) m,
    ];
    if (items.isEmpty) {
      return const AdminCard(
        child: EmptyState(icon: Icons.verified_rounded, text: 'Tidak ada laporan terbuka. Komunitas aman.'),
      );
    }
    return Column(
      children: [
        for (final m in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MessageTile(
              message: m,
              reportCount: reported[m.id] ?? 0,
              banned: _ds.statusOf(m.userId).isBanned(),
              onAction: (a) => _handle(a, m),
              showDismiss: true,
            ),
          ),
      ],
    );
  }

  Future<void> _handle(_MsgAction a, ChatMessage m) async {
    switch (a) {
      case _MsgAction.delete:
        final ok = await confirmDialog(
          context,
          title: 'Hapus pesan?',
          message: 'Pesan dari ${m.userName} akan dihapus dari Komunitas.',
          confirmLabel: 'Hapus',
          danger: true,
        );
        if (ok) {
          _ds.deleteMessage(m.id);
          if (mounted) adminToast(context, 'Pesan dihapus');
        }
      case _MsgAction.warn:
        if (await ModerationActions.warn(context, m.userId, m.userName) && mounted) {
          adminToast(context, 'Peringatan dikirim ke ${m.userName}');
        }
      case _MsgAction.ban:
        if (await ModerationActions.ban(context, m.userId, m.userName) && mounted) {
          adminToast(context, '${m.userName} dibanned');
        }
      case _MsgAction.lift:
        if (await ModerationActions.lift(context, m.userId, m.userName) && mounted) {
          adminToast(context, 'Banned ${m.userName} dibebaskan');
        }
      case _MsgAction.dismiss:
        _ds.dismissReport(m.id);
        adminToast(context, 'Laporan ditutup');
    }
  }

  // ---------------- Banned ----------------
  Widget _bannedTab(
    List<MapEntry<String, dynamic>> banned,
    List<MapEntry<String, dynamic>> warned,
  ) {
    Widget row(MapEntry<String, dynamic> e, {required bool isBan}) {
      final s = _ds.statusOf(e.key);
      final name = _nameOf(e.key, fallback: _lastNameFromMessages(e.key));
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AdminCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: LayoutBuilder(
            builder: (context, c) {
              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  if (isBan && s.bannedUntil != null)
                    Text(
                      'Sisa ${AdminFmt.remaining(s.bannedUntil!)} • sampai ${AdminFmt.dateTime(s.bannedUntil!)}',
                      style: const TextStyle(fontSize: 12.5, color: AdminColors.danger),
                    )
                  else
                    Text('${s.strikes}x pelanggaran, belum dibanned', style: const TextStyle(fontSize: 12.5, color: AdminColors.warn)),
                ],
              );
              final buttons = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isBan) ...[
                    AdminButton(
                      label: 'Ubah Durasi',
                      icon: Icons.timer_outlined,
                      outlined: true,
                      onPressed: () async {
                        if (await ModerationActions.ban(context, e.key, name) && context.mounted) {
                          adminToast(context, 'Durasi banned $name diperbarui');
                        }
                      },
                    ),
                    AdminButton(
                      label: 'Bebaskan',
                      icon: Icons.lock_open_rounded,
                      onPressed: () async {
                        if (await ModerationActions.lift(context, e.key, name) && context.mounted) {
                          adminToast(context, 'Banned $name dibebaskan');
                        }
                      },
                    ),
                  ] else ...[
                    AdminButton(
                      label: 'Banned',
                      icon: Icons.block_rounded,
                      danger: true,
                      outlined: true,
                      onPressed: () async {
                        if (await ModerationActions.ban(context, e.key, name) && context.mounted) {
                          adminToast(context, '$name dibanned');
                        }
                      },
                    ),
                    AdminButton(
                      label: 'Reset Catatan',
                      icon: Icons.restart_alt_rounded,
                      outlined: true,
                      onPressed: () {
                        _ds.liftBan(e.key, name);
                        adminToast(context, 'Catatan pelanggaran $name direset');
                      },
                    ),
                  ],
                ],
              );
              if (c.maxWidth < 620) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 10), buttons]);
              }
              return Row(children: [Expanded(child: info), buttons]);
            },
          ),
        ),
      );
    }

    if (banned.isEmpty && warned.isEmpty) {
      return const AdminCard(
        child: EmptyState(icon: Icons.sentiment_satisfied_alt_rounded, text: 'Tidak ada pengguna yang dibanned atau diperingatkan'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (banned.isNotEmpty) ...[
          const SectionTitle('Sedang dibanned', icon: Icons.block_rounded),
          const SizedBox(height: 10),
          for (final e in banned) row(e, isBan: true),
        ],
        if (warned.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionTitle('Dalam peringatan', icon: Icons.warning_amber_rounded),
          const SizedBox(height: 10),
          for (final e in warned) row(e, isBan: false),
        ],
      ],
    );
  }

  String? _lastNameFromMessages(String userId) {
    for (final m in _ds.messages.reversed) {
      if (m.userId == userId) return m.userName;
    }
    for (final e in _ds.events) {
      if (e.userId == userId) return e.userName;
    }
    return null;
  }

  // ---------------- Log ----------------
  Widget _logTab(List<ModerationEvent> events) {
    if (events.isEmpty) {
      return const AdminCard(child: EmptyState(icon: Icons.history_rounded, text: 'Belum ada catatan moderasi'));
    }
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        children: [
          for (final e in events.take(80))
            ListTile(
              dense: true,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (e.action.isAuto ? AdminColors.warn : AdminColors.green).withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  e.action.isAuto ? Icons.security_rounded : Icons.admin_panel_settings_rounded,
                  size: 20,
                  color: e.action.isAuto ? AdminColors.warn : AdminColors.green,
                ),
              ),
              title: Text('${e.action.label} • ${e.userName}'),
              subtitle: Text(e.detail, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(AdminFmt.ago(e.at), style: const TextStyle(fontSize: 11.5, color: AdminColors.muted)),
            ),
        ],
      ),
    );
  }
}

enum _MsgAction { delete, warn, ban, lift, dismiss }

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.reportCount,
    required this.banned,
    required this.onAction,
    this.showDismiss = false,
  });

  final ChatMessage message;
  final int reportCount;
  final bool banned;
  final ValueChanged<_MsgAction> onAction;
  final bool showDismiss;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final asset = m.avatarAsset;
    final flagged = reportCount > 0;
    return AdminCard(
      padding: const EdgeInsets.all(12),
      color: flagged ? const Color(0xFFFFF4E0) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AdminColors.goldSoft,
            backgroundImage: asset == null ? null : AssetImage(asset),
            onBackgroundImageError: asset == null ? null : (e, s) {},
            child: asset == null
                ? Text(
                    m.userName.isEmpty ? '?' : m.userName[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AdminColors.green),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(m.userName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(AdminFmt.ago(m.createdAt), style: const TextStyle(fontSize: 11.5, color: AdminColors.muted)),
                    if (banned) const Pill('Banned', color: AdminColors.danger),
                    if (flagged) Pill('Dilaporkan ${reportCount}x', color: AdminColors.warn, icon: Icons.flag_rounded),
                  ],
                ),
                const SizedBox(height: 4),
                Text(m.text),
                if (m.reactions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final e in m.reactions.entries)
                        Pill('${e.key} ${e.value.length}', color: AdminColors.muted),
                    ],
                  ),
                ],
                if (showDismiss) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AdminButton(label: 'Hapus Pesan', icon: Icons.delete_outline_rounded, danger: true, onPressed: () => onAction(_MsgAction.delete)),
                      AdminButton(label: 'Peringatan', icon: Icons.warning_amber_rounded, outlined: true, onPressed: () => onAction(_MsgAction.warn)),
                      AdminButton(label: 'Tutup Laporan', icon: Icons.check_rounded, outlined: true, onPressed: () => onAction(_MsgAction.dismiss)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_MsgAction>(
            tooltip: 'Tindakan',
            onSelected: onAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: _MsgAction.delete, child: Text('Hapus pesan')),
              const PopupMenuItem(value: _MsgAction.warn, child: Text('Beri peringatan')),
              if (banned)
                const PopupMenuItem(value: _MsgAction.lift, child: Text('Bebaskan banned'))
              else
                const PopupMenuItem(value: _MsgAction.ban, child: Text('Banned pengguna')),
              if (flagged) const PopupMenuItem(value: _MsgAction.dismiss, child: Text('Tutup laporan')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Penanda "LIVE" berkedip.
class _LivePill extends StatefulWidget {
  const _LivePill();

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.25, end: 1).animate(_c),
            child: const Icon(Icons.circle, size: 11, color: AdminColors.danger),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(fontWeight: FontWeight.w800, color: AdminColors.danger, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
