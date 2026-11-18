import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sadaqo/admin/data/admin_community_store.dart';
import 'package:sadaqo/admin/presentation/pages/community_live_tab.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/error/exceptions.dart';
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
  if (diff.inDays < 30) return '${diff.inDays} hari lalu';
  return DateFormat('d MMM yyyy', 'id_ID').format(d);
}

/// Moderasi Komunitas untuk admin: tinjau laporan, sematkan/hapus post, kelola agenda.
class CommunityModerationPage extends StatefulWidget {
  const CommunityModerationPage({super.key});

  @override
  State<CommunityModerationPage> createState() => _CommunityModerationPageState();
}

class _CommunityModerationPageState extends State<CommunityModerationPage> {
  final _store = sl<AdminCommunityStore>();

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: LayoutBuilder(
        builder: (context, c) {
          final pad = c.maxWidth < 600 ? 14.0 : 24.0;
          return Padding(
            padding: EdgeInsets.fromLTRB(pad, 4, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Moderasi Komunitas',
                  subtitle: 'Pantau Komunitas secara live, tulis pengumuman dan polling, beri peringatan atau banned, serta kelola agenda.',
                ),
                ListenableBuilder(
                  listenable: _store,
                  builder: (context, _) => TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AdminColors.green,
                    unselectedLabelColor: AdminColors.muted,
                    indicatorColor: AdminColors.green,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: [
                      Tab(text: _store.pendingCount > 0 ? 'Laporan (${_store.pendingCount})' : 'Laporan'),
                      const Tab(text: 'Live'),
                      const Tab(text: 'Agenda'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ReportsTab(store: _store),
                      const CommunityLiveTab(),
                      const _AgendaTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===================== Laporan =====================

class _ReportsTab extends StatefulWidget {
  const _ReportsTab({required this.store});

  final AdminCommunityStore store;

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  String _filter = 'pending'; // pending | done | all

  Future<void> _valid(CommunityReport r) async {
    final type = await showDialog<ViolationType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Jenis pelanggaran'),
        children: [
          for (final v in ViolationType.values)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, v), child: Text(v.label)),
        ],
      ),
    );
    if (type == null || !mounted) return;
    final ok = await confirmDialog(
      context,
      title: 'Nyatakan laporan valid?',
      message:
          'Konten disembunyikan dari Komunitas. Penulis mendapat peringatan, dan pelanggaran ke-${CommunityPolicy.strikesBeforeBan} otomatis dibanned ${CommunityPolicy.banDays} hari.',
      confirmLabel: 'Valid & beri sanksi',
      danger: true,
    );
    if (!ok || !mounted) return;
    final err = await widget.store.review(r, valid: true, violation: type);
    if (mounted) adminToast(context, err ?? 'Konten disembunyikan dan sanksi dicatat');
  }

  Future<void> _dismiss(CommunityReport r) async {
    final err = await widget.store.review(r, valid: false);
    if (mounted) adminToast(context, err ?? 'Laporan ditolak');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final s = widget.store;
        final items = s.reports.where((r) {
          if (_filter == 'pending') return r.isPending;
          if (_filter == 'done') return !r.isPending;
          return true;
        }).toList();
        return RefreshIndicator(
          onRefresh: s.load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final f in const [('pending', 'Menunggu'), ('done', 'Selesai'), ('all', 'Semua')])
                    ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      showCheckmark: false,
                      selectedColor: AdminColors.green,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _filter == f.$1 ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                      onSelected: (_) => setState(() => _filter = f.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (s.loading && s.reports.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
              else if (s.error != null && s.reports.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(s.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      AdminButton(label: 'Coba lagi', icon: Icons.refresh_rounded, outlined: true, onPressed: s.load),
                    ],
                  ),
                )
              else if (items.isEmpty)
                EmptyState(
                  icon: Icons.verified_user_outlined,
                  text: _filter == 'pending' ? 'Tidak ada laporan yang menunggu.' : 'Belum ada laporan.',
                )
              else
                for (final r in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReportCard(report: r, onValid: () => _valid(r), onDismiss: () => _dismiss(r)),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onValid, required this.onDismiss});

  final CommunityReport report;
  final VoidCallback onValid;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final (statusLabel, statusColor) = switch (r.status) {
      'valid' => ('Valid', AdminColors.danger),
      'dismissed' => ('Ditolak', AdminColors.muted),
      _ => ('Menunggu', AdminColors.warn),
    };
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(r.kind == 'comment' ? 'Komentar' : 'Post', icon: r.kind == 'comment' ? Icons.chat_bubble_outline : Icons.article_outlined),
              Pill(statusLabel, color: statusColor),
              if (r.isHidden) const Pill('Disembunyikan', color: AdminColors.warn, icon: Icons.visibility_off_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Text('Alasan: ${r.reason}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.page,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(r.content.isEmpty ? '(konten sudah dihapus)' : r.content, maxLines: 5, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 8),
          Text(
            'Penulis: ${r.authorName ?? '-'} • Pelapor: ${r.reporterName} • ${_ago(r.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AdminColors.muted),
          ),
          if (r.isPending) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AdminButton(label: 'Valid, beri sanksi', icon: Icons.gavel_rounded, danger: true, onPressed: onValid),
                AdminButton(label: 'Tolak laporan', icon: Icons.close_rounded, outlined: true, onPressed: onDismiss),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===================== Agenda =====================

class _AgendaTab extends StatefulWidget {
  const _AgendaTab();

  @override
  State<_AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<_AgendaTab> {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _err(e);
        _loading = false;
      });
    }
  }

  Future<void> _form([CommunityEvent? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EventForm(existing: existing),
    );
    if (saved == true && mounted) {
      adminToast(context, existing == null ? 'Agenda ditambahkan' : 'Agenda diperbarui');
      _load();
    }
  }

  Future<void> _delete(CommunityEvent e) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus agenda?',
      message: '"${e.title}" akan hilang dari Komunitas.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await _api.deleteEvent(e.id);
      if (!mounted) return;
      adminToast(context, 'Agenda dihapus');
      _load();
    } catch (err) {
      if (mounted) adminToast(context, _err(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM yyyy • HH.mm', 'id_ID');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AdminButton(label: 'Tambah Agenda', icon: Icons.add_rounded, onPressed: () => _form()),
          ),
          const SizedBox(height: 12),
          if (_loading && _events.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_error != null && _events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  AdminButton(label: 'Coba lagi', icon: Icons.refresh_rounded, outlined: true, onPressed: _load),
                ],
              ),
            )
          else if (_events.isEmpty)
            const EmptyState(icon: Icons.event_busy_rounded, text: 'Belum ada agenda.')
          else
            for (final e in _events)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Pill(e.isOnline ? 'Online' : 'Tatap muka', icon: e.isOnline ? Icons.videocam_outlined : Icons.place_outlined),
                          if (e.isPast) const Pill('Selesai', color: AdminColors.muted),
                          Pill('${e.interestedCount} tertarik', color: AdminColors.gold),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(fmt.format(e.startsAt), style: const TextStyle(fontSize: 13)),
                      Text(e.location, style: const TextStyle(fontSize: 13, color: AdminColors.muted)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AdminButton(label: 'Ubah', icon: Icons.edit_outlined, outlined: true, onPressed: () => _form(e)),
                          AdminButton(label: 'Hapus', icon: Icons.delete_outline_rounded, danger: true, outlined: true, onPressed: () => _delete(e)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _EventForm extends StatefulWidget {
  const _EventForm({this.existing});

  final CommunityEvent? existing;

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _api = sl<CommunityFeedApi>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _location = TextEditingController(text: widget.existing?.location ?? '');
  late final _desc = TextEditingController(text: widget.existing?.description ?? '');
  late bool _online = widget.existing?.isOnline ?? false;
  late DateTime _start = widget.existing?.startsAt ?? DateTime.now().add(const Duration(days: 1)).copyWith(minute: 0, second: 0, millisecond: 0);
  late DateTime? _end = widget.existing?.endsAt;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final loc = _location.text.trim();
    if (title.length < 5) return setState(() => _error = 'Judul minimal 5 karakter');
    if (loc.isEmpty) return setState(() => _error = 'Lokasi wajib diisi');
    if (_end != null && !_end!.isAfter(_start)) return setState(() => _error = 'Waktu selesai harus setelah waktu mulai');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.saveEvent(
        id: widget.existing?.id,
        title: title,
        location: loc,
        isOnline: _online,
        startsAt: _start,
        endsAt: _end,
        description: _desc.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _err(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE, d MMM yyyy • HH.mm', 'id_ID');
    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah Agenda' : 'Ubah Agenda'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 12),
              TextField(controller: _location, decoration: const InputDecoration(labelText: 'Lokasi / tautan')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acara online'),
                value: _online,
                onChanged: (v) => setState(() => _online = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: const Text('Mulai'),
                subtitle: Text(fmt.format(_start)),
                onTap: () async {
                  final d = await _pick(_start);
                  if (d != null) setState(() => _start = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_rounded),
                title: const Text('Selesai (opsional)'),
                subtitle: Text(_end == null ? 'Belum diatur' : fmt.format(_end!)),
                trailing: _end == null
                    ? null
                    : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _end = null)),
                onTap: () async {
                  final d = await _pick(_end ?? _start.add(const Duration(hours: 2)));
                  if (d != null) setState(() => _end = d);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _desc,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_error!, style: const TextStyle(color: AdminColors.danger)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.green),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}
