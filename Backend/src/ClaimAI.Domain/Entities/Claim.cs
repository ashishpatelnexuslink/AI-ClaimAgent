using ClaimAI.Domain.Enums;

namespace ClaimAI.Domain.Entities;

public class Claim : BaseEntity
{
    public string ClaimNumber { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public ClaimStatus Status { get; set; } = ClaimStatus.Draft;
    public string ClaimType { get; set; } = string.Empty;
    public decimal? Amount { get; set; }
    public string? AssignedTo { get; set; }
    public string? PatientName { get; set; }
    public string? PolicyNumber { get; set; }

    // Claimant details
    public string? FullName { get; set; }
    public string? ClaimantType { get; set; }

    // Vehicle details
    public string? VehicleNumber { get; set; }
    public string? VinNumber { get; set; }
    public string? VehicleRegistrationNumber { get; set; }
    public string? VehicleModel { get; set; }

    // Incident details
    public DateTime? IncidentDate { get; set; }
    public string? IncidentLocation { get; set; }
    public string? IncidentDescription { get; set; }

    // Insurance details
    public string? CoverageType { get; set; }
    public string? PolicyStatus { get; set; }
    public DateTime? PolicyValidUntil { get; set; }

    // KYC / verification
    public bool? IdentityVerified { get; set; }

    // Document counts captured from the chat save_summary payload. These are a
    // snapshot of what the bot extracted; the authoritative list of uploaded
    // files lives in <see cref="ClaimDocument"/>.
    public int VehiclePhotosCount { get; set; }
    public int DamagePhotosCount { get; set; }
    public int LicensePhotosCount { get; set; }
    public int PoliceReportCount { get; set; }
    public int RepairBillCount { get; set; }
    public int SupportingDocsCount { get; set; }

    // Chatbot thread reference
    public string? ChatThreadId { get; set; }

    /// <summary>
    /// JSON blob capturing every useful key the chatbot returned in its final
    /// summary that did not map to a dedicated column. Lets us keep all chat
    /// data on the claim without chasing the schema every time the bot adds a
    /// new field.
    /// </summary>
    public string? AdditionalData { get; set; }

    // Foreign key to ApplicationUser
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;
}
