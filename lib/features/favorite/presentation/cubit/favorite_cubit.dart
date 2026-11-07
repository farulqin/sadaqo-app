import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/favorite/domain/usecases/favorite_usecases.dart';

class FavoriteState extends Equatable {
  const FavoriteState({this.ids = const <String>{}});

  final Set<String> ids;

  bool isFavorite(String id) => ids.contains(id);

  @override
  List<Object?> get props => [ids];
}

class FavoriteCubit extends Cubit<FavoriteState> {
  FavoriteCubit({
    required GetFavoriteIds getIds,
    required ToggleFavorite toggleFavorite,
  })  : _getIds = getIds,
        _toggle = toggleFavorite,
        super(const FavoriteState());

  final GetFavoriteIds _getIds;
  final ToggleFavorite _toggle;

  Future<void> load() async {
    final result = await _getIds(const NoParams());
    result.fold((_) {}, (ids) => emit(FavoriteState(ids: ids)));
  }

  Future<void> toggle(String campaignId) async {
    final result = await _toggle(campaignId);
    result.fold((_) {}, (ids) => emit(FavoriteState(ids: ids)));
  }
}