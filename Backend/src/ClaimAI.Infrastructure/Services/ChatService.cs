using System.Text.Json;
using ClaimAI.Application.DTOs.Mobile.Chat;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Entities;
using ClaimAI.Infrastructure.Data;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Services;

public class ChatService : IChatService
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _env;

    private static readonly JsonSerializerOptions TranscriptJsonOptions = new()
    {
        WriteIndented = true,
    };

    public ChatService(ApplicationDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
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

    /// <summary>
    /// Persists a chat session. The full message stream is written to a JSON
    /// file at <c>wwwroot/uploads/conversations/{ThreadId}.json</c>; the
    /// <c>Conversations</c> row only stores the owner, optional claim link,
    /// the AI thread id, and the relative path to that file. Re-saving the
    /// same threadId overwrites the file and updates the existing row.
    /// </summary>
    public async Task<Result<SaveConversationResponseDto>> SaveConversationAsync(
        string userId, SaveConversationRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.ThreadId))
            return Result<SaveConversationResponseDto>.Failure("ThreadId is required.");

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

        // Write the transcript JSON file. ThreadId doubles as the filename so
        // a re-submit for the same chat session overwrites the previous file.
        var safeThreadId = SanitizeThreadIdForFilename(request.ThreadId.Trim());
        var webRoot = _env.WebRootPath
            ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var conversationsDir = Path.Combine(webRoot, "uploads", "conversations");
        Directory.CreateDirectory(conversationsDir);

        var fileName = $"{safeThreadId}.json";
        var diskPath = Path.Combine(conversationsDir, fileName);
        var relativeUrl = $"/uploads/conversations/{fileName}";

        await using (var stream = new FileStream(diskPath, FileMode.Create))
        {
            await JsonSerializer.SerializeAsync(stream, request.Messages, TranscriptJsonOptions);
        }

        // Upsert the conversation row by ThreadId so repeat saves don't pile up.
        var conversation = await _context.Conversations
            .FirstOrDefaultAsync(c => c.UserId == userId && c.ThreadId == request.ThreadId);

        if (conversation is null)
        {
            conversation = new Conversation
            {
                UserId = userId,
                ClaimId = claimId,
                ThreadId = request.ThreadId,
                JsonFilePath = relativeUrl,
            };
            _context.Conversations.Add(conversation);
        }
        else
        {
            conversation.ClaimId = claimId ?? conversation.ClaimId;
            conversation.JsonFilePath = relativeUrl;
        }

        await _context.SaveChangesAsync();

        return Result<SaveConversationResponseDto>.Success(new SaveConversationResponseDto
        {
            ConversationId = conversation.Id.ToString(),
            MessageCount = request.Messages.Count,
        });
    }

    /// <summary>
    /// Strips anything outside [A-Za-z0-9_-] from a thread id before using it
    /// as a filename, so a malformed/malicious value can't escape the
    /// conversations folder. Falls back to a Guid if nothing usable remains.
    /// </summary>
    private static string SanitizeThreadIdForFilename(string threadId)
    {
        var cleaned = new string(threadId
            .Where(c => char.IsLetterOrDigit(c) || c == '_' || c == '-')
            .ToArray());
        return string.IsNullOrEmpty(cleaned) ? Guid.NewGuid().ToString() : cleaned;
    }
}
