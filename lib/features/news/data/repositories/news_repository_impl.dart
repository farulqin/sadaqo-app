import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/news/data/datasources/news_remote_datasource.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';
import 'package:sadaqo/features/news/domain/repositories/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  const NewsRepositoryImpl(this._remote);

  final NewsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<NewsArticle>>> getNews() async {
    try {
      final items = await _remote.getNews();
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
