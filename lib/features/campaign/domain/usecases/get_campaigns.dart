import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/core/usecases/usecase.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';
import 'package:sadaqo/features/campaign/domain/repositories/campaign_repository.dart';

class GetCampaigns implements UseCase<List<Campaign>, NoParams> {
  const GetCampaigns(this._repository);

  final CampaignRepository _repository;

  @override
  Future<Either<Failure, List<Campaign>>> call(NoParams params) {
    return _repository.getCampaigns();
  }
}
