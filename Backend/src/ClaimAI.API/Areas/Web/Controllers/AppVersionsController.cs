using ClaimAI.Application.DTOs.AppVersions;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/app-versions")]
[Authorize]
public class AppVersionsController : ControllerBase
{
    private readonly IAppVersionService _service;

    public AppVersionsController(IAppVersionService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] AppPlatform? platform, CancellationToken cancellationToken)
    {
        var result = await _service.GetAllAsync(platform, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));
        return Ok(ApiResponse<List<AppVersionDto>>.SuccessResponse(result.Data!));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));
        return Ok(ApiResponse<AppVersionDto>.SuccessResponse(result.Data!));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateAppVersionDto request, CancellationToken cancellationToken)
    {
        var result = await _service.CreateAsync(request, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));
        return Ok(ApiResponse<AppVersionDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateAppVersionDto request, CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(id, request, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));
        return Ok(ApiResponse<AppVersionDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(id, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));
        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }
}
