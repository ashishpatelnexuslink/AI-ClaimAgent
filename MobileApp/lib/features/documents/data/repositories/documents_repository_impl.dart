import 'package:dartz/dartz.dart';
import 'package:claim_ai/core/error/exceptions.dart';
import 'package:claim_ai/core/error/failures.dart';
import 'package:claim_ai/core/network/network_info.dart';
import 'package:claim_ai/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:claim_ai/features/documents/domain/entities/document_entity.dart';
import 'package:claim_ai/features/documents/domain/repositories/documents_repository.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  final DocumentsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DocumentsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<DocumentEntity>>> getDocuments(
      String claimId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final docs = await remoteDataSource.getDocuments(claimId);
      return Right(docs);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> uploadDocument({
    required String claimId,
    required String filePath,
    required String fileName,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final doc = await remoteDataSource.uploadDocument(
        claimId: claimId,
        filePath: filePath,
        fileName: fileName,
      );
      return Right(doc);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDocument(String documentId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.deleteDocument(documentId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, DocumentEntity>> finalizeDocument(
      String documentId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final doc = await remoteDataSource.finalizeDocument(documentId);
      return Right(doc);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<DocumentTemplate>>> getTemplates() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final templates = await remoteDataSource.getTemplates();
      return Right(templates);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
