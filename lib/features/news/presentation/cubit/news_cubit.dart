import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/news/domain/usecases/get_news.dart';
import 'package:sadaqo/features/news/presentation/cubit/news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  NewsCubit(this._getNews) : super(const NewsInitial());

  final GetNews _getNews;

  Future<void> load() async {
    emit(const NewsLoading());
    final result = await _getNews(const NoParams());
    result.fold(
      (failure) => emit(NewsError(failure.message)),
      (articles) => emit(NewsLoaded(articles)),
    );
  }
}
