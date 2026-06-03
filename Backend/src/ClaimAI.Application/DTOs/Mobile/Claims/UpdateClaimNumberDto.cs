namespace ClaimAI.Application.DTOs.Mobile.Claims;

/// <summary>
/// Payload for overwriting <see cref="Domain.Entities.Claim.ClaimNumber"/>
/// with the reference number returned by the AI chatbot in a
/// <c>payload_type == "claim_reference"</c> stream message.
/// </summary>
public class UpdateClaimNumberDto
{
    public string ClaimNumber { get; set; } = string.Empty;
}
