namespace ClaimAI.Application.DTOs.Web.Claims;

/// <summary>
/// Row shape consumed by the AdminPanel claims table. Joined with
/// <c>UserProfile</c> so the admin sees a display name, not a GUID.
/// </summary>
public class AdminClaimListItemDto
{
    public Guid Id { get; set; }
    public string ClaimNumber { get; set; } = string.Empty;

    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;

    public string Type { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? VehicleReg { get; set; }
    public DateTime? IncidentDate { get; set; }
    public DateTime SubmittedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public decimal? Amount { get; set; }
    public string? AssignedTo { get; set; }
    public string? ClaimantType { get; set; }
}

public class AdminClaimDetailDto : AdminClaimListItemDto
{
    public string? Description { get; set; }
    public string? FullName { get; set; }
    public string? PolicyNumber { get; set; }
    public string? VehicleModel { get; set; }
    public string? VinNumber { get; set; }
    public string? VehicleRegistrationNumber { get; set; }
    public string? IncidentLocation { get; set; }
    public string? IncidentDescription { get; set; }
    public string? CoverageType { get; set; }
    public string? PolicyStatus { get; set; }
    public DateTime? PolicyValidUntil { get; set; }
    public bool? IdentityVerified { get; set; }
    public int VehiclePhotosCount { get; set; }
    public int DamagePhotosCount { get; set; }
    public int LicensePhotosCount { get; set; }
    public int PoliceReportCount { get; set; }
    public int RepairBillCount { get; set; }
    public int SupportingDocsCount { get; set; }
    public string? AdditionalData { get; set; }
}

public class AdminClaimListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? Search { get; set; }
    public string? Status { get; set; }
    public string? Type { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
}

public class UpdateClaimStatusRequest
{
    public string Status { get; set; } = string.Empty;
}
