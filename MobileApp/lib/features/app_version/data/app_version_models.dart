class VersionCheckResult {
  final bool updateRequired;
  final bool updateAvailable;
  final bool isMandatory;
  final String latestVersionName;
  final int latestVersionCode;
  final int minSupportedVersionCode;
  final String? storeUrl;
  final String? releaseNotes;

  const VersionCheckResult({
    required this.updateRequired,
    required this.updateAvailable,
    required this.isMandatory,
    required this.latestVersionName,
    required this.latestVersionCode,
    required this.minSupportedVersionCode,
    this.storeUrl,
    this.releaseNotes,
  });

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) {
    return VersionCheckResult(
      updateRequired: json['updateRequired'] as bool? ?? false,
      updateAvailable: json['updateAvailable'] as bool? ?? false,
      isMandatory: json['isMandatory'] as bool? ?? false,
      latestVersionName: json['latestVersionName']?.toString() ?? '',
      latestVersionCode: (json['latestVersionCode'] as num?)?.toInt() ?? 0,
      minSupportedVersionCode:
          (json['minSupportedVersionCode'] as num?)?.toInt() ?? 0,
      storeUrl: json['storeUrl']?.toString(),
      releaseNotes: json['releaseNotes']?.toString(),
    );
  }
}
