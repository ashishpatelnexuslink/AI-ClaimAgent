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

    /// <summary>
    /// Optional <see cref="NotificationTemplate.Key"/> the API uses to resolve
    /// a localized title/message at fetch time. Legacy rows have this null and
    /// render straight from <see cref="Title"/>/<see cref="Message"/>.
    /// </summary>
    public string? TemplateKey { get; set; }

    /// <summary>
    /// JSON-encoded substitution params for the template (e.g.
    /// <c>{"claimNumber":"CL-1234"}</c>). Stored as jsonb.
    /// </summary>
    public string? TemplateParams { get; set; }
}
