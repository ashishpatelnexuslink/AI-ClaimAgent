namespace ClaimAI.Application.DTOs.Admin;

public class UpdateAdminUserDto
{
    public string Name { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = "Active";
}
