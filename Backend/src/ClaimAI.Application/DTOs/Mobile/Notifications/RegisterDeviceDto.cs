using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.Mobile.Notifications;

public class RegisterDeviceDto
{
    public string FcmToken { get; set; } = string.Empty;
    public DevicePlatform Platform { get; set; }
}
