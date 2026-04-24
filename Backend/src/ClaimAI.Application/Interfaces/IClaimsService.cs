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
}
