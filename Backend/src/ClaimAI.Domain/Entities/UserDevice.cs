using ClaimAI.Domain.Enums;

namespace ClaimAI.Domain.Entities;

public class UserDevice : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;

    public string FcmToken { get; set; } = string.Empty;
    public DevicePlatform Platform { get; set; }
    public DateTime LastSeenAt { get; set; } = DateTime.UtcNow;
}
