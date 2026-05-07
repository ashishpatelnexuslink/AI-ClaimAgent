import 'package:equatable/equatable.dart';

enum ClaimStatus { draft, pending, submitted, inReview, approved, rejected, closed }

class ClaimEntity extends Equatable {
  final String id;
  final String claimNumber;
  final String title;
  final ClaimStatus status;
  final String claimType;
  final double? amount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? policyNumber;

  // Policy / claimant details used by the claim detail screen.
  final String? fullName;
  final String? claimantType;
  final String? vinNumber;
  final String? vehicleRegistrationNumber;
  final String? vehicleModel;
  final String? policyStatus;
  final DateTime? policyValidUntil;

  // Incident fields captured from the chat summary.
  final DateTime? incidentDate;
  final String? incidentLocation;
  final String? incidentDescription;

  // KYC status snapshot from the chat.
  final bool? identityVerified;

  const ClaimEntity({
    required this.id,
    required this.claimNumber,
    required this.title,
    required this.status,
    required this.claimType,
    this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.policyNumber,
    this.fullName,
    this.claimantType,
    this.vinNumber,
    this.vehicleRegistrationNumber,
    this.vehicleModel,
    this.policyStatus,
    this.policyValidUntil,
    this.incidentDate,
    this.incidentLocation,
    this.incidentDescription,
    this.identityVerified,
  });

  @override
  List<Object?> get props => [
        id,
        claimNumber,
        title,
        status,
        claimType,
        amount,
        createdAt,
        updatedAt,
        policyNumber,
        fullName,
        claimantType,
        vinNumber,
        vehicleRegistrationNumber,
        vehicleModel,
        policyStatus,
        policyValidUntil,
        incidentDate,
        incidentLocation,
        incidentDescription,
        identityVerified,
      ];
}
