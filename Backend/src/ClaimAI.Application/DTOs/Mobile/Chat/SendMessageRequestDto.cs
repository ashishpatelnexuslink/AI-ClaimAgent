namespace ClaimAI.Application.DTOs.Mobile.Chat;

public class SendMessageRequestDto
{
    public string Message { get; set; } = string.Empty;
    public string ClaimId { get; set; } = string.Empty;
}
