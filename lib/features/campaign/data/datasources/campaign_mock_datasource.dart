import 'package:sadaqo/features/campaign/data/datasources/campaign_remote_datasource.dart';
import 'package:sadaqo/features/campaign/data/datasources/mock_campaign_store.dart';
import 'package:sadaqo/features/campaign/data/models/campaign_model.dart';

/// Data dummy selama backend belum siap. Isinya ada di MockCampaignStore.
class CampaignMockDataSource implements CampaignRemoteDataSource {
  const CampaignMockDataSource(this._store);

  final MockCampaignStore _store;

  @override
  Future<List<CampaignModel>> getCampaigns() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _store.all;
  }
}