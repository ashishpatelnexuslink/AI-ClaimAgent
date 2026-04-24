using System.Security.Claims;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.Chat;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/[controller]")]
[Authorize]
public class ConversationsController : ControllerBase
{
    private readonly IChatService _chatService;

    public ConversationsController(IChatService chatService)
    {
        _chatService = chatService;
    }

    [HttpPost]
    public async Task<IActionResult> SaveConversation([FromBody] SaveConversationRequestDto request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _chatService.SaveConversationAsync(userId, request);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<SaveConversationResponseDto>.SuccessResponse(result.Data!));
    }
}
