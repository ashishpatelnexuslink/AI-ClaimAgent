using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Web.Dashboard;
using ClaimAI.Domain.Enums;
using ClaimAI.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/dashboard")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public DashboardController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var todayStart = now.Date;
        var currentWindowStart = now.AddDays(-30);
        var priorWindowStart = now.AddDays(-60);

        var claims = _context.Claims;

        var totalClaims = await claims.CountAsync(cancellationToken);
        var pendingClaims = await claims
            .CountAsync(c => c.Status == ClaimStatus.Pending || c.Status == ClaimStatus.Submitted || c.Status == ClaimStatus.InReview, cancellationToken);
        var approvedClaims = await claims.CountAsync(c => c.Status == ClaimStatus.Approved, cancellationToken);
        var rejectedClaims = await claims.CountAsync(c => c.Status == ClaimStatus.Rejected, cancellationToken);
        var claimsToday = await claims.CountAsync(c => c.CreatedAt >= todayStart, cancellationToken);

        // Avg resolution = days between CreatedAt and UpdatedAt for claims that reached a terminal state.
        var terminalClaims = await claims
            .Where(c => c.Status == ClaimStatus.Approved || c.Status == ClaimStatus.Rejected || c.Status == ClaimStatus.Closed)
            .Select(c => new { c.CreatedAt, c.UpdatedAt })
            .ToListAsync(cancellationToken);

        var avgResolutionDays = terminalClaims.Count > 0
            ? Math.Round(terminalClaims.Average(c => ((c.UpdatedAt ?? c.CreatedAt) - c.CreatedAt).TotalDays), 1)
            : 0;

        var totalUsers = await _context.UserProfiles.CountAsync(cancellationToken);

        // "Active" conversation = any conversation row touched in the last 24
        // hours. Messages live in a JSON file now, not a child table, so we
        // proxy activity off the row's UpdatedAt/CreatedAt instead.
        var activeSince = now.AddHours(-24);
        var activeConversations = await _context.Conversations
            .Where(c => (c.UpdatedAt ?? c.CreatedAt) >= activeSince)
            .CountAsync(cancellationToken);

        // Period-over-period deltas for the three tiles that show a trend chip.
        var currentTotal = await claims.CountAsync(c => c.CreatedAt >= currentWindowStart, cancellationToken);
        var priorTotal = await claims.CountAsync(c => c.CreatedAt >= priorWindowStart && c.CreatedAt < currentWindowStart, cancellationToken);

        var currentApproved = await claims.CountAsync(c => c.Status == ClaimStatus.Approved && c.UpdatedAt >= currentWindowStart, cancellationToken);
        var priorApproved = await claims.CountAsync(c => c.Status == ClaimStatus.Approved && c.UpdatedAt >= priorWindowStart && c.UpdatedAt < currentWindowStart, cancellationToken);

        var currentRejected = await claims.CountAsync(c => c.Status == ClaimStatus.Rejected && c.UpdatedAt >= currentWindowStart, cancellationToken);
        var priorRejected = await claims.CountAsync(c => c.Status == ClaimStatus.Rejected && c.UpdatedAt >= priorWindowStart && c.UpdatedAt < currentWindowStart, cancellationToken);

        var dto = new AdminDashboardStatsDto
        {
            TotalClaims = totalClaims,
            PendingClaims = pendingClaims,
            ApprovedClaims = approvedClaims,
            RejectedClaims = rejectedClaims,
            TotalUsers = totalUsers,
            ActiveConversations = activeConversations,
            ClaimsToday = claimsToday,
            AvgResolutionDays = avgResolutionDays,
            TotalClaimsDeltaPct = PctChange(priorTotal, currentTotal),
            ApprovedDeltaPct = PctChange(priorApproved, currentApproved),
            RejectedDeltaPct = PctChange(priorRejected, currentRejected),
        };

        return Ok(ApiResponse<AdminDashboardStatsDto>.SuccessResponse(dto));
    }

    [HttpGet("claims-trend")]
    public async Task<IActionResult> GetClaimsTrend(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        days = Math.Clamp(days, 7, 180);
        var start = DateTime.UtcNow.Date.AddDays(-(days - 1));

        // Submitted buckets by CreatedAt; approved/rejected bucket by UpdatedAt
        // (terminal state transition time). Both are projected to UTC dates so
        // the chart gets one row per calendar day.
        var submittedByDay = await _context.Claims
            .Where(c => c.CreatedAt >= start)
            .GroupBy(c => c.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var terminalByDay = await _context.Claims
            .Where(c => (c.Status == ClaimStatus.Approved || c.Status == ClaimStatus.Rejected)
                && c.UpdatedAt != null && c.UpdatedAt >= start)
            .GroupBy(c => new { Date = c.UpdatedAt!.Value.Date, c.Status })
            .Select(g => new { g.Key.Date, g.Key.Status, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var submittedMap = submittedByDay.ToDictionary(x => x.Date, x => x.Count);
        var approvedMap = terminalByDay.Where(x => x.Status == ClaimStatus.Approved)
            .ToDictionary(x => x.Date, x => x.Count);
        var rejectedMap = terminalByDay.Where(x => x.Status == ClaimStatus.Rejected)
            .ToDictionary(x => x.Date, x => x.Count);

        var points = new List<AdminClaimsTrendPointDto>(days);
        for (var i = 0; i < days; i++)
        {
            var d = start.AddDays(i);
            points.Add(new AdminClaimsTrendPointDto
            {
                Date = d,
                Submitted = submittedMap.GetValueOrDefault(d, 0),
                Approved = approvedMap.GetValueOrDefault(d, 0),
                Rejected = rejectedMap.GetValueOrDefault(d, 0),
            });
        }

        return Ok(ApiResponse<IReadOnlyList<AdminClaimsTrendPointDto>>.SuccessResponse(points));
    }

    [HttpGet("claims-by-type")]
    public async Task<IActionResult> GetClaimsByType(CancellationToken cancellationToken)
    {
        var rows = await _context.Claims
            .GroupBy(c => c.ClaimType)
            .Select(g => new AdminClaimsByTypeDto
            {
                Type = string.IsNullOrWhiteSpace(g.Key) ? "Unspecified" : g.Key,
                Count = g.Count(),
            })
            .OrderByDescending(r => r.Count)
            .ToListAsync(cancellationToken);

        return Ok(ApiResponse<IReadOnlyList<AdminClaimsByTypeDto>>.SuccessResponse(rows));
    }

    private static double? PctChange(int prior, int current)
    {
        if (prior == 0) return null;
        return Math.Round(((double)(current - prior) / prior) * 100.0, 1);
    }
}
