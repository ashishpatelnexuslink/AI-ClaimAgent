import 'package:claim_ai/features/claims/domain/entities/claim_entity.dart';

class ClaimModel extends ClaimEntity {
  const ClaimModel({
    required super.id,
    required super.claimNumber,
    required super.title,
    super.description,
    required super.status,
    required super.claimType,
    super.amount,
    super.assignedTo,
    required super.createdAt,
    required super.updatedAt,
    super.patientName,
    super.policyNumber,
    super.fullName,
    super.claimantType,
    super.vehicleNumber,
    super.vinNumber,
    super.vehicleRegistrationNumber,
    super.vehicleModel,
    super.coverageType,
    super.policyStatus,
    super.policyValidUntil,
    super.incidentDate,
    super.incidentLocation,
    super.incidentDescription,
    super.identityVerified,
    super.vehiclePhotosCount,
    super.damagePhotosCount,
    super.licensePhotosCount,
    super.policeReportCount,
    super.repairBillCount,
    super.additionalData,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt'] as String?;
    final createdAt = createdAtStr != null
        ? DateTime.parse(createdAtStr)
        : DateTime.now();
    final updatedAtStr = json['updatedAt'] as String?;
    return ClaimModel(
      id: (json['id'] ?? '').toString(),
      claimNumber: (json['claimNumber'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      status: _parseStatus((json['status'] ?? '') as String),
      claimType: (json['claimType'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble(),
      assignedTo: json['assignedTo'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : createdAt,
      patientName: json['patientName'] as String?,
      policyNumber: json['policyNumber'] as String?,
      fullName: json['fullName'] as String?,
      claimantType: json['claimantType'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      vinNumber: json['vinNumber'] as String?,
      vehicleRegistrationNumber: json['vehicleRegistrationNumber'] as String?,
      vehicleModel: json['vehicleModel'] as String?,
      coverageType: json['coverageType'] as String?,
      policyStatus: json['policyStatus'] as String?,
      policyValidUntil: _parseDate(json['policyValidUntil']),
      incidentDate: _parseDate(json['incidentDate']),
      incidentLocation: json['incidentLocation'] as String?,
      incidentDescription: json['incidentDescription'] as String?,
      identityVerified: json['identityVerified'] as bool?,
      vehiclePhotosCount: (json['vehiclePhotosCount'] as num?)?.toInt() ?? 0,
      damagePhotosCount: (json['damagePhotosCount'] as num?)?.toInt() ?? 0,
      licensePhotosCount: (json['licensePhotosCount'] as num?)?.toInt() ?? 0,
      policeReportCount: (json['policeReportCount'] as num?)?.toInt() ?? 0,
      repairBillCount: (json['repairBillCount'] as num?)?.toInt() ?? 0,
      additionalData: json['additionalData'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'claimNumber': claimNumber,
      'title': title,
      'description': description,
      'status': status.name,
      'claimType': claimType,
      'amount': amount,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'patientName': patientName,
      'policyNumber': policyNumber,
      'fullName': fullName,
      'claimantType': claimantType,
      'vehicleNumber': vehicleNumber,
      'vinNumber': vinNumber,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'vehicleModel': vehicleModel,
      'coverageType': coverageType,
      'policyStatus': policyStatus,
      'policyValidUntil': policyValidUntil?.toIso8601String(),
      'incidentDate': incidentDate?.toIso8601String(),
      'incidentLocation': incidentLocation,
      'incidentDescription': incidentDescription,
      'identityVerified': identityVerified,
      'vehiclePhotosCount': vehiclePhotosCount,
      'damagePhotosCount': damagePhotosCount,
      'licensePhotosCount': licensePhotosCount,
      'policeReportCount': policeReportCount,
      'repairBillCount': repairBillCount,
      'additionalData': additionalData,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static ClaimStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return ClaimStatus.draft;
      case 'pending':
        return ClaimStatus.pending;
      case 'submitted':
        return ClaimStatus.submitted;
      case 'inreview':
      case 'in_review':
        return ClaimStatus.inReview;
      case 'approved':
        return ClaimStatus.approved;
      case 'rejected':
        return ClaimStatus.rejected;
      case 'closed':
        return ClaimStatus.closed;
      default:
        return ClaimStatus.draft;
    }
  }
}
