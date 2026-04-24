namespace ClaimAI.Application.DTOs.Mobile.Chat;

public class ChatMessageDto
{
    public string Id { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public string? ClaimId { get; set; }
}
