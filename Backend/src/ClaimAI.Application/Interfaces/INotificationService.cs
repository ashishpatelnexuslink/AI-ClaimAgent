using ClaimAI.Application.DTOs.Mobile.Notifications;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface INotificationService
{
    Task<Result<List<PendingActionDto>>> GetPendingActionsAsync(string userId, string? locale = null);
    Task<Result> MarkAsReadAsync(Guid notificationId, string userId);

    Task<Result> RegisterDeviceAsync(string userId, RegisterDeviceDto dto);
    Task<Result> UnregisterDeviceAsync(string userId, string fcmToken);

    Task<Result> CreateAndPushAsync(
        string userId,
        string title,
        string message,
        string actionType,
        Guid? claimId = null,
        string? actionUrl = null,
        string? templateKey = null,
        IDictionary<string, string>? templateParams = null);
}
