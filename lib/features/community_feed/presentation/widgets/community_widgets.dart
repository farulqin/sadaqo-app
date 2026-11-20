// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/network/api_config.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/pages/post_detail_page.dart';

const Color _likeColor = Color(0xFFD64545);

void showCommunitySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmCommunity(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok == true;
}

/// Memastikan pengguna sudah bergabung; menawarkan "Gabung" bila belum.
Future<bool> ensureJoined(BuildContext context) async {
  final cubit = context.read<CommunityFeedCubit>();
  if (cubit.state.overview?.joined ?? false) return true;
  final ok = await confirmCommunity(
    context,
    title: 'Gabung dulu ke Komunitas',
    message: 'Untuk menulis, memberi apresiasi, berkomentar, atau ikut polling, bergabunglah dulu ke Komunitas SADAQO.',
    confirmLabel: 'Gabung',
  );
  if (!ok) return false;
  final err = await cubit.join();
  if (err != null && context.mounted) {
    showCommunitySnack(context, err);
    return false;
  }
  return true;
}

const List<String> _reportReasons = [
  'Hoaks atau informasi menyesatkan',
  'Ujaran kebencian atau penistaan',
  'Penipuan atau scam',
  'Konten dewasa',
  'Kata-kata kasar',
  'Lainnya',
];

Future<String?> pickReportReason(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Laporkan karena...'),
      children: [
        for (final r in _reportReasons)
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, r), child: Text(r)),
      ],
    ),
  );
}

/// Gambar dari aset bawaan atau URL server.
class RemoteImage extends StatelessWidget {
  const RemoteImage(
    this.src, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String? src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  Widget _fallback() =>
      fallback ??
      Container(
        width: width,
        height: height,
        color: AppColors.sandBeige,
        child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
      );

  @override
  Widget build(BuildContext context) {
    final s = src;
    if (s == null || s.isEmpty) return _fallback();
    if (s.startsWith('http')) {
      return Image.network(
        ApiConfig.resolveMediaUrl(s),
        width: width,
        height: height,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (context, e, st) => _fallback(),
      );
    }
    return Image.asset(
      s,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, e, st) => _fallback(),
    );
  }
}

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar(this.author, {super.key, this.radius = 20});

  final CommunityAuthor author;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final d = radius * 2;
    return ClipOval(
      child: SizedBox(
        width: d,
        height: d,
        child: RemoteImage(
          author.avatar,
          width: d,
          height: d,
          fallback: Container(
            color: AppColors.sandBeige,
            alignment: Alignment.center,
            child: Text(
              author.initial,
              style: TextStyle(
                fontSize: radius * 0.85,
                fontWeight: FontWeight.w800,
                color: AppColors.brandInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikon badge kebaikan di samping nama (tekan lama untuk melihat artinya).
class BadgeStrip extends StatelessWidget {
  const BadgeStrip(this.badges, {super.key, this.max = 3});

  final List<CommunityBadge> badges;
  final int max;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final b in badges.take(max))
          Tooltip(
            message: '${b.label}: ${b.description}',
            child: Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(b.icon, style: const TextStyle(fontSize: 13)),
            ),
          ),
      ],
    );
  }
}

/// Nama penulis + pil peran + badge. Dipakai di post dan komentar.
class AuthorName extends StatelessWidget {
  const AuthorName(this.author, {super.key});

  final CommunityAuthor author;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            author.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        if (author.isStaff) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              author.roleLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brandInk,
              ),
            ),
          ),
        ],
        BadgeStrip(author.badges),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }
}

