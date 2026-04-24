using System.Security.Claims;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.ClaimDocuments;
using ClaimAI.Domain.Entities;
using ClaimAI.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/claim-documents")]
[Authorize]
public class ClaimDocumentsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _env;

    private static readonly string[] AllowedImageTypes =
        { "image/jpeg", "image/png", "image/webp", "image/gif" };

    private static readonly string[] AllowedDocTypes =
        {
            "image/jpeg", "image/png", "image/webp",
            "application/pdf",
            "application/msword",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        };

    private const long MaxFileSize = 15 * 1024 * 1024; // 15 MB

    public ClaimDocumentsController(ApplicationDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    [HttpPost]
    [RequestSizeLimit(20 * 1024 * 1024)]
    public async Task<IActionResult> Upload(
        IFormFile file,
        [FromForm] string? kind,
        [FromForm] string? category,
        [FromForm] string? chatThreadId)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null) return Unauthorized();

        if (file is null || file.Length == 0)
            return BadRequest(ApiResponse<object>.FailResponse("No file uploaded."));

        if (file.Length > MaxFileSize)
            return BadRequest(ApiResponse<object>.FailResponse("File size must not exceed 15 MB."));

        var normalisedKind = string.Equals(kind, "Image", StringComparison.OrdinalIgnoreCase)
            ? "Image"
            : "Document";

        var allowed = normalisedKind == "Image" ? AllowedImageTypes : AllowedDocTypes;
        if (!allowed.Contains(file.ContentType))
            return BadRequest(ApiResponse<object>.FailResponse(
                $"Content type '{file.ContentType}' is not allowed for {normalisedKind}."));

        var uploadsRoot = _env.WebRootPath
            ?? Path.Combine(_env.ContentRootPath, "wwwroot");
        var uploadsDir = Path.Combine(uploadsRoot, "uploads", "claim-documents");
        Directory.CreateDirectory(uploadsDir);

        var ext = Path.GetExtension(file.FileName);
        var storedName = $"{Guid.NewGuid()}{ext}";
        var diskPath = Path.Combine(uploadsDir, storedName);

        await using (var stream = new FileStream(diskPath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var relativeUrl = $"/uploads/claim-documents/{storedName}";

        var doc = new ClaimDocument
        {
            UserId = userId,
            ChatThreadId = chatThreadId,
            FileName = file.FileName,
            StoredFileName = storedName,
            RelativeUrl = relativeUrl,
            ContentType = file.ContentType,
            FileSize = file.Length,
            Kind = normalisedKind,
            Category = string.IsNullOrWhiteSpace(category) ? null : category.Trim(),
        };
        _context.ClaimDocuments.Add(doc);
        await _context.SaveChangesAsync();

        var dto = new ClaimDocumentDto
        {
            Id = doc.Id.ToString(),
            ClaimId = doc.ClaimId?.ToString(),
            FileName = doc.FileName,
            Url = $"{Request.Scheme}://{Request.Host}{relativeUrl}",
            ContentType = doc.ContentType,
            FileSize = doc.FileSize,
            Kind = doc.Kind,
            Category = doc.Category,
            CreatedAt = doc.CreatedAt,
        };

        return Ok(ApiResponse<ClaimDocumentDto>.SuccessResponse(dto));
    }

    [HttpGet("by-claim/{claimId:guid}")]
    public async Task<IActionResult> GetByClaim(Guid claimId)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null) return Unauthorized();

        var claimExists = await _context.Claims
            .AnyAsync(c => c.Id == claimId && c.UserId == userId);
        if (!claimExists)
            return NotFound(ApiResponse<object>.FailResponse("Claim not found."));

        var docs = await _context.ClaimDocuments
            .Where(d => d.ClaimId == claimId && d.UserId == userId)
            .OrderBy(d => d.CreatedAt)
            .ToListAsync();

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
    public async Task<IActionResult> Delete(Guid id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null) return Unauthorized();

        var doc = await _context.ClaimDocuments
            .FirstOrDefaultAsync(d => d.Id == id && d.UserId == userId);
        if (doc is null)
            return NotFound(ApiResponse<object>.FailResponse("Document not found."));

        _context.ClaimDocuments.Remove(doc);
        await _context.SaveChangesAsync();

        return Ok(ApiResponse<object>.SuccessResponse(new { deleted = true }));
    }

    [HttpPost("attach")]
    public async Task<IActionResult> Attach([FromBody] AttachClaimDocumentsRequestDto request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null) return Unauthorized();

        if (!Guid.TryParse(request.ClaimId, out var claimId))
            return BadRequest(ApiResponse<object>.FailResponse("Invalid ClaimId format."));

        if (request.DocumentIds is null || request.DocumentIds.Count == 0)
            return BadRequest(ApiResponse<object>.FailResponse("DocumentIds are required."));

        var claimExists = await _context.Claims
            .AnyAsync(c => c.Id == claimId && c.UserId == userId);
        if (!claimExists)
            return BadRequest(ApiResponse<object>.FailResponse("Claim not found."));

        var ids = request.DocumentIds
            .Select(id => Guid.TryParse(id, out var g) ? g : Guid.Empty)
            .Where(g => g != Guid.Empty)
            .ToList();

        var docs = await _context.ClaimDocuments
            .Where(d => ids.Contains(d.Id) && d.UserId == userId && d.ClaimId == null)
            .ToListAsync();

        foreach (var d in docs)
        {
            d.ClaimId = claimId;
        }

        await _context.SaveChangesAsync();

        return Ok(ApiResponse<AttachClaimDocumentsResponseDto>.SuccessResponse(
            new AttachClaimDocumentsResponseDto { AttachedCount = docs.Count }));
    }
}
