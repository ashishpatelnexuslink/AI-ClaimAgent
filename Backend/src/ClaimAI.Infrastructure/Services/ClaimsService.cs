using System.Text.Json;
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

    public ClaimsService(ApplicationDbContext context)
    {
        _context = context;
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
            PatientName = dto.PatientName,
            PolicyNumber = dto.PolicyNumber,

            VehicleNumber = dto.VehicleNumber,
            VinNumber = dto.VinNumber,
            VehicleRegistrationNumber = dto.VehicleRegistrationNumber,
            VehicleModel = dto.VehicleModel,

            IncidentDate = dto.IncidentDate,
            IncidentLocation = dto.IncidentLocation,
            IncidentDescription = dto.IncidentDescription,
            Description = dto.Description,

            CoverageType = dto.CoverageType,
            PolicyStatus = dto.PolicyStatus,
            PolicyValidUntil = dto.PolicyValidUntil,

            Amount = dto.Amount,
            ChatThreadId = dto.ChatThreadId,

            AdditionalData = SerializeExtras(dto.ExtraData),
        };

        _context.Claims.Add(claim);
        await _context.SaveChangesAsync();

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    public async Task<Result<ClaimResponseDto>> CreateClaimFromChatAsync(
        CreateClaimFromChatDto dto, string userId)
    {
        var claimNumber = await GenerateClaimNumberAsync();

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

        var extras = dto.ExtraData ?? new Dictionary<string, JsonElement>();
        if (!string.IsNullOrWhiteSpace(dto.ExternalReference) &&
            !extras.ContainsKey("externalReference"))
        {
            extras["externalReference"] = JsonSerializer.SerializeToElement(dto.ExternalReference);
        }

        var claim = new Claim
        {
            ClaimNumber = claimNumber,
            Title = $"{claimType} - {fullName}",
            Status = ClaimStatus.Pending,
            ClaimType = claimType,
            UserId = userId,

            FullName = fullName,
            ClaimantType = dto.ClaimantType,
            PatientName = dto.PatientName,
            PolicyNumber = policyNumber,

            VehicleNumber = dto.VehicleNumber,
            VinNumber = dto.VinNumber,
            VehicleRegistrationNumber = dto.VehicleRegistrationNumber,
            VehicleModel = dto.VehicleModel,

            IncidentDate = incidentDate,
            IncidentLocation = dto.IncidentLocation,
            IncidentDescription = dto.IncidentDescription,
            Description = dto.Description,

            CoverageType = dto.CoverageType,
            PolicyStatus = dto.PolicyStatus,
            PolicyValidUntil = dto.PolicyValidUntil,

            Amount = dto.Amount,
            IdentityVerified = dto.IdentityVerified,
            VehiclePhotosCount = dto.VehiclePhotosCount ?? 0,
            DamagePhotosCount = dto.DamagePhotosCount ?? 0,
            LicensePhotosCount = dto.LicensePhotosCount ?? 0,
            PoliceReportCount = dto.PoliceReportCount ?? 0,
            RepairBillCount = dto.RepairBillCount ?? 0,
            SupportingDocsCount = dto.SupportingDocsCount ?? 0,
            ChatThreadId = dto.ChatThreadId,

            AdditionalData = SerializeExtras(extras),
        };

        _context.Claims.Add(claim);
        await _context.SaveChangesAsync();

        return Result<ClaimResponseDto>.Success(MapToDto(claim));
    }

    /// Any JSON keys in the incoming payload that don't map to a declared
    /// property on <see cref="CreateClaimDto"/> get serialized back to JSON
    /// and stored verbatim so the admin can always replay what the chatbot
    /// extracted — even fields we haven't modeled yet.
    private static string? SerializeExtras(Dictionary<string, JsonElement>? extras)
    {
        if (extras is null || extras.Count == 0)
            return null;
        return JsonSerializer.Serialize(extras);
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
            PatientName = claim.PatientName,
            PolicyNumber = claim.PolicyNumber,
            CoverageType = claim.CoverageType,
            PolicyStatus = claim.PolicyStatus,
            PolicyValidUntil = claim.PolicyValidUntil,
            VehicleModel = claim.VehicleModel,
            VehicleNumber = claim.VehicleNumber,
            VinNumber = claim.VinNumber,
            VehicleRegistrationNumber = claim.VehicleRegistrationNumber,
            IncidentLocation = claim.IncidentLocation,
            IncidentDate = claim.IncidentDate,
            IncidentDescription = claim.IncidentDescription,
            Description = claim.Description,
            Amount = claim.Amount,
            IdentityVerified = claim.IdentityVerified,
            VehiclePhotosCount = claim.VehiclePhotosCount,
            DamagePhotosCount = claim.DamagePhotosCount,
            LicensePhotosCount = claim.LicensePhotosCount,
            PoliceReportCount = claim.PoliceReportCount,
            RepairBillCount = claim.RepairBillCount,
            SupportingDocsCount = claim.SupportingDocsCount,
            ChatThreadId = claim.ChatThreadId,
            AdditionalData = claim.AdditionalData,
            CreatedAt = claim.CreatedAt,
            UpdatedAt = claim.UpdatedAt,
        };
    }
}
