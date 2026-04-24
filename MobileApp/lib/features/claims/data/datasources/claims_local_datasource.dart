import 'package:hive/hive.dart';
import 'package:claim_ai/features/claims/data/models/claim_model.dart';

abstract class ClaimsLocalDataSource {
  Future<void> cacheClaims(List<ClaimModel> claims);
  Future<List<ClaimModel>> getCachedClaims();
  Future<void> cacheClaim(ClaimModel claim);
  Future<ClaimModel?> getCachedClaim(String id);
  Future<void> clearCache();
}

class ClaimsLocalDataSourceImpl implements ClaimsLocalDataSource {
  static const _boxName = 'claims_cache';

  Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Map>(_boxName);
    }
    return Hive.openBox<Map>(_boxName);
  }

  @override
  Future<void> cacheClaims(List<ClaimModel> claims) async {
    final box = await _openBox();
    await box.clear();
    for (final claim in claims) {
      await box.put(claim.id, claim.toJson());
    }
  }

  @override
  Future<List<ClaimModel>> getCachedClaims() async {
    final box = await _openBox();
    return box.values
        .map((map) => ClaimModel.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }

  @override
  Future<void> cacheClaim(ClaimModel claim) async {
    final box = await _openBox();
    await box.put(claim.id, claim.toJson());
  }

  @override
  Future<ClaimModel?> getCachedClaim(String id) async {
    final box = await _openBox();
    final map = box.get(id);
    if (map == null) return null;
    return ClaimModel.fromJson(Map<String, dynamic>.from(map));
  }

  @override
  Future<void> clearCache() async {
    final box = await _openBox();
    await box.clear();
  }
}
