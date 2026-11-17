import 'package:sadaqo/core/utils/formatter.dart';

DateTime _dt(dynamic v) =>
    (v is String ? DateTime.tryParse(v) : null)?.toLocal() ?? DateTime.now();

/// "baru saja", "5 menit lalu", "2 jam lalu", "3 hari lalu", atau tanggal.
String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return Formatter.date(time);
}

class CommunityBadge {
  const CommunityBadge({
    required this.key,
    required this.label,
    required this.icon,
    required this.description,
    this.earned = true,
  });

  final String key;
  final String label;
  final String icon;
  final String description;
  final bool earned;

  factory CommunityBadge.fromJson(Map<String, dynamic> j) => CommunityBadge(
        key: '${j['key']}',
        label: (j['label'] ?? '') as String,
        icon: (j['icon'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        earned: j['earned'] != false,
      );
}

List<CommunityBadge> _badges(dynamic v) => [
      if (v is List)
        for (final b in v)
          if (b is Map<String, dynamic>) CommunityBadge.fromJson(b),
    ];

class CommunityAuthor {
  const CommunityAuthor({
    required this.id,
    required this.name,
    required this.handle,
    required this.role,
    this.avatar,
    this.badges = const [],
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String handle;
  final String role;
  final String? avatar;
  final List<CommunityBadge> badges;
  final bool isOnline;

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'admin' || role == 'pengelola';
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
  String get roleLabel => switch (role) {
        'admin' => 'Admin',
        'pengelola' => 'Pengelola',
        _ => 'Anggota',
      };

  factory CommunityAuthor.fromJson(Map<String, dynamic> j) => CommunityAuthor(
        id: '${j['id']}',
        name: (j['name'] ?? '') as String,
        handle: (j['handle'] ?? '') as String,
        role: (j['role'] ?? 'donatur') as String,
        avatar: j['avatar'] as String?,
        badges: _badges(j['badges']),
        isOnline: j['is_online'] == true,
      );
}

class PollOption {
  const PollOption({
    required this.id,
    required this.label,
    required this.votes,
    required this.percent,
  });

  final int id;
  final String label;
  final int votes;
  final int percent;

  factory PollOption.fromJson(Map<String, dynamic> j) => PollOption(
        id: (j['id'] as num).toInt(),
        label: (j['label'] ?? '') as String,
        votes: (j['votes'] as num?)?.toInt() ?? 0,
        percent: (j['percent'] as num?)?.toInt() ?? 0,
      );
}

class CommunityPoll {
  const CommunityPoll({
    required this.id,
    required this.question,
    required this.endsAt,
    required this.isClosed,
    required this.totalVotes,
    required this.options,
    this.myVote,
  });

  final int id;
  final String question;
  final DateTime endsAt;
  final bool isClosed;
  final int totalVotes;
  final int? myVote;
  final List<PollOption> options;

  bool get showResults => myVote != null || isClosed;

  String get statusLabel {
    if (isClosed) return 'Polling selesai';
    final d = endsAt.difference(DateTime.now());
    if (d.inDays >= 1) return '${d.inDays} hari lagi';
    if (d.inHours >= 1) return '${d.inHours} jam lagi';
    return '${d.inMinutes < 1 ? 1 : d.inMinutes} menit lagi';
  }

  factory CommunityPoll.fromJson(Map<String, dynamic> j) => CommunityPoll(
        id: (j['id'] as num).toInt(),
        question: (j['question'] ?? '') as String,
        endsAt: _dt(j['ends_at']),
        isClosed: j['is_closed'] == true,
        totalVotes: (j['total_votes'] as num?)?.toInt() ?? 0,
        myVote: (j['my_vote'] as num?)?.toInt(),
        options: [
          if (j['options'] is List)
            for (final o in j['options'] as List)
              if (o is Map<String, dynamic>) PollOption.fromJson(o),
        ],
      );
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.category,
    required this.body,
    required this.createdAt,
    required this.author,
    this.image,
    this.isPinned = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.liked = false,
    this.poll,
    this.canDelete = false,
  });

  final String id;
  final String category; // diskusi | info
  final String body;
  final String? image;
  final bool isPinned;
  final DateTime createdAt;
  final CommunityAuthor author;
  final int likeCount;
  final int commentCount;
  final bool liked;
  final CommunityPoll? poll;
  final bool canDelete;

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? liked,
    CommunityPoll? poll,
  }) =>
      CommunityPost(
        id: id,
        category: category,
        body: body,
        image: image,
        isPinned: isPinned,
        createdAt: createdAt,
        author: author,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        liked: liked ?? this.liked,
        poll: poll ?? this.poll,
        canDelete: canDelete,
      );

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id: '${j['id']}',
        category: (j['category'] ?? 'diskusi') as String,
        body: (j['body'] ?? '') as String,
        image: j['image'] as String?,
        isPinned: j['is_pinned'] == true,
        createdAt: _dt(j['created_at']),
        author: CommunityAuthor.fromJson(j['author'] as Map<String, dynamic>),
        likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
        commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
        liked: j['liked'] == true,
        poll: j['poll'] is Map<String, dynamic>
            ? CommunityPoll.fromJson(j['poll'] as Map<String, dynamic>)
            : null,
        canDelete: j['can_delete'] == true,
      );
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.postId,
    required this.body,
    required this.createdAt,
    required this.author,
    this.parentId,
    this.canDelete = false,
    this.replies = const [],
  });

  final String id;
  final String postId;
  final String? parentId;
  final String body;
  final DateTime createdAt;
  final CommunityAuthor author;
  final bool canDelete;
  final List<CommunityComment> replies;

  CommunityComment copyWith({List<CommunityComment>? replies}) => CommunityComment(
        id: id,
        postId: postId,
        parentId: parentId,
        body: body,
        createdAt: createdAt,
        author: author,
        canDelete: canDelete,
        replies: replies ?? this.replies,
      );

  factory CommunityComment.fromJson(Map<String, dynamic> j) => CommunityComment(
        id: '${j['id']}',
        postId: '${j['post_id']}',
        parentId: j['parent_id'] == null ? null : '${j['parent_id']}',
        body: (j['body'] ?? '') as String,
        createdAt: _dt(j['created_at']),
        author: CommunityAuthor.fromJson(j['author'] as Map<String, dynamic>),
        canDelete: j['can_delete'] == true,
        replies: [
          if (j['replies'] is List)
            for (final r in j['replies'] as List)
              if (r is Map<String, dynamic>) CommunityComment.fromJson(r),
        ],
      );
}

