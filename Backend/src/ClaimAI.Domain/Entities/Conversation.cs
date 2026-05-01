namespace ClaimAI.Domain.Entities;

/// <summary>
/// One row per saved chat session. The actual transcript lives in the file at
/// <see cref="JsonFilePath"/> (relative URL under wwwroot, e.g.
/// <c>/uploads/conversations/{ThreadId}.json</c>); this row only stores the
/// owner, the optional claim link, the AI thread id, and the file pointer.
/// </summary>
public class Conversation : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;

    public Guid? ClaimId { get; set; }
    public Claim? Claim { get; set; }

    public string ThreadId { get; set; } = string.Empty;

    public string JsonFilePath { get; set; } = string.Empty;

    public string? ChatMode { get; set; }
}
