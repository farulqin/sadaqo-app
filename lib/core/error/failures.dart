import 'package:equatable/equatable.dart';

/// Failure dipakai oleh lapisan DOMAIN dan PRESENTATION.
/// UI cukup menampilkan [message] tanpa tahu sumber error-nya.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal membaca data lokal']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
