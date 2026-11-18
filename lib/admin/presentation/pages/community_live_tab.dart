import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sadaqo/admin/data/admin_community_store.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/community_feed/data/community_feed_api.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/domain/moderation.dart';
import 'package:sadaqo/injection_container.dart';

String _err(Object e) => e is ServerException ? e.message : 'Terjadi kesalahan. Coba lagi.';

String _ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
  if (diff.inDays < 1) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

String? get _myId => sl<AuthCubit>().user?.id;

/// Admin harus tercatat sebagai anggota Komunitas untuk menulis. Bila server
/// menolak karena belum bergabung, admin otomatis digabungkan lalu dicoba lagi.
Future<T> _withJoin<T>(CommunityFeedApi api, Future<T> Function() call) async {
  try {
    return await call();
  } on ServerException catch (e) {
    if (!e.message.toLowerCase().contains('gabung')) rethrow;
    await api.join();
    return call();
  }
}

// ===================== Tindakan terhadap penulis =====================

Future<void> warnAuthor(BuildContext context, CommunityAuthor a) async {
  final store = sl<AdminCommunityStore>();
  final note = TextEditingController();
  ViolationType type = ViolationType.hoax;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text('Beri peringatan ke ${a.name}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Jenis pelanggaran', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in ViolationType.values)
                    ChoiceChip(
                      label: Text(v.label),
                      selected: type == v,
                      onSelected: (_) => setS(() => type = v),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pesan peringatan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pelanggaran ke-${CommunityPolicy.strikesBeforeBan} otomatis dibanned ${CommunityPolicy.banDays} hari.',
                style: const TextStyle(fontSize: 12, color: AdminColors.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.warn),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim peringatan'),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final err = await store.warnUser(a.id, message: note.text.trim(), violation: type);
  if (context.mounted) adminToast(context, err ?? 'Peringatan dikirim ke ${a.name}');
}

Future<void> banAuthor(BuildContext context, CommunityAuthor a) async {
  final store = sl<AdminCommunityStore>();
  final reason = TextEditingController();
  int days = CommunityPolicy.banDays;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text('Banned ${a.name}?'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lama banned', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final d in const [1, 7, 30, 90])
                    ChoiceChip(
                      label: Text('$d hari'),
                      selected: days == d,
                      onSelected: (_) => setS(() => days = d),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reason,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Alasan', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Banned'),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final err = await store.banUser(a.id, days: days, reason: reason.text.trim());
  if (context.mounted) adminToast(context, err ?? '${a.name} dibanned $days hari');
}

Future<void> unbanAuthor(BuildContext context, CommunityAuthor a) async {
  final ok = await confirmDialog(
    context,
    title: 'Cabut banned?',
    message: '${a.name} dapat menulis lagi di Komunitas.',
    confirmLabel: 'Cabut banned',
  );
  if (!ok || !context.mounted) return;
  final err = await sl<AdminCommunityStore>().unbanUser(a.id);
  if (context.mounted) adminToast(context, err ?? 'Banned ${a.name} dicabut');
}

/// Menu tindakan terhadap seorang penulis (peringatan, banned, cabut banned).
class _AuthorMenu extends StatelessWidget {
  const _AuthorMenu({required this.author});

  final CommunityAuthor author;

  @override
  Widget build(BuildContext context) {
    // Admin/pengelola dan akun sendiri tidak dapat dikenai sanksi dari sini.
    if (author.isStaff || author.id == _myId) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Tindakan untuk ${author.name}',
      onSelected: (v) {
        switch (v) {
          case 'warn':
            warnAuthor(context, author);
          case 'ban':
            banAuthor(context, author);
          case 'unban':
            unbanAuthor(context, author);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'warn', child: Text('Beri peringatan')),
        PopupMenuItem(value: 'ban', child: Text('Banned pengguna')),
        PopupMenuItem(value: 'unban', child: Text('Cabut banned')),
      ],
      child: const Pill('Tindakan pengguna', color: AdminColors.warn, icon: Icons.gavel_rounded),
    );
  }
}

// ===================== Tab Live =====================

/// Pantauan Komunitas hampir real-time: daftar post diperbarui otomatis tiap
/// beberapa detik. Admin dapat menulis post/pengumuman, membuat polling,
/// membalas komentar, menyematkan, menghapus, memberi peringatan, dan banned.
class CommunityLiveTab extends StatefulWidget {
  const CommunityLiveTab({super.key});

  @override
  State<CommunityLiveTab> createState() => _CommunityLiveTabState();
}

class _CommunityLiveTabState extends State<CommunityLiveTab> {
  static const _interval = Duration(seconds: 8);

  final _api = sl<CommunityFeedApi>();
  Timer? _timer;
  List<CommunityPost> _first = const [];
  final List<CommunityPost> _more = [];
  int _morePages = 0;
  int _lastPage = 1;
  bool _loading = true;
  bool _live = true;
  bool _offline = false;
  String? _error;
  DateTime? _updated;

  List<CommunityPost> get _posts => [
        ..._first,
        ..._more.where((p) => !_first.any((f) => f.id == p.id)),
      ];

  @override
  void initState() {
    super.initState();
    _load();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (_live) _load(quiet: true);
    });
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _loading = true);
    try {
      final res = await _api.posts();
      if (!mounted) return;
      setState(() {
        _first = res.items;
        _lastPage = res.lastPage;
        _loading = false;
        _offline = false;
        _error = null;
        _updated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (quiet) {
          _offline = true; // tetap tampilkan data terakhir
        } else {
          _error = _err(e);
        }
      });
    }
  }

  Future<void> _loadMore() async {
    try {
      final res = await _api.posts(page: _morePages + 2);
      if (!mounted) return;
      setState(() {
        _more.addAll(res.items);
        _morePages++;
        _lastPage = res.lastPage;
      });
    } catch (e) {
      if (mounted) adminToast(context, _err(e));
    }
  }

  void _removeLocal(String id) {
    _first = _first.where((p) => p.id != id).toList();
    _more.removeWhere((p) => p.id == id);
  }

  Future<void> _pin(CommunityPost p) async {
    try {
      final pinned = await _api.togglePin(p.id);
      if (!mounted) return;
      adminToast(context, pinned ? 'Post disematkan' : 'Sematan dilepas');
      await _load(quiet: true);
    } catch (e) {
      if (mounted) adminToast(context, _err(e));
    }
  }

  Future<void> _delete(CommunityPost p) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus post?',
      message: 'Post dari ${p.author.name} beserta komentarnya dihapus permanen.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await _api.deletePost(p.id);
      if (!mounted) return;
      setState(() => _removeLocal(p.id));
      adminToast(context, 'Post dihapus');
    } catch (e) {
      if (mounted) adminToast(context, _err(e));
    }
  }

  void _openComments(CommunityPost p) {
    showDialog<void>(context: context, builder: (_) => _CommentsDialog(post: p, api: _api)).then((_) {
      if (mounted) _load(quiet: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _first.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _first.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            AdminButton(label: 'Coba lagi', icon: Icons.refresh_rounded, outlined: true, onPressed: _load),
          ],
        ),
      );
    }
    final posts = _posts;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _statusBar(),
          const SizedBox(height: 10),
          _Composer(
            api: _api,
            onPosted: () => _load(quiet: true),
          ),
          const SizedBox(height: 12),
          if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EmptyState(icon: Icons.forum_outlined, text: 'Belum ada post.'),
            ),
          for (final p in posts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PostCard(
                post: p,
                onComments: () => _openComments(p),
                onPin: () => _pin(p),
                onDelete: () => _delete(p),
              ),
            ),
          if (_morePages + 1 < _lastPage)
            Center(child: TextButton(onPressed: _loadMore, child: const Text('Muat lebih banyak'))),
        ],
      ),
    );
  }

  Widget _statusBar() {
    final color = !_live
        ? AdminColors.muted
        : _offline
            ? AdminColors.warn
            : AdminColors.green;
    final label = !_live
        ? 'Dijeda'
        : _offline
            ? 'Terputus, mencoba lagi...'
            : 'LIVE';
    final t = _updated;
    final time = t == null
        ? ''
        : 'Diperbarui ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Pill(label, color: color, icon: Icons.circle),
        const SizedBox(width: 10),
        Expanded(child: Text(time, style: const TextStyle(fontSize: 12, color: AdminColors.muted))),
        TextButton.icon(
          onPressed: () {
            setState(() => _live = !_live);
            if (_live) _load(quiet: true);
          },
          icon: Icon(_live ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
          label: Text(_live ? 'Jeda' : 'Lanjutkan'),
        ),
        IconButton(tooltip: 'Muat ulang', onPressed: () => _load(quiet: true), icon: const Icon(Icons.refresh_rounded)),
      ],
    );
  }
}

