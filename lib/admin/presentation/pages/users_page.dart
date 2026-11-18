import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sadaqo/admin/core/admin_utils.dart';
import 'package:sadaqo/admin/data/admin_activity_log.dart';
import 'package:sadaqo/admin/data/admin_user_store.dart';
import 'package:sadaqo/admin/presentation/pages/moderation_dialogs.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/network/api_config.dart';
import 'package:sadaqo/features/community_feed/domain/moderation.dart';
import 'package:sadaqo/injection_container.dart';

enum _UserFilter { all, active, warned, banned }

/// Kelola pengguna: tambah, ubah, nonaktifkan, hapus, beri peringatan, banned, dan bebaskan.
/// Data tersimpan di server (tabel users).
class UsersPage extends StatefulWidget {
  const UsersPage({super.key, this.initialQuery, this.startCreate = false});

  final String? initialQuery;
  final bool startCreate;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _users = sl<AdminUserStore>();
  final _log = sl<AdminActivityLog>();
  late final TextEditingController _search;
  _UserFilter _filter = _UserFilter.all;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _users.load();
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
    final saved = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _UserForm(existing: existing, users: _users),
    );
    if (saved == null || !mounted) return;
    if (existing == null) {
      _log.add(ActivityKind.user, 'Pengguna ditambahkan admin: $saved');
      adminToast(context, 'Pengguna ditambahkan');
    } else {
      adminToast(context, 'Data pengguna disimpan');
    }
  }

  Future<void> _toggleActive(AdminUser u) async {
    final ok = await confirmDialog(
      context,
      title: u.isActive ? 'Nonaktifkan akun?' : 'Aktifkan akun?',
      message: u.isActive
          ? '${u.name} tidak akan bisa masuk ke aplikasi sampai akunnya diaktifkan lagi. Riwayat donasinya tetap tersimpan.'
          : '${u.name} bisa masuk ke aplikasi lagi.',
      confirmLabel: u.isActive ? 'Nonaktifkan' : 'Aktifkan',
      danger: u.isActive,
    );
    if (!ok || !mounted) return;
    try {
      await _users.setActive(u.id, !u.isActive);
    } on ServerException catch (e) {
      if (mounted) adminToast(context, e.message);
      return;
    }
    _log.add(ActivityKind.user, u.isActive ? 'Akun dinonaktifkan: ${u.name}' : 'Akun diaktifkan: ${u.name}');
    if (!mounted) return;
    adminToast(context, u.isActive ? 'Akun dinonaktifkan' : 'Akun diaktifkan');
  }

  Future<void> _delete(AdminUser u) async {
    final ok = await confirmDialog(
      context,
      title: 'Hapus pengguna?',
      message:
          '${u.name} (${u.email}) akan dihapus. Pengguna yang sudah punya donasi tidak bisa dihapus, nonaktifkan saja akunnya.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await _users.remove(u.id);
    } on ServerException catch (e) {
      if (mounted) adminToast(context, e.message);
      return;
    }
    _log.add(ActivityKind.user, 'Pengguna dihapus: ${u.name}');
    if (!mounted) return;
    adminToast(context, 'Pengguna dihapus');
  }

  Future<void> _warn(AdminUser u) async {
    final note = await showWarnDialog(context, u.name);
    if (note == null || !mounted) return;
    try {
      await _users.warn(u.id, note);
    } on ServerException catch (e) {
      if (mounted) adminToast(context, e.message);
      return;
    }
    _log.add(ActivityKind.user, 'Peringatan dikirim ke ${u.name}');
    if (!mounted) return;
    adminToast(context, 'Peringatan dikirim ke ${u.name}');
  }

  Future<void> _ban(AdminUser u) async {
    final choice = await showBanDialog(context, u.name);
    if (choice == null || !mounted) return;
    try {
      await _users.ban(
        u.id,
        days: choice.permanent ? null : choice.duration.inDays,
        reason: choice.reason,
      );
    } on ServerException catch (e) {
      if (mounted) adminToast(context, e.message);
      return;
    }
    _log.add(ActivityKind.user, '${u.name} dibanned dari Komunitas');
    if (!mounted) return;
    adminToast(context, '${u.name} dibanned');
  }

  Future<void> _lift(AdminUser u) async {
    final ok = await confirmDialog(
      context,
      title: 'Bebaskan banned?',
      message: '${u.name} bisa mengirim pesan lagi dan catatan pelanggarannya direset.',
      confirmLabel: 'Bebaskan',
    );
    if (!ok || !mounted) return;
    try {
      await _users.lift(u.id);
    } on ServerException catch (e) {
      if (mounted) adminToast(context, e.message);
      return;
    }
    _log.add(ActivityKind.user, 'Banned ${u.name} dibebaskan');
    if (!mounted) return;
    adminToast(context, 'Banned ${u.name} dibebaskan');
  }

  void _showDetail(AdminUser u) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _UserDetail(
        user: u,
        onEdit: () {
          Navigator.pop(ctx);
          _openForm(existing: u);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _users,
      builder: (context, _) {
        final all = _users.all;
        final bannedCount = all.where((u) => u.moderation.isBanned()).length;
        final warnedCount =
            all.where((u) => !u.moderation.isBanned() && u.strikes > 0).length;
        final q = _search.text.trim().toLowerCase();
        final items = all.where((u) {
          final s = u.moderation;
          switch (_filter) {
            case _UserFilter.all:
              break;
            case _UserFilter.active:
              if (s.isBanned() || !u.isActive) return false;
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
                if (_users.loading && all.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: AdminColors.green)),
                  )
                else if (_users.error != null && all.isEmpty)
                  AdminCard(
                    child: Column(
                      children: [
                        EmptyState(icon: Icons.cloud_off_rounded, text: _users.error!),
                        const SizedBox(height: 8),
                        AdminButton(label: 'Coba lagi', icon: Icons.refresh_rounded, onPressed: _users.load),
                      ],
                    ),
                  )
                else if (items.isEmpty)
                  const AdminCard(child: EmptyState(icon: Icons.person_search_rounded, text: 'Tidak ada pengguna yang cocok'))
                else
                  for (final u in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UserRow(
                        user: u,
                        compact: c.maxWidth < 760,
                        onTap: () => _showDetail(u),
                        onEdit: () => _openForm(existing: u),
                        onToggleActive: () => _toggleActive(u),
                        onDelete: () => _delete(u),
                        onWarn: () => _warn(u),
                        onBan: () => _ban(u),
                        onLift: () => _lift(u),
                      ),
                    ),
              ],
            );
          },
        );
      },
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
      backgroundImage: asset == null
          ? null
          : (asset.startsWith('http')
              ? NetworkImage(ApiConfig.resolveMediaUrl(asset)) as ImageProvider
              : AssetImage(asset)),
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

