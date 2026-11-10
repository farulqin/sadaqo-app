import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/admin_analytics_store.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/admin/presentation/pages/moderation_dialogs.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/features/community/data/datasources/community_admin_datasource.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';
import 'package:sadaqo/injection_container.dart';

enum _UserFilter { all, active, warned, banned }

/// Kelola pengguna: tambah, ubah, hapus, beri peringatan, banned, dan bebaskan.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key, this.initialQuery, this.startCreate = false});

  final String? initialQuery;
  final bool startCreate;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _users = sl<AdminUserStore>();
  final _community = sl<CommunityAdminDataSource>();
  final _analytics = sl<AdminAnalyticsStore>();
  final _log = sl<AdminActivityLog>();
  late final TextEditingController _search;
  _UserFilter _filter = _UserFilter.all;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    // Sisa waktu banned diperbarui berkala.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    if (widget.startCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openForm();
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({AdminUser? existing}) async {
    final result = await showDialog<_UserFormResult>(
      context: context,
      builder: (ctx) => _UserForm(existing: existing, users: _users),
    );
    if (result == null || !mounted) return;
    if (existing == null) {
      _users.add(
        name: result.name,
        email: result.email,
        phone: result.phone,
        avatarAsset: result.avatar,
      );
      _log.add(ActivityKind.user, 'Pengguna ditambahkan admin: ${result.name}');
      adminToast(context, 'Pengguna ditambahkan');
    } else {
      _users.update(
        existing.copyWith(
          name: result.name,
          email: result.email,
          phone: result.phone,
          avatarAsset: result.avatar,
          clearAvatar: result.avatar == null,
        ),
      );
      adminToast(context, 'Data pengguna disimpan');
    }
  }

  Future<void> _delete(AdminUser u) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus pengguna?',
      message:
          '${u.name} (${u.email}) akan dihapus dari daftar. Riwayat donasinya tetap tersimpan karena transaksi tidak dapat diubah admin.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    _users.remove(u.id);
    _log.add(ActivityKind.user, 'Pengguna dihapus: ${u.name}');
    adminToast(context, 'Pengguna dihapus');
  }

  void _showDetail(AdminUser u) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _UserDetail(
        user: u,
        donated: _donatedBy(u),
        onEdit: () {
          Navigator.pop(ctx);
          _openForm(existing: u);
        },
      ),
    );
  }

  int _donatedBy(AdminUser u) => _analytics.all
      .where((t) => t.donorName == u.name)
      .fold<int>(0, (a, t) => a + t.amount);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _community.changes,
      builder: (context, _) => ListenableBuilder(
        listenable: _users,
        builder: (context, _) {
          final all = _users.all;
          ModerationStatus st(AdminUser u) => _community.statusOf(u.id);
          final bannedCount = all.where((u) => st(u).isBanned()).length;
          final warnedCount = all.where((u) => !st(u).isBanned() && st(u).strikes > 0).length;
          final q = _search.text.trim().toLowerCase();
          final items = all.where((u) {
            final s = st(u);
            switch (_filter) {
              case _UserFilter.all:
                break;
              case _UserFilter.active:
                if (s.isBanned()) return false;
                break;
              case _UserFilter.warned:
                if (s.isBanned() || s.strikes == 0) return false;
                break;
              case _UserFilter.banned:
                if (!s.isBanned()) return false;
                break;
            }
            if (q.isEmpty) return true;
            return u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                (u.phone?.contains(q) ?? false);
          }).toList();

          return LayoutBuilder(
            builder: (context, c) {
              final pad = c.maxWidth < 600 ? 14.0 : 24.0;
              return ListView(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                children: [
                  PageHeader(
                    title: 'Kelola Pengguna',
                    subtitle: '${all.length} pengguna • $bannedCount dibanned • $warnedCount dalam peringatan',
                    actions: [
                      AdminButton(label: 'Tambah Pengguna', icon: Icons.person_add_alt_1_rounded, onPressed: () => _openForm()),
                    ],
                  ),
                  AdminSearchField(
                    controller: _search,
                    hint: 'Cari nama, email, atau nomor HP...',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('Semua (${all.length})', _UserFilter.all),
                        _chip('Aktif', _UserFilter.active),
                        _chip('Peringatan ($warnedCount)', _UserFilter.warned),
                        _chip('Dibanned ($bannedCount)', _UserFilter.banned),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    const AdminCard(child: EmptyState(icon: Icons.person_search_rounded, text: 'Tidak ada pengguna yang cocok'))
                  else
                    for (final u in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _UserRow(
                          user: u,
                          status: st(u),
                          compact: c.maxWidth < 760,
                          onTap: () => _showDetail(u),
                          onEdit: () => _openForm(existing: u),
                          onDelete: () => _delete(u),
                          onWarn: () async {
                            if (await ModerationActions.warn(context, u.id, u.name) && context.mounted) {
                              adminToast(context, 'Peringatan dikirim ke ${u.name}');
                            }
                          },
                          onBan: () async {
                            if (await ModerationActions.ban(context, u.id, u.name) && context.mounted) {
                              adminToast(context, '${u.name} dibanned');
                            }
                          },
                          onLift: () async {
                            if (await ModerationActions.lift(context, u.id, u.name) && context.mounted) {
                              adminToast(context, 'Banned ${u.name} dibebaskan');
                            }
                          },
                        ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _chip(String label, _UserFilter f) {
    final selected = _filter == f;
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
        onSelected: (_) => setState(() => _filter = f),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar(this.user, {this.radius = 24});

  final AdminUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final asset = user.avatarAsset;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AdminColors.goldSoft,
      backgroundImage: asset == null ? null : AssetImage(asset),
      onBackgroundImageError: asset == null ? null : (e, s) {},
      child: asset == null
          ? Text(
              user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
              style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w800, color: AdminColors.green),
            )
          : null,
    );
  }
}

Pill _statusPill(ModerationStatus s) {
  if (s.isBanned()) {
    final until = s.bannedUntil!;
    return Pill('Banned • ${AdminFmt.remaining(until)}', color: AdminColors.danger, icon: Icons.block_rounded);
  }
  if (s.strikes > 0) {
    return Pill('Peringatan ${s.strikes}x', color: AdminColors.warn, icon: Icons.warning_amber_rounded);
  }
  return const Pill('Aktif', color: AdminColors.green, icon: Icons.check_circle_outline_rounded);
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.status,
    required this.compact,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onWarn,
    required this.onBan,
    required this.onLift,
  });

  final AdminUser user;
  final ModerationStatus status;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWarn;
  final VoidCallback onBan;
  final VoidCallback onLift;

  @override
  Widget build(BuildContext context) {
    final banned = status.isBanned();
    final actions = Wrap(
      spacing: 4,
      children: [
        IconButton(tooltip: 'Ubah', onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 20)),
        IconButton(
          tooltip: 'Beri peringatan',
          onPressed: onWarn,
          icon: const Icon(Icons.warning_amber_rounded, size: 21, color: AdminColors.warn),
        ),
        if (banned)
          IconButton(
            tooltip: 'Bebaskan banned',
            onPressed: onLift,
            icon: const Icon(Icons.lock_open_rounded, size: 21, color: AdminColors.green),
          )
        else
          IconButton(
            tooltip: 'Banned',
            onPressed: onBan,
            icon: const Icon(Icons.block_rounded, size: 21, color: AdminColors.danger),
          ),
        IconButton(
          tooltip: 'Hapus',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 21, color: AdminColors.danger),
        ),
      ],
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
            if (user.isDemo) ...[
              const SizedBox(width: 6),
              const Pill('Contoh', color: AdminColors.muted),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(user.email, style: const TextStyle(fontSize: 12.5, color: AdminColors.muted)),
        const SizedBox(height: 2),
        Text('Bergabung ${AdminFmt.dayMonthYear(user.joinedAt)}', style: const TextStyle(fontSize: 12, color: AdminColors.muted)),
      ],
    );
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [_UserAvatar(user), const SizedBox(width: 12), Expanded(child: info)]),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: _statusPill(status))),
                    actions,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                _UserAvatar(user),
                const SizedBox(width: 14),
                Expanded(flex: 3, child: info),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _statusPill(status))),
                actions,
              ],
            ),
    );
  }
}

