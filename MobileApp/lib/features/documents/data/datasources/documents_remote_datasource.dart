import 'package:dio/dio.dart';
import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/features/documents/data/models/document_model.dart';

abstract class DocumentsRemoteDataSource {
  Future<List<DocumentModel>> getDocuments(String claimId);
  Future<DocumentModel> uploadDocument({
    required String claimId,
    required String filePath,
    required String fileName,
  });
  Future<void> deleteDocument(String documentId);
  Future<DocumentModel> finalizeDocument(String documentId);
  Future<List<DocumentTemplateModel>> getTemplates();
}

class DocumentsRemoteDataSourceImpl implements DocumentsRemoteDataSource {
  final DioClient _client;

  DocumentsRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<List<DocumentModel>> getDocuments(String claimId) async {
    final response = await _client.get(
      ApiConstants.documents,
      queryParameters: {'claimId': claimId},
    );
    final list = response.data['data'] as List;
    return list
        .map((json) => DocumentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DocumentModel> uploadDocument({
    required String claimId,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'claimId': claimId,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _client.uploadFile(
      ApiConstants.documentUpload,
      data: formData,
    );
    return DocumentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _client.delete(
      ApiConstants.documentDelete.replaceFirst('{id}', documentId),
    );
  }

  @override
  Future<DocumentModel> finalizeDocument(String documentId) async {
    final response = await _client.post(
      ApiConstants.documentFinalize.replaceFirst('{id}', documentId),
    );
    return DocumentModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<DocumentTemplateModel>> getTemplates() async {
    final response = await _client.get(ApiConstants.documentTemplates);
    final list = response.data['data'] as List;
    return list
        .map((json) =>
            DocumentTemplateModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
