using ClaimAI.API.Extensions;
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
        var language = LocaleResolver.ResolveLanguage(Request.Headers.AcceptLanguage.ToString());
        var result = await _templateService.GetSingleActiveAsync(language, cancellationToken);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));

        return Ok(ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!));
    }
}