class _UserDetail extends StatelessWidget {
  const _UserDetail({required this.user, required this.donated, required this.onEdit});

  final AdminUser user;
  final int donated;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final ds = sl<CommunityAdminDataSource>();
    final status = ds.statusOf(user.id);
    final events = ds.events.where((e) => e.userId == user.id).take(8).toList();
    return Dialog(
      backgroundColor: AdminColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: ListView(
          padding: const EdgeInsets.all(22),
          shrinkWrap: true,
          children: [
            Row(
              children: [
                _UserAvatar(user, radius: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      Text(user.email, style: const TextStyle(color: AdminColors.muted)),
                      if (user.phone != null) Text(user.phone!, style: const TextStyle(color: AdminColors.muted)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusPill(status),
                Pill('Bergabung ${AdminFmt.dayMonthYear(user.joinedAt)}', color: AdminColors.muted),
                Pill('Total donasi ${AdminFmt.rupiah(donated)}', color: AdminColors.gold),
              ],
            ),
            if (status.isBanned()) ...[
              const SizedBox(height: 10),
              Text(
                'Banned sampai ${AdminFmt.dateTime(status.bannedUntil!)}',
                style: const TextStyle(color: AdminColors.danger, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 18),
            const Text('Riwayat moderasi', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text('Belum ada catatan pelanggaran.', style: TextStyle(color: AdminColors.muted)),
              )
            else
              for (final e in events)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.action.isAuto ? Icons.security_rounded : Icons.admin_panel_settings_rounded,
                    color: AdminColors.warn,
                  ),
                  title: Text(e.action.label),
                  subtitle: Text('${e.detail}\n${AdminFmt.ago(e.at)}'),
                  isThreeLine: true,
                ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: AdminButton(label: 'Ubah Data', icon: Icons.edit_rounded, onPressed: onEdit),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFormResult {
  const _UserFormResult(this.name, this.email, this.phone, this.avatar);

  final String name;
  final String email;
  final String? phone;
  final String? avatar;
}

class _UserForm extends StatefulWidget {
  const _UserForm({required this.users, this.existing});

  final AdminUserStore users;
  final AdminUser? existing;

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  String? _avatar;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _avatar = e?.avatarAsset;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final p = await showAssetPicker(
      context,
      title: 'Pilih avatar',
      groups: const ['avatar'],
      selected: _avatar,
    );
    if (p != null) setState(() => _avatar = p);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      backgroundColor: AdminColors.card,
      title: Text(isEdit ? 'Ubah Pengguna' : 'Tambah Pengguna'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AdminColors.goldSoft,
                        backgroundImage: _avatar == null ? null : AssetImage(_avatar!),
                        child: _avatar == null
                            ? const Icon(Icons.person_rounded, size: 40, color: AdminColors.green)
                            : null,
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: AdminColors.green,
                          child: Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_avatar != null)
                  TextButton(onPressed: () => setState(() => _avatar = null), child: const Text('Hapus avatar')),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    final e = (v ?? '').trim().toLowerCase();
                    if (!e.contains('@') || !e.contains('.')) return 'Format email tidak valid';
                    final dup = widget.users.all.any(
                      (u) => u.email.toLowerCase() == e && u.id != widget.existing?.id,
                    );
                    if (dup) return 'Email sudah dipakai pengguna lain';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor HP (opsional)'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.green),
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            Navigator.pop(
              context,
              _UserFormResult(
                _name.text.trim(),
                _email.text.trim(),
                _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                _avatar,
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
