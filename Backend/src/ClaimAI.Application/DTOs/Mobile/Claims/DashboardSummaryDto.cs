namespace ClaimAI.Application.DTOs.Mobile.Claims;

public class DashboardSummaryDto
{
    public int TotalClaims { get; set; }
    public int PendingClaims { get; set; }
    public int ApprovedClaims { get; set; }
    public int RejectedClaims { get; set; }
    public int InReviewClaims { get; set; }
    public double TotalAmount { get; set; }
    public double ApprovedAmount { get; set; }
}
