namespace ClaimAI.Application.DTOs.Mobile.Notifications;

public class PendingActionDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string ActionType { get; set; } = string.Empty;
    public string? ActionUrl { get; set; }
    public string? ClaimId { get; set; }
    public string? ClaimNumber { get; set; }
    public DateTime CreatedAt { get; set; }
}
