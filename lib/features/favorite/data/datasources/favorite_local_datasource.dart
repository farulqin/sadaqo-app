abstract class FavoriteLocalDataSource {
  Future<Set<String>> getIds();
  Future<Set<String>> toggle(String campaignId);
}

/// Penyimpanan di memori selama backend belum siap (hilang saat aplikasi ditutup).
class FavoriteMemoryDataSource implements FavoriteLocalDataSource {
  final Set<String> _ids = <String>{};

  @override
  Future<Set<String>> getIds() async => Set<String>.of(_ids);

  @override
  Future<Set<String>> toggle(String campaignId) async {
    if (!_ids.remove(campaignId)) _ids.add(campaignId);
    return Set<String>.of(_ids);
  }
}