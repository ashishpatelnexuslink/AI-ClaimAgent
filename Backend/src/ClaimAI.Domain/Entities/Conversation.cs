namespace ClaimAI.Domain.Entities;

public class Conversation : BaseEntity
{
    public string? Title { get; set; }

    // Owner
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;

    // Related claim (optional)
    public Guid? ClaimId { get; set; }
    public Claim? Claim { get; set; }

    // Messages
    public ICollection<ConversationMessage> Messages { get; set; } = new List<ConversationMessage>();
}
