using System.Text.Json;
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

    public async Task<Result<List<PendingActionDto>>> GetPendingActionsAsync(
        string userId, string? locale = null)
    {
        var notifications = await _context.Notifications
            .Include(n => n.Claim)
            .Where(n => n.UserId == userId && !n.IsRead)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();

        var templateKeys = notifications
            .Where(n => n.TemplateKey != null)
            .Select(n => n.TemplateKey!)
            .Distinct()
            .ToList();

        // Eager-load templates plus the relevant translations (exact tag and
        // language part) for the requested locale in one round trip.
        var languagePart = locale?.Split('-')[0];
        var templates = templateKeys.Count == 0
            ? new List<NotificationTemplate>()
            : await _context.NotificationTemplates
                .Where(t => templateKeys.Contains(t.Key))
                .Select(t => new NotificationTemplate
                {
                    Id = t.Id,
                    Key = t.Key,
                    DefaultTitle = t.DefaultTitle,
                    DefaultMessage = t.DefaultMessage,
                    Translations = t.Translations
                        .Where(tr => locale != null &&
                            (tr.Locale == locale || tr.Locale == languagePart))
                        .ToList(),
                })
                .ToListAsync();

        var templatesByKey = templates.ToDictionary(t => t.Key);

        var actions = notifications.Select(n =>
        {
            var (title, message) = ResolveLocalized(n, locale, languagePart, templatesByKey);
            return new PendingActionDto
            {
                Id = n.Id,
                Title = title,
                Message = message,
                ActionType = n.ActionType,
                ActionUrl = n.ActionUrl,
                ClaimId = n.ClaimId?.ToString(),
                ClaimNumber = n.Claim?.ClaimNumber,
                CreatedAt = n.CreatedAt,
            };
        }).ToList();

        return Result<List<PendingActionDto>>.Success(actions);
    }

    private static (string Title, string Message) ResolveLocalized(
        Notification n,
        string? locale,
        string? languagePart,
        IReadOnlyDictionary<string, NotificationTemplate> templatesByKey)
    {
        if (n.TemplateKey == null || !templatesByKey.TryGetValue(n.TemplateKey, out var tpl))
            return (n.Title, n.Message);

        var translation = tpl.Translations.FirstOrDefault(t => t.Locale == locale)
                       ?? tpl.Translations.FirstOrDefault(t => t.Locale == languagePart);

        var title = translation?.Title ?? tpl.DefaultTitle;
        var message = translation?.Message ?? tpl.DefaultMessage;

        var parameters = ParseParams(n.TemplateParams);
        return (ApplyParams(title, parameters), ApplyParams(message, parameters));
    }

    private static IReadOnlyDictionary<string, string> ParseParams(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return new Dictionary<string, string>();

        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json)
                   ?? new Dictionary<string, string>();
        }
        catch (JsonException)
        {
            return new Dictionary<string, string>();
        }
    }

    private static string ApplyParams(string template, IReadOnlyDictionary<string, string> parameters)
    {
        if (parameters.Count == 0) return template;

        var result = template;
        foreach (var (key, value) in parameters)
            result = result.Replace("{" + key + "}", value);
        return result;
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
        string? actionUrl = null,
        string? templateKey = null,
        IDictionary<string, string>? templateParams = null)
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
            TemplateKey = templateKey,
            TemplateParams = templateParams is { Count: > 0 }
                ? JsonSerializer.Serialize(templateParams)
                : null,
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
