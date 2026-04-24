using System.Text.Json;
using System.Text.Json.Serialization;

namespace ClaimAI.Application.DTOs.Mobile.Claims;

public class CreateClaimDto
{
    public string ClaimType { get; set; } = string.Empty;

    // Claimant details
    public string? FullName { get; set; }
    public string? ClaimantType { get; set; }
    public string? PatientName { get; set; }

    // Vehicle details
    public string? VehicleNumber { get; set; }
    public string? VinNumber { get; set; }
    public string? VehicleRegistrationNumber { get; set; }
    public string? VehicleModel { get; set; }

    // Policy details
    public string? PolicyNumber { get; set; }
    public string? CoverageType { get; set; }
    public string? PolicyStatus { get; set; }
    public DateTime? PolicyValidUntil { get; set; }

    // Incident details
    public DateTime? IncidentDate { get; set; }
    public string? IncidentLocation { get; set; }
    public string? IncidentDescription { get; set; }

    // Free-form description / notes surfaced in the final summary.
    public string? Description { get; set; }

    // Amount
    public decimal? Amount { get; set; }

    // Chatbot thread reference
    public string? ChatThreadId { get; set; }

    /// <summary>
    /// Catches any JSON keys in the incoming payload that don't map to the
    /// named properties above. The service persists this blob into
    /// <c>Claim.AdditionalData</c> so nothing the chatbot returned is lost.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtraData { get; set; }
}
