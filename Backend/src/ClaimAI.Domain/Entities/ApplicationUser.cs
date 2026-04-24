using Microsoft.AspNetCore.Identity;

namespace ClaimAI.Domain.Entities;

public class ApplicationUser : IdentityUser
{
    // Auth-related fields
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiryTime { get; set; }

    // OTP fields
    public string? Otp { get; set; }
    public DateTime? OtpExpiryTime { get; set; }
    public int OtpAttempts { get; set; } = 0;

    // Navigation to profile
    public UserProfile? Profile { get; set; }
}
