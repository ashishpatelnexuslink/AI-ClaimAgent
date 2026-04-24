namespace ClaimAI.Application.DTOs.MobileUsers;

public class MobileUserDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Country { get; set; } = string.Empty;
    public string AvatarPersonality { get; set; } = string.Empty;
    public string MemberSince { get; set; } = string.Empty;
    public int TotalClaims { get; set; }
    public string Status { get; set; } = "Active";
    public string? ProfileImage { get; set; }
}
