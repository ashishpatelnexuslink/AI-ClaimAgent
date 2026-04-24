namespace ClaimAI.Application.DTOs.Mobile.Claims;

public class ClaimResponseDto
{
    public Guid Id { get; set; }
    public string ClaimNumber { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string ClaimType { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public string? ClaimantType { get; set; }
    public string? PatientName { get; set; }
    public string? PolicyNumber { get; set; }
    public string? CoverageType { get; set; }
    public string? PolicyStatus { get; set; }
    public DateTime? PolicyValidUntil { get; set; }
    public string? VehicleModel { get; set; }
    public string? VehicleNumber { get; set; }
    public string? VinNumber { get; set; }
    public string? VehicleRegistrationNumber { get; set; }
    public string? IncidentLocation { get; set; }
    public DateTime? IncidentDate { get; set; }
    public string? IncidentDescription { get; set; }
    public string? Description { get; set; }
    public decimal? Amount { get; set; }
    public bool? IdentityVerified { get; set; }
    public int VehiclePhotosCount { get; set; }
    public int DamagePhotosCount { get; set; }
    public int LicensePhotosCount { get; set; }
    public int PoliceReportCount { get; set; }
    public int RepairBillCount { get; set; }
    public string? ChatThreadId { get; set; }
    public string? AdditionalData { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
