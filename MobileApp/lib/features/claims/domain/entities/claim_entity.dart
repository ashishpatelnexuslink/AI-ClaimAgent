import 'package:equatable/equatable.dart';

enum ClaimStatus { draft, pending, submitted, inReview, approved, rejected, closed }

class ClaimEntity extends Equatable {
  final String id;
  final String claimNumber;
  final String title;
  final String? description;
  final ClaimStatus status;
  final String claimType;
  final double? amount;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? patientName;
  final String? policyNumber;

  // Policy / claimant details used by the claim detail screen.
  final String? fullName;
  final String? claimantType;
  final String? vehicleNumber;
  final String? vinNumber;
  final String? vehicleRegistrationNumber;
  final String? vehicleModel;
  final String? coverageType;
  final String? policyStatus;
  final DateTime? policyValidUntil;

  // Incident fields captured from the chat summary.
  final DateTime? incidentDate;
  final String? incidentLocation;
  final String? incidentDescription;

  // KYC + document counts snapshot from the chat.
  final bool? identityVerified;
  final int vehiclePhotosCount;
  final int damagePhotosCount;
  final int licensePhotosCount;
  final int policeReportCount;
  final int repairBillCount;

  final String? additionalData;

  const ClaimEntity({
    required this.id,
    required this.claimNumber,
    required this.title,
    this.description,
    required this.status,
    required this.claimType,
    this.amount,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.patientName,
    this.policyNumber,
    this.fullName,
    this.claimantType,
    this.vehicleNumber,
    this.vinNumber,
    this.vehicleRegistrationNumber,
    this.vehicleModel,
    this.coverageType,
    this.policyStatus,
    this.policyValidUntil,
    this.incidentDate,
    this.incidentLocation,
    this.incidentDescription,
    this.identityVerified,
    this.vehiclePhotosCount = 0,
    this.damagePhotosCount = 0,
    this.licensePhotosCount = 0,
    this.policeReportCount = 0,
    this.repairBillCount = 0,
    this.additionalData,
  });

  @override
  List<Object?> get props => [
        id,
        claimNumber,
        title,
        description,
        status,
        claimType,
        amount,
        assignedTo,
        createdAt,
        updatedAt,
        patientName,
        policyNumber,
        fullName,
        claimantType,
        vehicleNumber,
        vinNumber,
        vehicleRegistrationNumber,
        vehicleModel,
        coverageType,
        policyStatus,
        policyValidUntil,
        incidentDate,
        incidentLocation,
        incidentDescription,
        identityVerified,
        vehiclePhotosCount,
        damagePhotosCount,
        licensePhotosCount,
        policeReportCount,
        repairBillCount,
        additionalData,
      ];
}