Pill _statusPill(AdminUser u) {
  final s = u.moderation;
  if (!u.isActive) {
    return const Pill('Nonaktif', color: AdminColors.muted, icon: Icons.person_off_rounded);
  }
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
    required this.compact,
    required this.onTap,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onWarn,
    required this.onBan,
    required this.onLift,
  });

  final AdminUser user;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onWarn;
  final VoidCallback onBan;
  final VoidCallback onLift;

  @override
  Widget build(BuildContext context) {
    final banned = user.moderation.isBanned();
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
          tooltip: user.isActive ? 'Nonaktifkan akun' : 'Aktifkan akun',
          onPressed: onToggleActive,
          icon: Icon(
            user.isActive ? Icons.person_off_outlined : Icons.how_to_reg_rounded,
            size: 21,
            color: AdminColors.muted,
          ),
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
            if (user.isManager) ...[
              const SizedBox(width: 6),
              const Pill('Pengelola', color: AdminColors.green, bg: AdminColors.limeSoft),
            ],
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
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: _statusPill(user))),
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
                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _statusPill(user))),
                actions,
              ],
            ),
    );
  }
}

class _UserDetail extends StatelessWidget {
  const _UserDetail({required this.user, required this.onEdit});

  final AdminUser user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final status = user.moderation;
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
                _statusPill(user),
                Pill(user.isManager ? 'Pengelola' : 'Donatur', color: AdminColors.green, bg: AdminColors.limeSoft),
                Pill('Bergabung ${AdminFmt.dayMonthYear(user.joinedAt)}', color: AdminColors.muted),
                Pill('Total donasi ${AdminFmt.rupiah(user.donationsTotal)}', color: AdminColors.gold),
                Pill('${user.donationsCount} transaksi', color: AdminColors.muted),
              ],
            ),
            if (status.isBanned()) ...[
              const SizedBox(height: 10),
              Text(
                'Banned sampai ${AdminFmt.dateTime(status.bannedUntil!)}',
                style: const TextStyle(color: AdminColors.danger, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              user.strikes == 0
                  ? 'Belum ada catatan pelanggaran.'
                  : 'Catatan pelanggaran: ${user.strikes}x. Pelanggaran ke-${CommunityPolicy.strikesBeforeBan} otomatis dibanned ${CommunityPolicy.banDays} hari dari Komunitas.',
              style: const TextStyle(color: AdminColors.muted),
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
  late final TextEditingController _password;
  String? _avatar;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _password = TextEditingController();
    _avatar = e?.avatarAsset;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
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

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final name = _name.text.trim();
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final e = widget.existing;
      if (e == null) {
        await widget.users.add(
          name: name,
          email: _email.text.trim(),
          phone: phone,
          password: _password.text,
          avatarAsset: _avatar,
        );
      } else {
        await widget.users.update(
          e.id,
          name: name,
          email: _email.text.trim(),
          phone: phone,
          avatarAsset: _avatar,
          avatarChanged: _avatar != e.avatarAsset,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, name);
    } on ServerException catch (err) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = err.message;
      });
    }
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
                        backgroundImage: _avatar == null
                            ? null
                            : (_avatar!.startsWith('http')
                                ? NetworkImage(ApiConfig.resolveMediaUrl(_avatar!)) as ImageProvider
                                : AssetImage(_avatar!)),
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
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password awal (minimal 8 karakter)'),
                    validator: (v) => (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: AdminColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.green),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
        ),
      ],
    );
  }
}