using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Templates;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/templates")]
[Authorize]
public class TemplatesController : ControllerBase
{
    private readonly ITemplateService _templateService;

    public TemplatesController(ITemplateService templateService)
    {
        _templateService = templateService;
    }

    /// <summary>
    /// Returns the single active template (with full child tree) so the mobile
    /// claim-summary page can render photo + document groups dynamically. The
    /// mobile app has no company / insurance-type context, so we just return
    /// whatever template is currently flagged Active.
    ///
    /// Honors the <c>Accept-Language</c> header — when set to a locale that
    /// has translation rows (e.g. <c>de</c>), Label / Instruction values are
    /// substituted; missing translations fall back to seed English.
    /// </summary>
    [HttpGet("active")]
    public async Task<IActionResult> GetActive(CancellationToken cancellationToken)
    {
        var language = ResolveLanguage(Request.Headers.AcceptLanguage.ToString());
        var result = await _templateService.GetSingleActiveAsync(language, cancellationToken);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));

        return Ok(ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!));
    }

    /// <summary>
    /// Picks the first language tag out of an <c>Accept-Language</c> header
    /// value (e.g. <c>"de-CH,de;q=0.9,en;q=0.8"</c> → <c>"de-CH"</c>). Returns
    /// <c>null</c> when the header is missing/blank so the service falls back
    /// to the seed English values.
    /// </summary>
    private static string? ResolveLanguage(string? acceptLanguage)
    {
        if (string.IsNullOrWhiteSpace(acceptLanguage)) return null;
        var first = acceptLanguage.Split(',')[0].Split(';')[0].Trim();
        return string.IsNullOrEmpty(first) ? null : first;
    }
}
