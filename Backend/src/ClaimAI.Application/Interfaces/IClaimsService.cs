using ClaimAI.Application.DTOs.Mobile.Claims;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface IClaimsService
{
    Task<Result<DashboardSummaryDto>> GetDashboardSummaryAsync(string userId);
    Task<Result<ClaimResponseDto>> CreateClaimAsync(CreateClaimDto dto, string userId);
    Task<Result<ClaimResponseDto>> CreateClaimFromChatAsync(CreateClaimFromChatDto dto, string userId);
    Task<Result<List<ClaimResponseDto>>> GetUserClaimsAsync(string userId);
    Task<Result<ClaimResponseDto>> GetClaimByIdAsync(Guid claimId, string userId);

    /// <summary>
    /// Updates incident date / location / description on a claim the user owns.
    /// Only allowed while the claim is in <c>Pending</c> state — any other
    /// status returns a failure result.
    /// </summary>
    Task<Result<ClaimResponseDto>> UpdateAccidentInfoAsync(
        Guid claimId,
        string userId,
        UpdateAccidentInfoDto dto);

    /// <summary>
    /// Admin/system-initiated status update. Persists the new status and
    /// emits a push notification to the claim owner's registered devices.
    /// </summary>
    Task<Result<ClaimResponseDto>> UpdateClaimStatusAsync(
        Guid claimId,
        UpdateClaimStatusDto dto);
}
