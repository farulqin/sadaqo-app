/// Exception dilempar oleh lapisan DATA (datasource).
/// Nanti diubah menjadi Failure oleh repository.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Terjadi kesalahan pada server']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Gagal membaca data lokal']);
}