/// Kartu post. [onOpen] kosong di halaman detail.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.onOpen, this.compact = true});

  final CommunityPost post;
  final VoidCallback? onOpen;
  final bool compact;

  Future<void> _like(BuildContext context) async {
    if (!await ensureJoined(context)) return;
    if (!context.mounted) return;
    final err = await context.read<CommunityFeedCubit>().toggleLike(post);
    if (err != null && context.mounted) showCommunitySnack(context, err);
  }

  Future<void> _share(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: '${post.author.name} di Komunitas SADAQO:\n\n${post.body}'),
    );
    if (context.mounted) showCommunitySnack(context, 'Teks post disalin. Tempel untuk membagikannya.');
  }

  Future<void> _onMenu(BuildContext context, String action) async {
    final cubit = context.read<CommunityFeedCubit>();
    switch (action) {
      case 'share':
        await _share(context);
      case 'report':
        final reason = await pickReportReason(context);
        if (reason == null || !context.mounted) return;
        final err = await cubit.reportPost(post, reason);
        if (context.mounted) {
          showCommunitySnack(context, err ?? 'Terima kasih, laporanmu akan ditinjau admin.');
        }
      case 'delete':
        final ok = await confirmCommunity(
          context,
          title: 'Hapus post?',
          message: 'Post beserta komentarnya akan dihapus permanen.',
          confirmLabel: 'Hapus',
        );
        if (!ok || !context.mounted) return;
        final err = await cubit.deletePost(post);
        if (context.mounted) {
          if (err != null) {
            showCommunitySnack(context, err);
          } else if (onOpen == null) {
            Navigator.of(context).pop(); // dari halaman detail
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = post.isPinned
        ? (Icons.push_pin_rounded, 'Disematkan admin')
        : (post.category == 'info' ? (Icons.campaign_rounded, 'Pengumuman') : null);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBeige),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(label.$1, size: 14, color: AppColors.brandInk),
                      const SizedBox(width: 4),
                      Text(
                        label.$2,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandInk,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  CommunityAvatar(post.author),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthorName(post.author),
                        Text(
                          timeAgo(post.createdAt),
                          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: AppColors.textMuted),
                    onSelected: (v) => _onMenu(context, v),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'share', child: Text('Bagikan')),
                      const PopupMenuItem(value: 'report', child: Text('Laporkan')),
                      if (post.canDelete)
                        const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Text(
                  post.body,
                  maxLines: compact ? 8 : null,
                  overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
                  style: const TextStyle(fontSize: 14.5, height: 1.45),
                ),
              ),
              if (post.image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RemoteImage(post.image, width: double.infinity, height: 200),
                  ),
                ),
              if (post.poll != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10, right: 8),
                  child: PollCard(post: post),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _ActionButton(
                    icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: '${post.likeCount}',
                    color: post.liked ? _likeColor : null,
                    onTap: () => _like(context),
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.commentCount}',
                    onTap: onOpen,
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Bagikan',
                    onTap: () => _share(context),
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

/// Polling: pilih satu opsi, lalu hasil tampil sebagai batang persentase.
class PollCard extends StatelessWidget {
  const PollCard({super.key, required this.post});

  final CommunityPost post;

  Future<void> _vote(BuildContext context, int optionId) async {
    if (!await ensureJoined(context)) return;
    if (!context.mounted) return;
    final err = await context.read<CommunityFeedCubit>().vote(post, optionId);
    if (err != null && context.mounted) showCommunitySnack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final poll = post.poll!;
    final results = poll.showResults;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBeige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll_rounded, size: 18, color: AppColors.brandInk),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: poll.isClosed ? AppColors.sandBeige : AppColors.successSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  poll.isClosed ? 'Selesai' : 'Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandInk,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                poll.statusLabel,
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            poll.question,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 10),
          for (final o in poll.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: results
                  ? _ResultBar(option: o, mine: poll.myVote == o.id)
                  : OutlinedButton(
                      onPressed: () => _vote(context, o.id),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        alignment: Alignment.centerLeft,
                        foregroundColor: AppColors.brandInk,
                        side: BorderSide(color: AppColors.brandInk.withValues(alpha: 0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(o.label),
                    ),
            ),
          Text(
            '${poll.totalVotes} suara',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.option, required this.mine});

  final PollOption option;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (mine) ...[
              Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontWeight: mine ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            Text(
              '${option.percent}%',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: option.percent / 100,
            minHeight: 8,
            backgroundColor: AppColors.sandBeige.withValues(alpha: 0.6),
            color: mine ? AppColors.brandInk : AppColors.limeGreen,
          ),
        ),
        Text(
          '${option.votes} suara',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// Membuka halaman detail post.
void openPostDetail(BuildContext context, CommunityPost post) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => PostDetailPage(postId: post.id)),
  );
}