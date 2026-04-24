using System.Text.Json;
using System.Text.Json.Serialization;

namespace ClaimAI.Application.DTOs.Mobile.Claims;

/// <summary>
/// Lightweight payload used when the user closes a chat-completed claim.
/// All fields are optional — missing required columns fall back to sensible
/// defaults in <c>ClaimsService.CreateClaimFromChatAsync</c> so the user
/// always ends up with a real row in the Claims table.
/// </summary>
public class CreateClaimFromChatDto
{
    public string? ChatThreadId { get; set; }
    public string? ExternalReference { get; set; }

    public string? ClaimType { get; set; }
    public string? FullName { get; set; }
    public string? ClaimantType { get; set; }
    public string? PatientName { get; set; }

    public string? VehicleNumber { get; set; }
    public string? VinNumber { get; set; }
    public string? VehicleRegistrationNumber { get; set; }
    public string? VehicleModel { get; set; }

    public string? PolicyNumber { get; set; }
    public string? CoverageType { get; set; }
    public string? PolicyStatus { get; set; }
    public DateTime? PolicyValidUntil { get; set; }

    public DateTime? IncidentDate { get; set; }
    public string? IncidentLocation { get; set; }
    public string? IncidentDescription { get; set; }

    public string? Description { get; set; }
    public decimal? Amount { get; set; }

    public bool? IdentityVerified { get; set; }

    public int? VehiclePhotosCount { get; set; }
    public int? DamagePhotosCount { get; set; }
    public int? LicensePhotosCount { get; set; }
    public int? PoliceReportCount { get; set; }
    public int? RepairBillCount { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtraData { get; set; }
}
