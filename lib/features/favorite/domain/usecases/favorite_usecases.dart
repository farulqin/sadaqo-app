import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/favorite/domain/repositories/favorite_repository.dart';

class GetFavoriteIds implements UseCase<Set<String>, NoParams> {
  const GetFavoriteIds(this._repository);

  final FavoriteRepository _repository;

  @override
  Future<Either<Failure, Set<String>>> call(NoParams params) => _repository.getIds();
}

/// Parameter: id program.
class ToggleFavorite implements UseCase<Set<String>, String> {
  const ToggleFavorite(this._repository);

  final FavoriteRepository _repository;

  @override
  Future<Either<Failure, Set<String>>> call(String campaignId) =>
      _repository.toggle(campaignId);
}