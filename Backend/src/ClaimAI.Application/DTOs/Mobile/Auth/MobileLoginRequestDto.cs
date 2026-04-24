namespace ClaimAI.Application.DTOs.Mobile.Auth;

public class MobileLoginRequestDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? DeviceId { get; set; }
    public string? PushToken { get; set; }
    public string? Platform { get; set; } // iOS, Android
}
