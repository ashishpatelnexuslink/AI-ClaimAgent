using ClaimAI.Application.DTOs.Mobile.Notifications;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Entities;
using ClaimAI.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace ClaimAI.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly IFcmSender _fcmSender;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        ApplicationDbContext context,
        IFcmSender fcmSender,
        ILogger<NotificationService> logger)
    {
        _context = context;
        _fcmSender = fcmSender;
        _logger = logger;
    }

    public async Task<Result<List<PendingActionDto>>> GetPendingActionsAsync(string userId)
    {
        var actions = await _context.Notifications
            .Include(n => n.Claim)
            .Where(n => n.UserId == userId && !n.IsRead)
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => new PendingActionDto
            {
                Id = n.Id,
                Title = n.Title,
                Message = n.Message,
                ActionType = n.ActionType,
                ActionUrl = n.ActionUrl,
                ClaimId = n.ClaimId.HasValue ? n.ClaimId.Value.ToString() : null,
                ClaimNumber = n.Claim != null ? n.Claim.ClaimNumber : null,
                CreatedAt = n.CreatedAt,
            })
            .ToListAsync();

        return Result<List<PendingActionDto>>.Success(actions);
    }

    public async Task<Result> MarkAsReadAsync(Guid notificationId, string userId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

        if (notification is null)
            return Result.Failure("Notification not found.");

        notification.IsRead = true;
        await _context.SaveChangesAsync();

        return Result.Success("Notification marked as read.");
    }

    public async Task<Result> RegisterDeviceAsync(string userId, RegisterDeviceDto dto)
    {
        var existing = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.FcmToken == dto.FcmToken);

        if (existing is not null)
        {
            existing.UserId = userId;
            existing.Platform = dto.Platform;
            existing.LastSeenAt = DateTime.UtcNow;
        }
        else
        {
            _context.UserDevices.Add(new UserDevice
            {
                UserId = userId,
                FcmToken = dto.FcmToken,
                Platform = dto.Platform,
                LastSeenAt = DateTime.UtcNow,
            });
        }

        await _context.SaveChangesAsync();
        return Result.Success("Device registered.");
    }

    public async Task<Result> UnregisterDeviceAsync(string userId, string fcmToken)
    {
        var device = await _context.UserDevices
            .FirstOrDefaultAsync(d => d.UserId == userId && d.FcmToken == fcmToken);

        if (device is null)
            return Result.Success("Device already unregistered.");

        device.IsDeleted = true;
        await _context.SaveChangesAsync();
        return Result.Success("Device unregistered.");
    }

    public async Task<Result> CreateAndPushAsync(
        string userId,
        string title,
        string message,
        string actionType,
        Guid? claimId = null,
        string? actionUrl = null)
    {
        var notification = new Domain.Entities.Notification
        {
            UserId = userId,
            Title = title,
            Message = message,
            ActionType = actionType,
            ActionUrl = actionUrl,
            ClaimId = claimId,
            IsRead = false,
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        var tokens = await _context.UserDevices
            .Where(d => d.UserId == userId)
            .Select(d => d.FcmToken)
            .ToListAsync();

        if (tokens.Count == 0)
            return Result.Success("Notification created (no devices to push).");

        var data = new Dictionary<string, string>
        {
            ["notificationId"] = notification.Id.ToString(),
            ["actionType"] = actionType,
        };
        if (claimId.HasValue) data["claimId"] = claimId.Value.ToString();
        if (!string.IsNullOrEmpty(actionUrl)) data["actionUrl"] = actionUrl;

        var sendResult = await _fcmSender.SendToTokensAsync(tokens, title, message, data);

        if (sendResult.InvalidTokens.Count > 0)
        {
            var invalid = await _context.UserDevices
                .Where(d => sendResult.InvalidTokens.Contains(d.FcmToken))
                .ToListAsync();
            foreach (var d in invalid) d.IsDeleted = true;
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Pruned {Count} invalid FCM tokens for user {UserId}",
                invalid.Count, userId);
        }

        return Result.Success($"Notification sent to {sendResult.SuccessCount}/{tokens.Count} devices.");
    }
}
