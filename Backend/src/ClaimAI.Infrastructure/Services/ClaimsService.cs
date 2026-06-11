using ClaimAI.Application.DTOs.Mobile.Claims;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Enums;
using ClaimAI.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Services;

public class ClaimsService : IClaimsService
{
    private readonly ApplicationDbContext _context;
    private readonly INotificationService _notificationService;

    public ClaimsService(
        ApplicationDbContext context,
        INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<Result<DashboardSummaryDto>> GetDashboardSummaryAsync(string userId)
    {
        var claims = await _context.Claims
            .Where(c => c.UserId == userId)
            .Select(c => new { c.Status, c.Amount })
            .ToListAsync();

        var summary = new DashboardSummaryDto
        {
            TotalClaims = claims.Count,
            PendingClaims = claims.Count(c =>
                c.Status == ClaimStatus.Pending || c.Status == ClaimStatus.Submitted),
            ApprovedClaims = claims.Count(c => c.Status == ClaimStatus.Approved),
            RejectedClaims = claims.Count(c => c.Status == ClaimStatus.Rejected),
            InReviewClaims = claims.Count(c => c.Status == ClaimStatus.InReview),
            TotalAmount = (double)claims.Sum(c => c.Amount ?? 0),
            ApprovedAmount = (double)claims
                .Where(c => c.Status == ClaimStatus.Approved)
                .Sum(c => c.Amount ?? 0),
        };

        return Result<DashboardSummaryDto>.Success(summary);
    }

    public async Task<Result<ClaimResponseDto>> CreateClaimAsync(CreateClaimDto dto, string userId)
    {
        var claimNumber = await GenerateClaimNumberAsync();

        var claim = new Claim
        {
            ClaimNumber = claimNumber,
            Title = $"{dto.ClaimType} - {dto.FullName}",
            Status = ClaimStatus.Submitted,
            ClaimType = dto.ClaimType,
            UserId = userId,

            FullName = dto.FullName,
            ClaimantType = dto.ClaimantType,
            PolicyNumber = dto.PolicyNumber,

            VinNumber = dto.VinNumber,
            VehicleRegistrationNumber = dto.VehicleRegistrationNumber,
            VehicleModel = dto.VehicleModel,

            IncidentDate = dto.IncidentDate,
            IncidentLocation = dto.IncidentLocation,
            IncidentDescription = dto.IncidentDescription,

            PolicyStatus = dto.PolicyStatus,
            PolicyValidUntil = dto.PolicyValidUntil,

            Amount = dto.Amount,
            ChatThreadId = dto.ChatThreadId,
        };

        _context.Claims.Add(claim);
        await _context.SaveChangesAsync();

        await NotifyMissingUploadsAsync(claim, userId);

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    public async Task<Result<ClaimResponseDto>> CreateClaimFromChatAsync(
        CreateClaimFromChatDto dto, string userId)
    {
        var claimNumber = string.IsNullOrWhiteSpace(dto.ClaimNumber)
            ? await GenerateClaimNumberAsync()
            : dto.ClaimNumber.Trim();

        var claimType = string.IsNullOrWhiteSpace(dto.ClaimType)
            ? "Vehicle"
            : dto.ClaimType;
        var fullName = string.IsNullOrWhiteSpace(dto.FullName)
            ? "Chat Submission"
            : dto.FullName;
        var policyNumber = string.IsNullOrWhiteSpace(dto.PolicyNumber)
            ? (dto.ExternalReference ?? "UNKNOWN")
            : dto.PolicyNumber;
        var incidentDate = dto.IncidentDate ?? DateTime.UtcNow;

        var claim = new Claim
        {
            ClaimNumber = claimNumber,
            Title = $"{claimType} - {fullName}",
            Status = ClaimStatus.Pending,
            ClaimType = claimType,
            UserId = userId,

            FullName = fullName,
            ClaimantType = dto.ClaimantType,
            PolicyNumber = policyNumber,

            VinNumber = dto.VinNumber,
            VehicleRegistrationNumber = dto.VehicleRegistrationNumber,
            VehicleModel = dto.VehicleModel,

            IncidentDate = incidentDate,
            IncidentLocation = dto.IncidentLocation,
            IncidentDescription = dto.IncidentDescription,

            PolicyStatus = dto.PolicyStatus,
            PolicyValidUntil = dto.PolicyValidUntil,

            Amount = dto.Amount,
            IdentityVerified = dto.IdentityVerified,
            ChatThreadId = dto.ChatThreadId,
        };

        _context.Claims.Add(claim);
        await _context.SaveChangesAsync();

        await NotifyMissingUploadsAsync(claim, userId);

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    public async Task<Result<List<ClaimResponseDto>>> GetUserClaimsAsync(string userId)
    {
        var claims = await _context.Claims
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

        return Result<List<ClaimResponseDto>>.Success(claims.Select(MapToDto).ToList());
    }

    public async Task<Result<ClaimResponseDto>> GetClaimByIdAsync(Guid claimId, string userId)
    {
        var claim = await _context.Claims
            .FirstOrDefaultAsync(c => c.Id == claimId && c.UserId == userId);

        if (claim is null)
            return Result<ClaimResponseDto>.Failure("Claim not found.");

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    public async Task<Result<ClaimResponseDto>> UpdateAccidentInfoAsync(
        Guid claimId,
        string userId,
        UpdateAccidentInfoDto dto)
    {
        var claim = await _context.Claims
            .FirstOrDefaultAsync(c => c.Id == claimId && c.UserId == userId);

        if (claim is null)
            return Result<ClaimResponseDto>.Failure("Claim not found.");

        if (claim.Status != ClaimStatus.Pending)
            return Result<ClaimResponseDto>.Failure(
                "Accident information can only be edited while the claim is pending.");

        claim.IncidentDate = dto.IncidentDate;
        claim.IncidentLocation = string.IsNullOrWhiteSpace(dto.IncidentLocation)
            ? null
            : dto.IncidentLocation.Trim();
        claim.IncidentDescription = string.IsNullOrWhiteSpace(dto.IncidentDescription)
            ? null
            : dto.IncidentDescription.Trim();

        await _context.SaveChangesAsync();

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    public async Task<Result<ClaimResponseDto>> UpdateClaimNumberAsync(
        Guid claimId,
        string userId,
        UpdateClaimNumberDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.ClaimNumber))
            return Result<ClaimResponseDto>.Failure("ClaimNumber is required.");

        var claim = await _context.Claims
            .FirstOrDefaultAsync(c => c.Id == claimId && c.UserId == userId);

        if (claim is null)
            return Result<ClaimResponseDto>.Failure("Claim not found.");

        claim.ClaimNumber = dto.ClaimNumber.Trim();
        await _context.SaveChangesAsync();

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    public async Task<Result<ClaimResponseDto>> UpdateClaimStatusAsync(
        Guid claimId,
        UpdateClaimStatusDto dto)
    {
        var claim = await _context.Claims.FirstOrDefaultAsync(c => c.Id == claimId);
        if (claim is null)
            return Result<ClaimResponseDto>.Failure("Claim not found.");

        if (claim.Status == dto.Status)
            return Result<ClaimResponseDto>.Success(MapToDto(claim));

        claim.Status = dto.Status;
        await _context.SaveChangesAsync();

        var (title, message, templateKey) = BuildStatusNotification(claim, dto);
        var noteSuffix = string.IsNullOrWhiteSpace(dto.Note) ? string.Empty : " " + dto.Note;
        await _notificationService.CreateAndPushAsync(
            userId: claim.UserId,
            title: title,
            message: message,
            actionType: "claim_status_changed",
            claimId: claim.Id,
            templateKey: templateKey,
            templateParams: templateKey is null
                ? null
                : new Dictionary<string, string>
                {
                    ["claimNumber"] = claim.ClaimNumber,
                    ["noteSuffix"] = noteSuffix,
                });

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    private static (string Title, string Message, string? TemplateKey) BuildStatusNotification(
        Claim claim, UpdateClaimStatusDto dto)
    {
        var (statusText, templateKey) = dto.Status switch
        {
            ClaimStatus.InReview => ("is now under review", "claim.status.inReview"),
            ClaimStatus.Approved => ("has been approved", "claim.status.approved"),
            ClaimStatus.Rejected => ("has been rejected", "claim.status.rejected"),
            ClaimStatus.Closed => ("has been closed", (string?)null),
            ClaimStatus.Submitted => ("has been submitted", (string?)null),
            ClaimStatus.Pending => ("is pending", (string?)null),
            ClaimStatus.Draft => ("was reverted to draft", (string?)null),
            _ => ($"status changed to {dto.Status}", (string?)null),
        };

        var title = $"Claim {claim.ClaimNumber} updated";
        var message = string.IsNullOrWhiteSpace(dto.Note)
            ? $"Your claim {statusText}."
            : $"Your claim {statusText}. {dto.Note}";

        return (title, message, templateKey);
    }

    private async Task NotifyMissingUploadsAsync(Claim claim, string userId)
    {
        // Pick up docs already bound to the claim, plus docs uploaded during
        // chat that share the claim's ChatThreadId but haven't been attached yet
        // (the /claim-documents/attach call usually follows claim creation).
        var query = _context.ClaimDocuments
            .Where(d => d.UserId == userId &&
                (d.ClaimId == claim.Id ||
                    (claim.ChatThreadId != null
                        && d.ChatThreadId == claim.ChatThreadId
                        && d.ClaimId == null)));

        var photoCount = await query.CountAsync(d => d.Kind == "Image");
        var docCount = await query.CountAsync(d => d.Kind != "Image");

        var missingPhotos = photoCount == 0;
        var missingDocs = docCount == 0;
        if (!missingPhotos && !missingDocs) return;

        string message;
        string templateKey;
        if (missingPhotos && missingDocs)
        {
            message = $"Please upload photos and supporting documents to complete your claim {claim.ClaimNumber}.";
            templateKey = "claim.action.uploadPhotosAndDocs";
        }
        else if (missingPhotos)
        {
            message = $"Please upload photos of the damage to complete your claim {claim.ClaimNumber}.";
            templateKey = "claim.action.uploadPhotos";
        }
        else
        {
            message = $"Please upload supporting documents to complete your claim {claim.ClaimNumber}.";
            templateKey = "claim.action.uploadDocs";
        }

        await _notificationService.CreateAndPushAsync(
            userId: userId,
            title: "Action Required",
            message: message,
            actionType: "upload_documents",
            claimId: claim.Id,
            actionUrl: $"/claims/{claim.Id}/documents",
            templateKey: templateKey,
            templateParams: new Dictionary<string, string>
            {
                ["claimNumber"] = claim.ClaimNumber,
            });
    }

    private async Task<string> GenerateClaimNumberAsync()
    {
        var today = DateTime.UtcNow;
        var prefix = $"CLM-{today:yyyyMMdd}";

        var todayCount = await _context.Claims
            .CountAsync(c => c.ClaimNumber.StartsWith(prefix));

        return $"{prefix}-{(todayCount + 1):D4}";
    }

    private static ClaimResponseDto MapToDto(Claim claim)
    {
        return new ClaimResponseDto
        {
            Id = claim.Id,
            ClaimNumber = claim.ClaimNumber,
            Title = claim.Title,
            Status = claim.Status.ToString(),
            ClaimType = claim.ClaimType,
            FullName = claim.FullName,
            ClaimantType = claim.ClaimantType,
            PolicyNumber = claim.PolicyNumber,
            PolicyStatus = claim.PolicyStatus,
            PolicyValidUntil = claim.PolicyValidUntil,
            VehicleModel = claim.VehicleModel,
            VinNumber = claim.VinNumber,
            VehicleRegistrationNumber = claim.VehicleRegistrationNumber,
            IncidentLocation = claim.IncidentLocation,
            IncidentDate = claim.IncidentDate,
            IncidentDescription = claim.IncidentDescription,
            Amount = claim.Amount,
            IdentityVerified = claim.IdentityVerified,
            ChatThreadId = claim.ChatThreadId,
            CreatedAt = claim.CreatedAt,
            UpdatedAt = claim.UpdatedAt,
        };
    }
}
