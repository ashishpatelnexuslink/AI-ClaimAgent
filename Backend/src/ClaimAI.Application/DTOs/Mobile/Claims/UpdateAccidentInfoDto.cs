namespace ClaimAI.Application.DTOs.Mobile.Claims;

/// <summary>
/// Payload for the mobile "edit accident information" form on the claim
/// summary page. Only available while the claim is in <c>Pending</c> state.
/// </summary>
public class UpdateAccidentInfoDto
{
    public DateTime? IncidentDate { get; set; }
    public string? IncidentLocation { get; set; }
    public string? IncidentDescription { get; set; }
}
