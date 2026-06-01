using ClaimAI.Application.DTOs.AppVersions;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/app-versions")]
[AllowAnonymous]
public class AppVersionsController : ControllerBase
{
    private readonly IAppVersionService _service;

    public AppVersionsController(IAppVersionService service)
    {
        _service = service;
    }

    [HttpGet("latest")]
    public async Task<IActionResult> GetLatest([FromQuery] AppPlatform platform, CancellationToken cancellationToken)
    {
        var result = await _service.GetLatestAsync(platform, cancellationToken);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));
        return Ok(ApiResponse<AppVersionDto>.SuccessResponse(result.Data!));
    }

    [HttpPost("check")]
    public async Task<IActionResult> Check([FromBody] VersionCheckRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _service.CheckAsync(request, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));
        return Ok(ApiResponse<VersionCheckResponseDto>.SuccessResponse(result.Data!));
    }
}
