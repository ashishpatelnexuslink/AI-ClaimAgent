using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.ClaimDocuments;
using ClaimAI.Application.DTOs.Web.Claims;
using ClaimAI.Domain.Enums;
using ClaimAI.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/claims")]
[Authorize]
public class ClaimsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ClaimsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> List(
        [FromQuery] AdminClaimListQuery query,
        CancellationToken cancellationToken)
    {
        var page = Math.Max(1, query.PageNumber);
        var size = Math.Clamp(query.PageSize, 1, 200);

        var q = from c in _context.Claims
                join p in _context.UserProfiles on c.UserId equals p.UserId into pj
                from p in pj.DefaultIfEmpty()
                select new { Claim = c, Profile = p };

        if (!string.IsNullOrWhiteSpace(query.Status) &&
            Enum.TryParse<ClaimStatus>(query.Status, ignoreCase: true, out var statusEnum))
        {
            q = q.Where(x => x.Claim.Status == statusEnum);
        }

        if (!string.IsNullOrWhiteSpace(query.Type))
        {
            var t = query.Type.Trim();
            q = q.Where(x => x.Claim.ClaimType == t);
        }

        if (query.FromDate.HasValue)
        {
            var from = query.FromDate.Value;
            q = q.Where(x => x.Claim.IncidentDate >= from || x.Claim.CreatedAt >= from);
        }

        if (query.ToDate.HasValue)
        {
            var to = query.ToDate.Value;
            q = q.Where(x => x.Claim.IncidentDate <= to || x.Claim.CreatedAt <= to);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var s = query.Search.Trim().ToLower();
            q = q.Where(x =>
                x.Claim.ClaimNumber.ToLower().Contains(s) ||
                (x.Claim.FullName != null && x.Claim.FullName.ToLower().Contains(s)) ||
                (x.Profile != null && (
                    x.Profile.FirstName.ToLower().Contains(s) ||
                    x.Profile.LastName.ToLower().Contains(s))) ||
                (x.Claim.VehicleNumber != null && x.Claim.VehicleNumber.ToLower().Contains(s)));
        }

        var totalCount = await q.CountAsync(cancellationToken);

        var rows = await q
            .OrderByDescending(x => x.Claim.CreatedAt)
            .Skip((page - 1) * size)
            .Take(size)
            .Select(x => new AdminClaimListItemDto
            {
                Id = x.Claim.Id,
                ClaimNumber = x.Claim.ClaimNumber,
                UserId = x.Claim.UserId,
                UserName = x.Profile != null
                    ? (x.Profile.FirstName + " " + x.Profile.LastName).Trim()
                    : (x.Claim.FullName ?? string.Empty),
                Type = x.Claim.ClaimType,
                Status = x.Claim.Status.ToString(),
                VehicleReg = x.Claim.VehicleRegistrationNumber ?? x.Claim.VehicleNumber,
                IncidentDate = x.Claim.IncidentDate,
                SubmittedAt = x.Claim.CreatedAt,
                UpdatedAt = x.Claim.UpdatedAt,
                Amount = x.Claim.Amount,
                AssignedTo = x.Claim.AssignedTo,
                ClaimantType = x.Claim.ClaimantType,
            })
            .ToListAsync(cancellationToken);

        var paged = new PagedResult<AdminClaimListItemDto>
        {
            Items = rows,
            TotalCount = totalCount,
            PageNumber = page,
            PageSize = size,
        };

        return Ok(ApiResponse<PagedResult<AdminClaimListItemDto>>.SuccessResponse(paged));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var row = await (from c in _context.Claims
                         join p in _context.UserProfiles on c.UserId equals p.UserId into pj
                         from p in pj.DefaultIfEmpty()
                         where c.Id == id
                         select new { Claim = c, Profile = p })
            .FirstOrDefaultAsync(cancellationToken);

        if (row is null)
            return NotFound(ApiResponse<object>.FailResponse("Claim not found."));

        var dto = new AdminClaimDetailDto
        {
            Id = row.Claim.Id,
            ClaimNumber = row.Claim.ClaimNumber,
            UserId = row.Claim.UserId,
            UserName = row.Profile != null
                ? (row.Profile.FirstName + " " + row.Profile.LastName).Trim()
                : (row.Claim.FullName ?? string.Empty),
            Type = row.Claim.ClaimType,
            Status = row.Claim.Status.ToString(),
            VehicleReg = row.Claim.VehicleRegistrationNumber ?? row.Claim.VehicleNumber,
            IncidentDate = row.Claim.IncidentDate,
            SubmittedAt = row.Claim.CreatedAt,
            UpdatedAt = row.Claim.UpdatedAt,
            Amount = row.Claim.Amount,
            AssignedTo = row.Claim.AssignedTo,
            ClaimantType = row.Claim.ClaimantType,
            Description = row.Claim.Description,
            FullName = row.Claim.FullName,
            PolicyNumber = row.Claim.PolicyNumber,
            VehicleModel = row.Claim.VehicleModel,
            VinNumber = row.Claim.VinNumber,
            VehicleRegistrationNumber = row.Claim.VehicleRegistrationNumber,
            IncidentLocation = row.Claim.IncidentLocation,
            IncidentDescription = row.Claim.IncidentDescription,
            CoverageType = row.Claim.CoverageType,
            PolicyStatus = row.Claim.PolicyStatus,
            PolicyValidUntil = row.Claim.PolicyValidUntil,
            IdentityVerified = row.Claim.IdentityVerified,
            VehiclePhotosCount = row.Claim.VehiclePhotosCount,
            DamagePhotosCount = row.Claim.DamagePhotosCount,
            LicensePhotosCount = row.Claim.LicensePhotosCount,
            PoliceReportCount = row.Claim.PoliceReportCount,
            RepairBillCount = row.Claim.RepairBillCount,
            AdditionalData = row.Claim.AdditionalData,
        };

        return Ok(ApiResponse<AdminClaimDetailDto>.SuccessResponse(dto));
    }

    [HttpGet("{id:guid}/documents")]
    public async Task<IActionResult> GetDocuments(Guid id, CancellationToken cancellationToken)
    {
        var claimExists = await _context.Claims.AnyAsync(c => c.Id == id, cancellationToken);
        if (!claimExists)
            return NotFound(ApiResponse<object>.FailResponse("Claim not found."));

        var docs = await _context.ClaimDocuments
            .Where(d => d.ClaimId == id)
            .OrderBy(d => d.CreatedAt)
            .ToListAsync(cancellationToken);

        var list = docs.Select(d => new ClaimDocumentDto
        {
            Id = d.Id.ToString(),
            ClaimId = d.ClaimId?.ToString(),
            FileName = d.FileName,
            Url = $"{Request.Scheme}://{Request.Host}{d.RelativeUrl}",
            ContentType = d.ContentType,
            FileSize = d.FileSize,
            Kind = d.Kind,
            Category = d.Category,
            CreatedAt = d.CreatedAt,
        }).ToList();

        return Ok(ApiResponse<List<ClaimDocumentDto>>.SuccessResponse(list));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var claim = await _context.Claims
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        if (claim is null)
            return NotFound(ApiResponse<object>.FailResponse("Claim not found."));

        // Detach any documents so deleting the claim doesn't blow up the FK.
        // ClaimDocument.ClaimId is already nullable with OnDelete(SetNull),
        // so EF will null out the FK on SaveChanges when we remove the claim.
        _context.Claims.Remove(claim);
        await _context.SaveChangesAsync(cancellationToken);

        return Ok(ApiResponse<object>.SuccessResponse(new { deleted = true }));
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(
        Guid id,
        [FromBody] UpdateClaimStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (!Enum.TryParse<ClaimStatus>(request.Status, ignoreCase: true, out var newStatus))
            return BadRequest(ApiResponse<object>.FailResponse($"Unknown status '{request.Status}'."));

        var claim = await _context.Claims
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        if (claim is null)
            return NotFound(ApiResponse<object>.FailResponse("Claim not found."));

        claim.Status = newStatus;
        await _context.SaveChangesAsync(cancellationToken);

        return Ok(ApiResponse<object>.SuccessResponse(new { id, status = newStatus.ToString() }));
    }
}
