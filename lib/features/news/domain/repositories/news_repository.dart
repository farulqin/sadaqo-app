import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';

abstract class NewsRepository {
  Future<Either<Failure, List<NewsArticle>>> getNews();
}
