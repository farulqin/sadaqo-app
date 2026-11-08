import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/navigation/main_tab_controller.dart';
import 'package:sadaqo/core/utils/formatter.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sadaqo/features/community/domain/entities/chat_message.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';
import 'package:sadaqo/features/community/presentation/cubit/community_cubit.dart';
import 'package:sadaqo/features/home/presentation/widgets/top_bar_actions.dart';
import 'package:sadaqo/features/notification/presentation/cubit/notification_cubit.dart';
import 'package:sadaqo/injection_container.dart';

/// Ruang obrolan donatur: kirim chat, emote, dan reaksi. Ada moderasi konten:
/// pelanggaran pertama = peringatan keras, berikutnya = banned 30 hari.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const List<String> _emotes = [
    '🤲', '🕌', '🌱', '❤️', '🙏', '😊', '👍', '✨', '🎉', '🥰', '😢', '☪️',
  ];
  static const List<String> _reactions = ['🤲', '❤️', '👍', '😊', '🙏', '🌱'];

  final _controller = TextEditingController();
  bool _showEmotes = false;

  String get _userId => context.read<AuthCubit>().user?.id ?? 'guest';
  String get _userName => context.read<AuthCubit>().user?.name ?? 'Donatur';

  @override
  void initState() {
    super.initState();
    context.read<CommunityCubit>().load(_userId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final cubit = context.read<CommunityCubit>();
    final ok = await cubit.send(userId: _userId, userName: _userName, text: text);
    // Pesan terlarang juga dikosongkan agar tidak terkirim ulang.
    if (mounted && (ok || cubit.state.notice != null)) _controller.clear();
  }

  void _insertEmote(String emote) {
    _controller.text = '${_controller.text}$emote';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  void _onEvent(BuildContext context, CommunityState state) {
    final error = state.errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final notice = state.notice;
    if (notice == null) return;

    final ban = notice.isBan;
    final until = notice.status.bannedUntil;
    final title = ban ? 'Pelanggaran Berat: Akun Dibanned' : 'Peringatan Keras';
    final body = ban
        ? 'Kamu kembali melanggar aturan Komunitas (${notice.type.label}). Akunmu '
            'dibanned dari fitur Komunitas selama ${CommunityPolicy.banDays} hari '
            '(sampai ${until == null ? '-' : Formatter.date(until)}). '
            'Kamu tetap bisa berdonasi dan memakai fitur lain.'
        : 'Pesanmu mengandung konten terlarang: ${notice.type.label}. Pesan tidak '
            'dikirim. Ini peringatan keras pertama. Jika kamu mengulanginya, akunmu '
            'otomatis dibanned dari Komunitas selama ${CommunityPolicy.banDays} hari.';

    // Pemberitahuan pelanggaran tetap masuk notifikasi walau notifikasi dimatikan.
    context.read<NotificationCubit>().add(title: title, body: body, important: true);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          ban ? Icons.block : Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 48,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(body, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Saya Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showRules(BuildContext context) {
    const rules = [
      (Icons.report_gmailerrorred, 'Hoaks', 'Menyebarkan kabar bohong atau menyesatkan.'),
      (Icons.sentiment_very_dissatisfied, 'Ujaran kebencian', 'Menyerang atau mengancam orang lain.'),
      (Icons.money_off, 'Penipuan / scam', 'Meminta transfer, OTP, atau mengarahkan ke tautan mencurigakan.'),
      (Icons.no_adult_content, 'Pornografi', 'Konten dewasa dalam bentuk apa pun.'),
      (Icons.gavel, 'Penistaan agama', 'Menghina agama, kitab suci, atau tokoh agama.'),
      (Icons.mic_off, 'Kata kotor', 'Makian dan bahasa kasar.'),
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aturan Komunitas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(r.$1, size: 20, color: AppColors.forestGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${r.$2}: ',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: r.$3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Text(
                'Sanksi: pelanggaran pertama mendapat peringatan keras. Jika diulangi, '
                'akun otomatis dibanned dari Komunitas selama ${CommunityPolicy.banDays} hari. '
                'Donasi tetap bisa dilakukan.',
                style: const TextStyle(fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 8),
              const Text(
                'Melihat pesan bermasalah? Ketuk pesannya lalu pilih "Laporkan pesan".',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, ChatMessage message, bool mine) {
    final cubit = context.read<CommunityCubit>();
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Beri reaksi', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  for (final e in _reactions)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        cubit.toggleReaction(
                          messageId: message.id,
                          emoji: e,
                          userId: _userId,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.sandBeige,
                          shape: BoxShape.circle,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
              if (!mine) ...[
                const Divider(height: 28),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined, color: AppColors.error),
                  title: const Text('Laporkan pesan'),
                  subtitle: const Text(
                    'Hoaks, ujaran kebencian, scam, pornografi, penistaan agama, atau kata kotor',
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final ok = await cubit.report(messageId: message.id, userId: _userId);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Laporan terkirim. Terima kasih sudah menjaga komunitas.'
                              : 'Gagal mengirim laporan',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunityCubit, CommunityState>(
      listenWhen: (a, b) => a.eventId != b.eventId,
      listener: _onEvent,
      builder: (context, state) {
        final banned = state.status.isBanned();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Komunitas'),
            actions: [
              IconButton(
                onPressed: () => _showRules(context),
                icon: const Icon(Icons.rule_folder_outlined, color: Colors.white),
                tooltip: 'Aturan Komunitas',
              ),
              const TopBarActions(),
            ],
          ),
          body: banned
              ? _BannedView(status: state.status)
              : Column(
                  children: [
                    _RulesStrip(onTap: () => _showRules(context)),
                    Expanded(
                      child: state.loading
                          ? const LoadingView()
                          : _messageList(context, state),
                    ),
                    if (_showEmotes) _EmotePanel(emotes: _emotes, onPick: _insertEmote),
                    _Composer(
                      controller: _controller,
                      sending: state.sending,
                      showEmotes: _showEmotes,
                      onToggleEmotes: () => setState(() => _showEmotes = !_showEmotes),
                      onSend: _send,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _messageList(BuildContext context, CommunityState state) {
    if (state.messages.isEmpty) {
      return const Center(child: Text('Belum ada pesan. Jadilah yang pertama menyapa!'));
    }
    final me = _userId;
    return ListView.builder(
      reverse: true, // pesan terbaru di bawah
      padding: const EdgeInsets.all(12),
      itemCount: state.messages.length,
      itemBuilder: (context, i) {
        final m = state.messages[state.messages.length - 1 - i];
        final mine = m.userId == me;
        return _Bubble(
          message: m,
          mine: mine,
          myId: me,
          onTap: () => _showActions(context, m, mine),
          onReact: (emoji) => context
              .read<CommunityCubit>()
              .toggleReaction(messageId: m.id, emoji: emoji, userId: me),
        );
      },
    );
  }
}

class _RulesStrip extends StatelessWidget {
  const _RulesStrip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: AppColors.sandBeige,
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: AppColors.forestGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Jaga adab: dilarang hoaks, ujaran kebencian, scam, pornografi, '
                'penistaan agama, dan kata kotor. Ketuk untuk aturan lengkap.',
                style: TextStyle(fontSize: 11.5, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.myId,
    required this.onTap,
    required this.onReact,
  });

  final ChatMessage message;
  final bool mine;
  final String myId;
  final VoidCallback onTap;
  final ValueChanged<String> onReact;

  String get _time =>
      '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final reactions = message.reactions.entries.where((e) => e.value.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.sandBeige,
              backgroundImage:
                  message.avatarAsset == null ? null : AssetImage(message.avatarAsset!),
              child: message.avatarAsset == null
                  ? Text(
                      message.userName.isEmpty ? '?' : message.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      message.userName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: mine ? AppColors.forestGreen : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(mine ? 16 : 4),
                        bottomRight: Radius.circular(mine ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: mine ? Colors.white : AppColors.textDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (final e in reactions)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => onReact(e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: e.value.contains(myId)
                                    ? AppColors.limeGreen.withValues(alpha: 0.5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.sandBeige),
                              ),
                              child: Text(
                                '${e.key} ${e.value.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
                  child: Text(
                    _time,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotePanel extends StatelessWidget {
  const _EmotePanel({required this.emotes, required this.onPick});

  final List<String> emotes;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final e in emotes)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onPick(e),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(e, style: const TextStyle(fontSize: 26)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.showEmotes,
    required this.onToggleEmotes,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool showEmotes;
  final VoidCallback onToggleEmotes;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onToggleEmotes,
                icon: Icon(
                  showEmotes ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                  color: AppColors.forestGreen,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: CommunityPolicy.maxMessageLength,
                  buildCounter: (context,
                          {required currentLength, required isFocused, required maxLength}) =>
                      null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan yang baik...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: sending ? null : onSend,
                style: IconButton.styleFrom(backgroundColor: AppColors.forestGreen),
                icon: sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannedView extends StatelessWidget {
  const _BannedView({required this.status});

  final ModerationStatus status;

  @override
  Widget build(BuildContext context) {
    final until = status.bannedUntil;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block, size: 72, color: AppColors.error),
            const SizedBox(height: 14),
            const Text(
              'Akun Dibanned dari Komunitas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Kamu melanggar aturan Komunitas berulang kali. Fitur Komunitas tidak '
              'dapat dipakai sampai ${until == null ? '-' : Formatter.date(until)} '
              '(${status.daysLeft} hari lagi).',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'Kamu tetap bisa berdonasi dan memakai fitur lainnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  sl<MainTabController>().index.value = MainTabController.donate,
              child: const Text('Berdonasi Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}