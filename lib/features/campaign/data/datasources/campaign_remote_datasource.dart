import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

abstract class CampaignRemoteDataSource {
  Future<List<CampaignModel>> getCampaigns();
}
