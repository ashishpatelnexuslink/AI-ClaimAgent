namespace ClaimAI.Application.DTOs.Mobile.Chat;

public class SaveConversationRequestDto
{
    public string? ThreadId { get; set; }
    public string? ClaimId { get; set; }
    public string? ExternalReference { get; set; }
    public string? Title { get; set; }
    public List<SaveConversationMessageDto> Messages { get; set; } = new();
}

public class SaveConversationMessageDto
{
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime? Timestamp { get; set; }
    public string? Metadata { get; set; }
}

public class SaveConversationResponseDto
{
    public string ConversationId { get; set; } = string.Empty;
    public int MessageCount { get; set; }
}
