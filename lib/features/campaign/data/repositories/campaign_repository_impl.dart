import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_remote_datasource.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/domain/repositories/campaign_repository.dart';

class CampaignRepositoryImpl implements CampaignRepository {
  const CampaignRepositoryImpl(this._remote);

  final CampaignRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Campaign>>> getCampaigns() async {
    try {
      final models = await _remote.getCampaigns();
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
