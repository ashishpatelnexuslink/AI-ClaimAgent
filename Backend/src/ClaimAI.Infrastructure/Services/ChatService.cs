using ClaimAI.Application.DTOs.Mobile.Chat;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Enums;
using ClaimAI.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Services;

public class ChatService : IChatService
{
    private readonly ApplicationDbContext _context;

    public ChatService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Result<ChatMessageDto>> SendMessageAsync(string userId, SendMessageRequestDto request)
    {
        if (!Guid.TryParse(request.ClaimId, out var claimId))
            return Result<ChatMessageDto>.Failure("Invalid ClaimId format.");

        var claimExists = await _context.Claims
            .AnyAsync(c => c.Id == claimId && c.UserId == userId);

        if (!claimExists)
            return Result<ChatMessageDto>.Failure("Claim not found.");

        // Find or create conversation for this user + claim
        var conversation = await _context.Conversations
            .FirstOrDefaultAsync(c => c.UserId == userId && c.ClaimId == claimId);

        if (conversation is null)
        {
            conversation = new Conversation
            {
                UserId = userId,
                ClaimId = claimId,
                Title = request.Message.Length > 50
                    ? request.Message[..50] + "..."
                    : request.Message,
            };
            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync();
        }

        // Save user message
        var userMessage = new ConversationMessage
        {
            ConversationId = conversation.Id,
            Role = MessageRole.User,
            Content = request.Message,
        };
        _context.ConversationMessages.Add(userMessage);

        // Generate stub assistant reply (replace with real AI integration later)
        var assistantMessage = new ConversationMessage
        {
            ConversationId = conversation.Id,
            Role = MessageRole.Assistant,
            Content = GenerateStubReply(request.Message),
        };
        _context.ConversationMessages.Add(assistantMessage);

        await _context.SaveChangesAsync();

        return Result<ChatMessageDto>.Success(new ChatMessageDto
        {
            Id = assistantMessage.Id.ToString(),
            Content = assistantMessage.Content,
            Role = assistantMessage.Role.ToString().ToLowerInvariant(),
            Timestamp = assistantMessage.CreatedAt,
            ClaimId = claimId.ToString(),
        });
    }

    public async Task<Result<List<ChatMessageDto>>> GetChatHistoryAsync(string userId, string claimId)
    {
        if (!Guid.TryParse(claimId, out var parsedClaimId))
            return Result<List<ChatMessageDto>>.Failure("Invalid ClaimId format.");

        var conversation = await _context.Conversations
            .FirstOrDefaultAsync(c => c.UserId == userId && c.ClaimId == parsedClaimId);

        if (conversation is null)
            return Result<List<ChatMessageDto>>.Success([]);

        var messages = await _context.ConversationMessages
            .Where(m => m.ConversationId == conversation.Id)
            .OrderBy(m => m.CreatedAt)
            .Select(m => new ChatMessageDto
            {
                Id = m.Id.ToString(),
                Content = m.Content,
                Role = m.Role.ToString().ToLowerInvariant(),
                Timestamp = m.CreatedAt,
                ClaimId = claimId,
            })
            .ToListAsync();

        return Result<List<ChatMessageDto>>.Success(messages);
    }

    public Task<Result<List<string>>> GetSuggestionsAsync(string userId, string claimId)
    {
        var suggestions = new List<string>
        {
            "What's the status of my claim?",
            "Upload supporting documents",
            "Speak to an agent",
            "Check estimated timeline",
        };

        return Task.FromResult(Result<List<string>>.Success(suggestions));
    }

    public async Task<Result<SaveConversationResponseDto>> SaveConversationAsync(
        string userId, SaveConversationRequestDto request)
    {
        Guid? claimId = null;
        if (!string.IsNullOrWhiteSpace(request.ClaimId))
        {
            if (!Guid.TryParse(request.ClaimId, out var parsed))
                return Result<SaveConversationResponseDto>.Failure("Invalid ClaimId format.");

            var claimExists = await _context.Claims
                .AnyAsync(c => c.Id == parsed && c.UserId == userId);
            if (!claimExists)
                return Result<SaveConversationResponseDto>.Failure("Claim not found.");

            claimId = parsed;
        }

        // Find an existing conversation for this user + claim so repeat
        // submissions don't create duplicate header rows.
        Conversation? conversation = null;
        if (claimId.HasValue)
        {
            conversation = await _context.Conversations
                .FirstOrDefaultAsync(c => c.UserId == userId && c.ClaimId == claimId);
        }

        if (conversation is null)
        {
            var title = request.Title;
            if (string.IsNullOrWhiteSpace(title))
            {
                var firstContent = request.Messages.FirstOrDefault()?.Content ?? string.Empty;
                title = firstContent.Length > 50 ? firstContent[..50] + "..." : firstContent;
            }

            conversation = new Conversation
            {
                UserId = userId,
                ClaimId = claimId,
                Title = title,
            };
            _context.Conversations.Add(conversation);
            await _context.SaveChangesAsync();
        }

        foreach (var m in request.Messages)
        {
            if (!Enum.TryParse<MessageRole>(m.Role, ignoreCase: true, out var role))
            {
                role = m.Role.Equals("bot", StringComparison.OrdinalIgnoreCase)
                    ? MessageRole.Assistant
                    : MessageRole.User;
            }

            _context.ConversationMessages.Add(new ConversationMessage
            {
                ConversationId = conversation.Id,
                Role = role,
                Content = m.Content,
                Metadata = m.Metadata,
            });
        }

        await _context.SaveChangesAsync();

        return Result<SaveConversationResponseDto>.Success(new SaveConversationResponseDto
        {
            ConversationId = conversation.Id.ToString(),
            MessageCount = request.Messages.Count,
        });
    }

    private static string GenerateStubReply(string userMessage)
    {
        return "I've received your message. Our team will review your claim and get back to you shortly. Is there anything else I can help you with?";
    }
}
