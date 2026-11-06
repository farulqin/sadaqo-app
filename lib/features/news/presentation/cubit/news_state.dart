import 'package:equatable/equatable.dart';
import 'package:sadaqo/features/news/domain/entities/news_article.dart';

abstract class NewsState extends Equatable {
  const NewsState();

  @override
  List<Object?> get props => [];
}

class NewsInitial extends NewsState {
  const NewsInitial();
}

class NewsLoading extends NewsState {
  const NewsLoading();
}

class NewsLoaded extends NewsState {
  const NewsLoaded(this.articles);

  final List<NewsArticle> articles;

  @override
  List<Object?> get props => [articles];
}

class NewsError extends NewsState {
  const NewsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
