using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.Mobile.Claims;

public class UpdateClaimStatusDto
{
    public ClaimStatus Status { get; set; }
    public string? Note { get; set; }
}
