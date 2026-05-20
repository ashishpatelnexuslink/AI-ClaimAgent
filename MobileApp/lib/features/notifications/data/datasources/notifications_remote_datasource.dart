import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/features/notifications/data/models/pending_action_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<PendingActionModel>> getPendingActions();
  Future<void> markAsRead(String notificationId);
  Future<void> registerDevice({required String fcmToken, required String platform});
  Future<void> unregisterDevice(String fcmToken);
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

  @override
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    await _client.post(
      ApiConstants.registerDevice,
      data: {'fcmToken': fcmToken, 'platform': platform},
    );
  }

  @override
  Future<void> unregisterDevice(String fcmToken) async {
    await _client.delete(
      ApiConstants.unregisterDevice.replaceFirst('{token}', fcmToken),
    );
  }
}
