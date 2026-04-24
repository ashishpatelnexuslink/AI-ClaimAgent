using ClaimAI.Application.DTOs.Mobile.Notifications;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;

    public NotificationService(ApplicationDbContext context)
    {
        _context = context;
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
}
