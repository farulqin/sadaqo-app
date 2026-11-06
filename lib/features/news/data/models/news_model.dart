import 'package:sadaqo/core/constants/program_category.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';

class NewsModel extends NewsArticle {
  const NewsModel({
    required super.id,
    required super.title,
    required super.summary,
    required super.content,
    required super.category,
    required super.author,
    required super.publishedAt,
    super.campaignId,
    super.imageAsset,
  });

  /// Nama key JSON mengikuti respons API Laravel (GET /api/news).
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      category: ProgramCategory.fromKey(json['category'] as String),
      author: json['author'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      campaignId: json['campaign_id']?.toString(),
      imageAsset: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'content': content,
        'category': category.key,
        'author': author,
        'published_at': publishedAt.toIso8601String(),
        'campaign_id': campaignId,
        'image': imageAsset,
      };
}
