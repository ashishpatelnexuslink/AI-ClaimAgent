using ClaimAI.Application.DTOs.AiMl;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

/// <summary>
/// Thin client over the external AI/ML service (same host the mobile app
/// streams from at <c>/chat/stream</c>). Handles silent login and bearer-token
/// caching internally.
/// </summary>
public interface IAiMlClient
{
    /// <summary>POSTs the supplied template settings to <c>{baseUrl}/config</c>.</summary>
    Task<Result<TemplateConfigResponseDto>> SyncTemplateConfigAsync(
        TemplateConfigRequestDto request, CancellationToken cancellationToken = default);
}
