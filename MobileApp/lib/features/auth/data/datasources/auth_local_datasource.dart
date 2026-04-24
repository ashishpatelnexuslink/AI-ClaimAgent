import 'dart:convert';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorage _localStorage;
  static const _userCacheKey = 'cached_user';

  AuthLocalDataSourceImpl({required LocalStorage localStorage})
      : _localStorage = localStorage;

  @override
  Future<void> cacheUser(UserModel user) async {
    await _localStorage.setString(
      _userCacheKey,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonStr = _localStorage.getString(_userCacheKey);
    if (jsonStr == null) return null;
    return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  @override
  Future<void> clearCache() async {
    await _localStorage.remove(_userCacheKey);
  }
}
