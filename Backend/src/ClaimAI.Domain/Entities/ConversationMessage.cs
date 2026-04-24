using ClaimAI.Domain.Enums;

namespace ClaimAI.Domain.Entities;

public class ConversationMessage : BaseEntity
{
    public Guid ConversationId { get; set; }
    public Conversation Conversation { get; set; } = null!;

    public MessageRole Role { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? Metadata { get; set; }
}
