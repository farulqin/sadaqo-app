import 'package:flutter/material.dart';
import 'package:sadaqo/admin/presentation/widgets/admin_widgets.dart';
import 'package:sadaqo/features/community/data/datasources/community_admin_datasource.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/injection_container.dart';

/// Pilihan banned dari admin: lamanya dan alasan.
class BanChoice {
  const BanChoice(this.duration, this.reason);

  final Duration duration;
  final String reason;

  bool get permanent => duration.inDays >= 3650;
}

/// Dialog peringatan. Mengembalikan isi peringatan, atau null jika batal.
Future<String?> showWarnDialog(BuildContext context, String userName) async {
  final controller = TextEditingController(
    text: 'Mohon jaga etika di Komunitas SADAQO. Pesanmu melanggar ketentuan komunitas.',
  );
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Beri peringatan ke $userName'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Isi peringatan'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.warn),
          onPressed: () {
            if (controller.text.trim().isEmpty) return;
            Navigator.pop(ctx, controller.text.trim());
          },
          child: const Text('Kirim Peringatan'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Dialog banned: admin menentukan lamanya. Mengembalikan null jika batal.
Future<BanChoice?> showBanDialog(BuildContext context, String userName, {Duration? current}) {
  return showDialog<BanChoice>(
    context: context,
    builder: (ctx) => _BanDialog(userName: userName),
  );
}

class _BanDialog extends StatefulWidget {
  const _BanDialog({required this.userName});

  final String userName;

  @override
  State<_BanDialog> createState() => _BanDialogState();
}

class _BanDialogState extends State<_BanDialog> {
  static const List<(String, int)> _presets = [
    ('1 hari', 1),
    ('3 hari', 3),
    ('7 hari', 7),
    ('14 hari', 14),
    ('30 hari', 30),
    ('90 hari', 90),
    ('1 tahun', 365),
    ('Permanen', 36500),
    ('Kustom', -1),
  ];

  int _days = 7;
  final _custom = TextEditingController(text: '10');
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _custom.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    var days = _days;
    if (days == -1) {
      final n = int.tryParse(_custom.text.trim());
      if (n == null || n < 1 || n > 36500) {
        setState(() => _error = 'Isi jumlah hari antara 1 dan 36.500');
        return;
      }
      days = n;
    }
    Navigator.pop(context, BanChoice(Duration(days: days), _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Banned ${widget.userName}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lama banned dari Komunitas', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _presets)
                    ChoiceChip(
                      label: Text(p.$1),
                      selected: _days == p.$2,
                      showCheckmark: false,
                      selectedColor: p.$2 == 36500 ? AdminColors.danger : AdminColors.green,
                      labelStyle: TextStyle(
                        color: _days == p.$2 ? Colors.white : const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() {
                        _days = p.$2;
                        _error = null;
                      }),
                    ),
                ],
              ),
              if (_days == -1) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _custom,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah hari',
                    suffixText: 'hari',
                    errorText: _error,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _reason,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Alasan (opsional)'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Selama banned, pengguna tidak bisa mengirim pesan di Komunitas. Admin dapat membebaskannya kapan saja.',
                style: TextStyle(fontSize: 12, color: AdminColors.muted),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
          onPressed: _submit,
          child: const Text('Banned'),
        ),
      ],
    );
  }
}

/// Aksi moderasi yang dipakai halaman Pengguna dan Komunitas.
class ModerationActions {
  ModerationActions._();

  static CommunityAdminDataSource get _ds => sl<CommunityAdminDataSource>();

  static Future<bool> warn(BuildContext context, String userId, String userName) async {
    final note = await showWarnDialog(context, userName);
    if (note == null) return false;
    _ds.warnUser(userId, userName, note: note);
    // Pada demo satu perangkat, peringatan dicatat di notifikasi aplikasi.
    // Dengan backend, kirim sebagai push notification ke pengguna terkait.
    sl<NotificationCubit>().add(
      title: 'Peringatan dari admin',
      body: note,
      important: true,
    );
    return true;
  }

  static Future<bool> ban(BuildContext context, String userId, String userName) async {
    final choice = await showBanDialog(context, userName);
    if (choice == null) return false;
    _ds.banUser(
      userId,
      userName,
      choice.duration,
      note: choice.reason.isEmpty ? null : choice.reason,
    );
    sl<NotificationCubit>().add(
      title: 'Akunmu dibanned dari Komunitas',
      body: choice.permanent
          ? 'Kamu dibanned permanen dari Komunitas.${choice.reason.isEmpty ? '' : ' Alasan: ${choice.reason}'}'
          : 'Kamu dibanned ${choice.duration.inDays} hari dari Komunitas.${choice.reason.isEmpty ? '' : ' Alasan: ${choice.reason}'}',
      important: true,
    );
    return true;
  }

  static Future<bool> lift(BuildContext context, String userId, String userName) async {
    final ok = await confirmDialog(
      context,
      title: 'Bebaskan banned?',
      message: '$userName bisa mengirim pesan lagi dan catatan pelanggarannya direset.',
      confirmLabel: 'Bebaskan',
    );
    if (!ok) return false;
    _ds.liftBan(userId, userName);
    sl<NotificationCubit>().add(
      title: 'Banned dibebaskan',
      body: 'Akunmu sudah bisa kembali berpartisipasi di Komunitas. Mohon patuhi ketentuan komunitas.',
      important: true,
    );
    return true;
  }
}
