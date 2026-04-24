namespace ClaimAI.Application.DTOs.Web.Dashboard;

/// <summary>
/// Aggregate numbers consumed by the AdminPanel dashboard tiles.
/// All counts are computed over live (non soft-deleted) rows.
/// </summary>
public class AdminDashboardStatsDto
{
    public int TotalClaims { get; set; }
    public int PendingClaims { get; set; }
    public int ApprovedClaims { get; set; }
    public int RejectedClaims { get; set; }
    public int TotalUsers { get; set; }
    public int ActiveConversations { get; set; }
    public int ClaimsToday { get; set; }
    public double AvgResolutionDays { get; set; }

    // Simple period-over-period percentages (current 30d vs prior 30d), used
    // by the trend chip on each tile. `null` means the prior period had zero
    // rows, so a % change is undefined.
    public double? TotalClaimsDeltaPct { get; set; }
    public double? ApprovedDeltaPct { get; set; }
    public double? RejectedDeltaPct { get; set; }
}

public class AdminClaimsTrendPointDto
{
    public DateTime Date { get; set; }
    public int Submitted { get; set; }
    public int Approved { get; set; }
    public int Rejected { get; set; }
}

public class AdminClaimsByTypeDto
{
    public string Type { get; set; } = string.Empty;
    public int Count { get; set; }
}
