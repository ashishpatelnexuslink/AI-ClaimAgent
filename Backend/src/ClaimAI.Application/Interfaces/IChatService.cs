using ClaimAI.Application.DTOs.Mobile.Chat;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface IChatService
{
    Task<Result<ChatMessageDto>> SendMessageAsync(string userId, SendMessageRequestDto request);
    Task<Result<List<ChatMessageDto>>> GetChatHistoryAsync(string userId, string claimId);
    Task<Result<List<string>>> GetSuggestionsAsync(string userId, string claimId);
    Task<Result<SaveConversationResponseDto>> SaveConversationAsync(string userId, SaveConversationRequestDto request);
}
