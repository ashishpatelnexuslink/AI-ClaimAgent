namespace ClaimAI.Application.DTOs.Mobile.Auth;

public class SendOtpResponseDto
{
    public string Otp { get; set; } = string.Empty;
    public bool IsNewUser { get; set; }
}