class CommunityOverview {
  const CommunityOverview({
    required this.memberCount,
    required this.onlineCount,
    required this.joined,
    required this.activePolls,
    this.myBadges = const [],
    this.catalog = const [],
    this.posts = 0,
    this.comments = 0,
    this.appreciations = 0,
  });

  final int memberCount;
  final int onlineCount;
  final bool joined;
  final int activePolls;
  final List<CommunityBadge> myBadges;
  final List<CommunityBadge> catalog;
  final int posts;
  final int comments;
  final int appreciations;

  factory CommunityOverview.fromJson(Map<String, dynamic> j) {
    final stats = j['my_stats'] is Map<String, dynamic>
        ? j['my_stats'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return CommunityOverview(
      memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
      onlineCount: (j['online_count'] as num?)?.toInt() ?? 0,
      joined: j['joined'] == true,
      activePolls: (j['active_polls'] as num?)?.toInt() ?? 0,
      myBadges: _badges(j['my_badges']),
      catalog: _badges(j['badge_catalog']),
      posts: (stats['posts'] as num?)?.toInt() ?? 0,
      comments: (stats['comments'] as num?)?.toInt() ?? 0,
      appreciations: (stats['appreciations'] as num?)?.toInt() ?? 0,
    );
  }
}

class PostPage {
  const PostPage({required this.items, required this.page, required this.lastPage});

  final List<CommunityPost> items;
  final int page;
  final int lastPage;
}

class CommunityEvent {
  const CommunityEvent({
    required this.id,
    required this.title,
    required this.location,
    required this.startsAt,
    this.description,
    this.isOnline = false,
    this.endsAt,
    this.image,
    this.interestedCount = 0,
    this.interested = false,
    this.creator,
    this.canManage = false,
  });

  final String id;
  final String title;
  final String? description;
  final String location;
  final bool isOnline;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? image;
  final int interestedCount;
  final bool interested;
  final String? creator;
  final bool canManage;

  /// Sudah lewat bila kegiatan berakhir (atau 3 jam setelah mulai bila tak ada jam selesai).
  bool get isPast =>
      (endsAt ?? startsAt.add(const Duration(hours: 3))).isBefore(DateTime.now());

  CommunityEvent copyWith({bool? interested, int? interestedCount}) => CommunityEvent(
        id: id,
        title: title,
        description: description,
        location: location,
        isOnline: isOnline,
        startsAt: startsAt,
        endsAt: endsAt,
        image: image,
        interestedCount: interestedCount ?? this.interestedCount,
        interested: interested ?? this.interested,
        creator: creator,
        canManage: canManage,
      );

  factory CommunityEvent.fromJson(Map<String, dynamic> j) => CommunityEvent(
        id: '${j['id']}',
        title: (j['title'] ?? '') as String,
        description: j['description'] as String?,
        location: (j['location'] ?? '') as String,
        isOnline: j['is_online'] == true,
        startsAt: _dt(j['starts_at']),
        endsAt: j['ends_at'] is String ? _dt(j['ends_at']) : null,
        image: j['image'] as String?,
        interestedCount: (j['interested_count'] as num?)?.toInt() ?? 0,
        interested: j['interested'] == true,
        creator: j['creator'] as String?,
        canManage: j['can_manage'] == true,
      );
}