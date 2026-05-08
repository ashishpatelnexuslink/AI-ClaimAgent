using System.Text.Json;
using System.Text.Json.Serialization;

namespace ClaimAI.Application.DTOs.Mobile.Claims;

public class CreateClaimDto
{
    public string ClaimType { get; set; } = string.Empty;

    // Claimant details
    public string? FullName { get; set; }
    public string? ClaimantType { get; set; }

    // Vehicle details
    public string? VinNumber { get; set; }
    public string? VehicleRegistrationNumber { get; set; }
    public string? VehicleModel { get; set; }

    // Policy details
    public string? PolicyNumber { get; set; }
    public string? PolicyStatus { get; set; }
    public DateTime? PolicyValidUntil { get; set; }

    // Incident details
    public DateTime? IncidentDate { get; set; }
    public string? IncidentLocation { get; set; }
    public string? IncidentDescription { get; set; }

    // Amount
    public decimal? Amount { get; set; }

    // Chatbot thread reference
    public string? ChatThreadId { get; set; }

    /// <summary>
    /// Catches any JSON keys in the incoming payload that don't map to the
    /// named properties above. Currently ignored on the server side — kept so
    /// JSON deserialization doesn't fail on stray chatbot fields.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtraData { get; set; }
}
