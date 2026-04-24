using ClaimAI.Application.DTOs.Mobile.Notifications;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface INotificationService
{
    Task<Result<List<PendingActionDto>>> GetPendingActionsAsync(string userId);
    Task<Result> MarkAsReadAsync(Guid notificationId, string userId);
}
