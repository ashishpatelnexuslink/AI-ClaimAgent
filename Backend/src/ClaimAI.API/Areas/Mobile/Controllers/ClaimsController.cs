using System.Security.Claims;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.Claims;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/[controller]")]
[Authorize]
public class ClaimsController : ControllerBase
{
    private readonly IClaimsService _claimsService;

    public ClaimsController(IClaimsService claimsService)
    {
        _claimsService = claimsService;
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetDashboardSummary()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _claimsService.GetDashboardSummaryAsync(userId);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<DashboardSummaryDto>.SuccessResponse(result.Data!));
    }

    [HttpPost]
    public async Task<IActionResult> CreateClaim([FromBody] CreateClaimDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _claimsService.CreateClaimAsync(dto, userId);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Created(string.Empty, ApiResponse<ClaimResponseDto>.SuccessResponse(result.Data!));
    }

    [HttpPost("from-chat")]
    public async Task<IActionResult> CreateClaimFromChat([FromBody] CreateClaimFromChatDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _claimsService.CreateClaimFromChatAsync(dto, userId);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Created(string.Empty, ApiResponse<ClaimResponseDto>.SuccessResponse(result.Data!));
    }

    [HttpGet]
    public async Task<IActionResult> GetUserClaims()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _claimsService.GetUserClaimsAsync(userId);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<List<ClaimResponseDto>>.SuccessResponse(result.Data!));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetClaimById(Guid id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _claimsService.GetClaimByIdAsync(id, userId);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<ClaimResponseDto>.SuccessResponse(result.Data!));
    }

    [HttpPut("{id:guid}/accident-info")]
    public async Task<IActionResult> UpdateAccidentInfo(
        Guid id,
        [FromBody] UpdateAccidentInfoDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _claimsService.UpdateAccidentInfoAsync(id, userId, dto);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<ClaimResponseDto>.SuccessResponse(result.Data!));
    }
}