// ===================== Kartu post =====================

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onComments,
    required this.onPin,
    required this.onDelete,
  });

  final CommunityPost post;
  final VoidCallback onComments;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final poll = p.poll;
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.author.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (p.author.isOnline)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.circle, size: 9, color: AdminColors.green),
                ),
              Text(_ago(p.createdAt), style: const TextStyle(fontSize: 12, color: AdminColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(p.author.roleLabel, color: AdminColors.muted),
              Pill(p.category == 'info' ? 'Pengumuman' : 'Diskusi'),
              if (p.isPinned) const Pill('Disematkan', color: AdminColors.warn, icon: Icons.push_pin_rounded),
              if (poll != null) const Pill('Polling', color: AdminColors.gold, icon: Icons.poll_rounded),
            ],
          ),
          const SizedBox(height: 8),
          Text(p.body),
          if (poll != null) ...[
            const SizedBox(height: 10),
            Text(poll.question, style: const TextStyle(fontWeight: FontWeight.w800)),
            for (final o in poll.options)
              BarRow(
                label: o.label,
                valueText: '${o.votes} suara (${o.percent}%)',
                fraction: (o.percent / 100).clamp(0.0, 1.0),
              ),
            Text(
              '${poll.totalVotes} suara • ${poll.isClosed ? 'ditutup' : 'masih berjalan'}',
              style: const TextStyle(fontSize: 12, color: AdminColors.muted),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${p.likeCount} apresiasi • ${p.commentCount} komentar',
            style: const TextStyle(fontSize: 12, color: AdminColors.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminButton(label: 'Komentar', icon: Icons.chat_bubble_outline_rounded, outlined: true, onPressed: onComments),
              AdminButton(
                label: p.isPinned ? 'Lepas sematan' : 'Sematkan',
                icon: Icons.push_pin_outlined,
                outlined: true,
                onPressed: onPin,
              ),
              AdminButton(label: 'Hapus', icon: Icons.delete_outline_rounded, danger: true, outlined: true, onPressed: onDelete),
              _AuthorMenu(author: p.author),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================== Penulis post / polling =====================

class _Composer extends StatefulWidget {
  const _Composer({required this.api, required this.onPosted});

  final CommunityFeedApi api;
  final VoidCallback onPosted;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _body = TextEditingController();
  final _question = TextEditingController();
  final List<TextEditingController> _options = [TextEditingController(), TextEditingController()];
  String _category = 'info';
  bool _poll = false;
  int _days = 3;
  bool _sending = false;

  @override
  void dispose() {
    _body.dispose();
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    final body = _body.text.trim();
    final question = _question.text.trim();
    final options = _options.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (body.isEmpty) {
      adminToast(context, 'Isi pesan belum diisi.');
      return;
    }
    if (_poll && (question.isEmpty || options.length < 2)) {
      adminToast(context, 'Polling butuh pertanyaan dan minimal 2 pilihan.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _withJoin(
        widget.api,
        () => widget.api.createPost(
          category: _category,
          body: body,
          pollQuestion: _poll ? question : null,
          pollOptions: _poll ? options : const [],
          pollDays: _days,
        ),
      );
      if (!mounted) return;
      _body.clear();
      _question.clear();
      for (final c in _options) {
        c.clear();
      }
      setState(() {
        _poll = false;
        _sending = false;
      });
      adminToast(context, 'Terkirim ke Komunitas');
      widget.onPosted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      adminToast(context, _err(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tulis sebagai Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Tulis pengumuman atau pesan untuk anggota Komunitas...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Pengumuman'),
                selected: _category == 'info',
                onSelected: (_) => setState(() => _category = 'info'),
              ),
              ChoiceChip(
                label: const Text('Diskusi'),
                selected: _category == 'diskusi',
                onSelected: (_) => setState(() => _category = 'diskusi'),
              ),
              FilterChip(
                avatar: const Icon(Icons.poll_rounded, size: 18),
                label: const Text('Tambah polling'),
                selected: _poll,
                onSelected: (v) => setState(() => _poll = v),
              ),
            ],
          ),
          if (_poll) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _question,
              decoration: const InputDecoration(labelText: 'Pertanyaan polling', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _options[i],
                        decoration: InputDecoration(labelText: 'Pilihan ${i + 1}', border: const OutlineInputBorder()),
                      ),
                    ),
                    if (_options.length > 2)
                      IconButton(
                        tooltip: 'Hapus pilihan',
                        onPressed: () => setState(() => _options.removeAt(i).dispose()),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_options.length < 5)
                  TextButton.icon(
                    onPressed: () => setState(() => _options.add(TextEditingController())),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah pilihan'),
                  ),
                const Text('Berlangsung'),
                for (final d in const [1, 3, 7])
                  ChoiceChip(label: Text('$d hari'), selected: _days == d, onSelected: (_) => setState(() => _days = d)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AdminButton(
              label: _sending ? 'Mengirim...' : 'Kirim',
              icon: Icons.send_rounded,
              onPressed: _sending ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== Komentar (obrolan) =====================

class _CommentsDialog extends StatefulWidget {
  const _CommentsDialog({required this.post, required this.api});

  final CommunityPost post;
  final CommunityFeedApi api;

  @override
  State<_CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<_CommentsDialog> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;
  List<CommunityComment> _items = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final list = await widget.api.comments(widget.post.id);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!quiet) _error = _err(e);
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _withJoin(widget.api, () => widget.api.addComment(widget.post.id, text));
      if (!mounted) return;
      _input.clear();
      setState(() => _sending = false);
      await _load(quiet: true);
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      adminToast(context, _err(e));
    }
  }

  Future<void> _delete(CommunityComment c) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus komentar?',
      message: 'Komentar dari ${c.author.name} dihapus.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await widget.api.deleteComment(c.id);
      if (!mounted) return;
      adminToast(context, 'Komentar dihapus');
      await _load(quiet: true);
    } catch (e) {
      if (mounted) adminToast(context, _err(e));
    }
  }

  Widget _tile(CommunityComment c, {required bool reply}) {
    final mine = c.author.id == _myId;
    return Padding(
      padding: EdgeInsets.only(left: reply ? 28 : 0, bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? AdminColors.limeSoft : AdminColors.card,
          border: Border.all(color: AdminColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${c.author.name}${c.author.isStaff ? ' (${c.author.roleLabel})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                Text(_ago(c.createdAt), style: const TextStyle(fontSize: 11, color: AdminColors.muted)),
              ],
            ),
            const SizedBox(height: 4),
            Text(c.body),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InkWell(
                  onTap: () => _delete(c),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Text('Hapus', style: TextStyle(color: AdminColors.danger, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
                _AuthorMenu(author: c.author),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: h * 0.85),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Pill('LIVE', icon: Icons.circle),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Komentar: ${widget.post.author.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _items.isEmpty
                            ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, text: 'Belum ada komentar.')
                            : ListView(
                                controller: _scroll,
                                children: [
                                  for (final c in _items) ...[
                                    _tile(c, reply: false),
                                    for (final r in c.replies) _tile(r, reply: true),
                                  ],
                                ],
                              ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Balas sebagai Admin...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}