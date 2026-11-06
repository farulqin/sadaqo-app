import 'package:dartz/dartz.dart';
import 'package:sadaqo/core/error/failures.dart';
import 'package:sadaqo/features/campaign/domain/entities/campaign.dart';

abstract class CampaignRepository {
  Future<Either<Failure, List<Campaign>>> getCampaigns();
}
