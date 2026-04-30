using ClaimAI.Application.DTOs.Mobile.Chat;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface IChatService
{
    Task<Result<List<string>>> GetSuggestionsAsync(string userId, string claimId);
    Task<Result<SaveConversationResponseDto>> SaveConversationAsync(string userId, SaveConversationRequestDto request);
}
