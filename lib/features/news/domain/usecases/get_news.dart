import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';
import 'package:sadaqo/features/news/domain/repositories/news_repository.dart';

class GetNews implements UseCase<List<NewsArticle>, NoParams> {
  const GetNews(this._repository);

  final NewsRepository _repository;

  /// Jumlah berita yang ditampilkan di carousel beranda.
  static const int homeLimit = 5;

  @override
  Future<Either<Failure, List<NewsArticle>>> call(NoParams params) async {
    final result = await _repository.getNews();
    return result.map((items) {
      // Terbaru dulu, ambil 5 saja.
      final sorted = List<NewsArticle>.of(items)
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return sorted.take(homeLimit).toList();
    });
  }
}
