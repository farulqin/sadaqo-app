import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Kontrak dasar: satu use case = satu aksi bisnis.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Dipakai jika use case tidak butuh parameter.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
