using System.Security.Claims;
using ClaimAI.API.Extensions;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.Notifications;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/[controller]")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet("pending-actions")]
    public async Task<IActionResult> GetPendingActions()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var locale = LocaleResolver.ResolveLanguage(Request.Headers.AcceptLanguage.ToString());
        var result = await _notificationService.GetPendingActionsAsync(userId, locale);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<List<PendingActionDto>>.SuccessResponse(result.Data!));
    }

    [HttpPut("{id:guid}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _notificationService.MarkAsReadAsync(id, userId);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }

    [HttpPost("devices/register")]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _notificationService.RegisterDeviceAsync(userId, dto);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }

    [HttpDelete("devices/{token}")]
    public async Task<IActionResult> UnregisterDevice(string token)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _notificationService.UnregisterDeviceAsync(userId, token);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }
}
