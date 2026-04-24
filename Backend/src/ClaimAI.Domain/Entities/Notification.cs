namespace ClaimAI.Domain.Entities;

public class Notification : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string ActionType { get; set; } = string.Empty;  // e.g. "upload_document", "review_claim"
    public string? ActionUrl { get; set; }
    public bool IsRead { get; set; }

    // Related claim (optional)
    public Guid? ClaimId { get; set; }
    public Claim? Claim { get; set; }

    // Target user
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;
}
