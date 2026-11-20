// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/widgets/state_views.dart';
import 'package:sadaqo/features/community_feed/data/community_feed_api.dart';
import 'package:sadaqo/features/community_feed/domain/community_models.dart';
import 'package:sadaqo/features/community_feed/presentation/cubit/community_feed_cubit.dart';
import 'package:sadaqo/features/community_feed/presentation/widgets/community_widgets.dart';
import 'package:sadaqo/injection_container.dart';

/// Detail post: isi lengkap, komentar bersarang, dan kolom balasan.
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _api = sl<CommunityFeedApi>();
  final _input = TextEditingController();

  List<CommunityComment> _comments = const [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  CommunityComment? _replyTo;
  String? _postError;

  @override
  void initState() {
    super.initState();
    _load();
    _ensure();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.comments(widget.postId);
      if (!mounted) return;
      setState(() {
        _comments = list;
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

  Future<void> _ensure() async {
    final err = await context.read<CommunityFeedCubit>().ensurePost(widget.postId);
    if (mounted && err != null) setState(() => _postError = err);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (!await ensureJoined(context)) return;
    if (!mounted) return;
    setState(() => _sending = true);
    try {
      final c = await _api.addComment(widget.postId, text, parentId: _replyTo?.id);
      if (!mounted) return;
      final parentId = c.parentId;
      setState(() {
        if (parentId == null) {
          _comments = [..._comments, c];
        } else {
          _comments = [
            for (final x in _comments)
              x.id == parentId ? x.copyWith(replies: [...x.replies, c]) : x,
          ];
        }
        _input.clear();
        _replyTo = null;
        _sending = false;
      });
      context.read<CommunityFeedCubit>().adjustCommentCount(widget.postId, 1);
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showCommunitySnack(context, e.message);
    }
  }

  Future<void> _delete(CommunityComment c) async {
    final ok = await confirmCommunity(
      context,
      title: 'Hapus komentar?',
      message: c.replies.isEmpty ? 'Komentar ini akan dihapus.' : 'Komentar beserta balasannya akan dihapus.',
      confirmLabel: 'Hapus',
    );
    if (!ok || !mounted) return;
    try {
      await _api.deleteComment(c.id);
    } on ServerException catch (e) {
      if (mounted) showCommunitySnack(context, e.message);
      return;
    }
    if (!mounted) return;
    var removed = 1 + c.replies.length;
    setState(() {
      if (c.parentId == null) {
        _comments = [for (final x in _comments) if (x.id != c.id) x];
      } else {
        removed = 1;
        _comments = [
          for (final x in _comments)
            x.id == c.parentId
                ? x.copyWith(replies: [for (final r in x.replies) if (r.id != c.id) r])
                : x,
        ];
      }
    });
    context.read<CommunityFeedCubit>().adjustCommentCount(widget.postId, -removed);
  }

  Future<void> _report(CommunityComment c) async {
    final reason = await pickReportReason(context);
    if (reason == null || !mounted) return;
    try {
      await _api.reportComment(c.id, reason);
      if (mounted) showCommunitySnack(context, 'Terima kasih, laporanmu akan ditinjau admin.');
    } on ServerException catch (e) {
      if (mounted) showCommunitySnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = context.select<CommunityFeedCubit, CommunityPost?>(
      (c) => c.state.postById(widget.postId),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        title: Text(post?.category == 'info' ? 'Pengumuman' : 'Diskusi'),
      ),
      body: post == null
          ? Center(
              child: _postError == null
                  ? const CircularProgressIndicator()
                  : Text(_postError!, textAlign: TextAlign.center),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      PostCard(post: post, compact: false),
                      const SizedBox(height: 16),
                      Text(
                        'Komentar (${post.commentCount})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (_loading)
                        const Padding(padding: EdgeInsets.all(24), child: LoadingView())
                      else if (_error != null)
                        ErrorView(message: _error!, onRetry: _load)
                      else if (_comments.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Belum ada komentar. Jadilah yang pertama!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        for (final c in _comments) ...[
                          _CommentTile(
                            comment: c,
                            isReply: false,
                            onReply: () => setState(() => _replyTo = c),
                            onDelete: () => _delete(c),
                            onReport: () => _report(c),
                          ),
                          for (final r in c.replies)
                            _CommentTile(
                              comment: r,
                              isReply: true,
                              onReply: () => setState(() => _replyTo = c),
                              onDelete: () => _delete(r),
                              onReport: () => _report(r),
                            ),
                        ],
                    ],
                  ),
                ),
                _inputBar(),
              ],
            ),
    );
  }

  Widget _inputBar() {
    return Material(
      elevation: 8,
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            8,
            8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Membalas ${_replyTo!.author.name}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _replyTo = null),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: _replyTo == null ? 'Tulis komentar...' : 'Tulis balasan...',
                        counterText: '',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: Icon(
                      Icons.send_rounded,
                      color: _sending ? AppColors.textMuted : AppColors.brandInk,
                    ),
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isReply,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
  });

  final CommunityComment comment;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommunityAvatar(comment.author, radius: isReply ? 14 : 17),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sandBeige),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: AuthorName(comment.author)),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                        onSelected: (v) => v == 'delete' ? onDelete() : onReport(),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'report', child: Text('Laporkan')),
                          if (comment.canDelete)
                            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(comment.body, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ),
                  Row(
                    children: [
                      Text(
                        timeAgo(comment.createdAt),
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: onReply,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('Balas', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
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