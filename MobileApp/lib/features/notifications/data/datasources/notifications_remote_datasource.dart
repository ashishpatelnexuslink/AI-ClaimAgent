import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/features/notifications/data/models/pending_action_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<PendingActionModel>> getPendingActions();
  Future<void> markAsRead(String notificationId);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final DioClient _client;

  NotificationsRemoteDataSourceImpl({required DioClient client})
    : _client = client;

  @override
  Future<List<PendingActionModel>> getPendingActions() async {
    final response = await _client.get(ApiConstants.pendingActions);
    final list = response.data['data'] as List;
    return list
        .map(
          (json) => PendingActionModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client.put(
      ApiConstants.notificationRead.replaceFirst('{id}', notificationId),
    );
  }
}
