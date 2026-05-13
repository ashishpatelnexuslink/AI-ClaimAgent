namespace ClaimAI.Domain.Entities;

public class UserProfile : BaseEntity
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsBiometricEnabled { get; set; }

    // FK to AspNetUsers
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;
}
