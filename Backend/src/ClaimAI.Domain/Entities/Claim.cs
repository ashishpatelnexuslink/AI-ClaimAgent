using ClaimAI.Domain.Enums;

namespace ClaimAI.Domain.Entities;

public class Claim : BaseEntity
{
    public string ClaimNumber { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public ClaimStatus Status { get; set; } = ClaimStatus.Draft;
    public string ClaimType { get; set; } = string.Empty;
    public decimal? Amount { get; set; }
    public string? PolicyNumber { get; set; }

    // Claimant details
    public string? FullName { get; set; }
    public string? ClaimantType { get; set; }

    // Vehicle details
    public string? VinNumber { get; set; }
    public string? VehicleRegistrationNumber { get; set; }
    public string? VehicleModel { get; set; }

    // Incident details
    public DateTime? IncidentDate { get; set; }
    public string? IncidentLocation { get; set; }
    public string? IncidentDescription { get; set; }

    // Insurance details
    public string? PolicyStatus { get; set; }
    public DateTime? PolicyValidUntil { get; set; }

    // KYC / verification
    public bool? IdentityVerified { get; set; }

    // Chatbot thread reference
    public string? ChatThreadId { get; set; }

    // Foreign key to ApplicationUser
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;
}
