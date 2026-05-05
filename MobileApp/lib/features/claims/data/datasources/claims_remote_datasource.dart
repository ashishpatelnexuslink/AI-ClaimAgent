import 'package:dio/dio.dart';
import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/features/claims/data/models/claim_model.dart';
import 'package:claim_ai/features/claims/data/models/claim_summary_model.dart';

abstract class ClaimsRemoteDataSource {
  Future<List<ClaimModel>> getClaims({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  });
  Future<ClaimModel> getClaimById(String id);
  Future<ClaimSummaryModel> getClaimSummary(String id);
  Future<ClaimModel> updateClaimStatus({
    required String id,
    required String status,
  });

  /// Updates incident date / location / description on a Pending claim. The
  /// backend rejects the update when the claim has progressed past Pending.
  Future<ClaimModel> updateAccidentInfo({
    required String id,
    DateTime? incidentDate,
    String? incidentLocation,
    String? incidentDescription,
  });
  Future<ClaimSummaryModel> getDashboardSummary();
  Future<Map<String, dynamic>> createClaim(Map<String, dynamic> claimData);
  Future<Map<String, dynamic>> createClaimFromChat(Map<String, dynamic> claimData);

  /// Uploads a single file to `/mobile/claim-documents` and returns the row
  /// that was created (including its `id`). [claimId] is always null on
  /// upload — we attach later via [attachClaimDocuments]. [groupKey] / [label]
  /// come from the active template's PhotoSetting / DocumentSetting and get
  /// stored verbatim on the resulting `ClaimDocument` row.
  Future<Map<String, dynamic>> uploadClaimDocument({
    required List<int> bytes,
    required String fileName,
    required String kind,
    String? groupKey,
    String? label,
    String? chatThreadId,
    String? angle,
  });

  /// Associates a list of previously-uploaded document ids with a claim
  /// that was just created.
  Future<Map<String, dynamic>> attachClaimDocuments({
    required String claimId,
    required List<String> documentIds,
  });

  /// Fetches every document attached to a claim.
  Future<List<Map<String, dynamic>>> getDocumentsByClaim(String claimId);

  /// Deletes a single uploaded document.
  Future<void> deleteClaimDocument(String documentId);

  /// Deletes every unattached document the current user uploaded for the
  /// given chat thread, optionally narrowed by groupKey. Returns the ids of
  /// the rows that were actually deleted so the caller can prune local state.
  Future<List<String>> deleteClaimDocumentsByThread({
    required String threadId,
    String? groupKey,
  });
}

class ClaimsRemoteDataSourceImpl implements ClaimsRemoteDataSource {
  final DioClient _client;

  ClaimsRemoteDataSourceImpl({required DioClient client}) : _client = client;

  @override
  Future<List<ClaimModel>> getClaims({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    final response = await _client.get(
      ApiConstants.claims,
      queryParameters: {
        'page': page,
        'limit': limit,
        'status': ?status,
        'search': ?search,
      },
    );
    final list = response.data['data'] as List;
    return list
        .map((json) => ClaimModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClaimModel> getClaimById(String id) async {
    final response = await _client.get(
      ApiConstants.claimById.replaceFirst('{id}', id),
    );
    return ClaimModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ClaimSummaryModel> getClaimSummary(String id) async {
    final response = await _client.get(
      ApiConstants.claimSummary.replaceFirst('{id}', id),
    );
    return ClaimSummaryModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ClaimModel> updateClaimStatus({
    required String id,
    required String status,
  }) async {
    final response = await _client.put(
      ApiConstants.claimStatus.replaceFirst('{id}', id),
      data: {'status': status},
    );
    return ClaimModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ClaimModel> updateAccidentInfo({
    required String id,
    DateTime? incidentDate,
    String? incidentLocation,
    String? incidentDescription,
  }) async {
    final response = await _client.put(
      ApiConstants.updateClaimAccidentInfo.replaceFirst('{id}', id),
      data: {
        'incidentDate': incidentDate?.toUtc().toIso8601String(),
        'incidentLocation': incidentLocation,
        'incidentDescription': incidentDescription,
      },
    );
    return ClaimModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<ClaimSummaryModel> getDashboardSummary() async {
    final response = await _client.get('${ApiConstants.claims}/summary');
    return ClaimSummaryModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> createClaim(Map<String, dynamic> claimData) async {
    final response = await _client.post(
      ApiConstants.createClaim,
      data: claimData,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createClaimFromChat(
      Map<String, dynamic> claimData) async {
    final response = await _client.post(
      ApiConstants.createClaimFromChat,
      data: claimData,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> uploadClaimDocument({
    required List<int> bytes,
    required String fileName,
    required String kind,
    String? groupKey,
    String? label,
    String? chatThreadId,
    String? angle,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      'kind': kind,
      'groupKey': ?groupKey,
      'label': ?label,
      'chatThreadId': ?chatThreadId,
      'angle': ?angle,
    });
    final response = await _client.uploadFile(
      ApiConstants.uploadClaimDocument,
      data: formData,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> attachClaimDocuments({
    required String claimId,
    required List<String> documentIds,
  }) async {
    final response = await _client.post(
      ApiConstants.attachClaimDocuments,
      data: {
        'claimId': claimId,
        'documentIds': documentIds,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<Map<String, dynamic>>> getDocumentsByClaim(String claimId) async {
    final response = await _client.get(
      ApiConstants.claimDocumentsByClaim.replaceFirst('{claimId}', claimId),
    );
    final list = response.data['data'] as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<void> deleteClaimDocument(String documentId) async {
    await _client.delete(
      ApiConstants.deleteClaimDocument.replaceFirst('{id}', documentId),
    );
  }

  @override
  Future<List<String>> deleteClaimDocumentsByThread({
    required String threadId,
    String? groupKey,
  }) async {
    final response = await _client.delete(
      ApiConstants.deleteClaimDocumentsByThread
          .replaceFirst('{threadId}', threadId),
      queryParameters: {
        if (groupKey != null && groupKey.isNotEmpty) 'groupKey': groupKey,
      },
    );
    final data = response.data['data'];
    if (data is Map && data['deletedIds'] is List) {
      return (data['deletedIds'] as List).map((e) => e.toString()).toList();
    }
    return const <String>[];
  }
}
