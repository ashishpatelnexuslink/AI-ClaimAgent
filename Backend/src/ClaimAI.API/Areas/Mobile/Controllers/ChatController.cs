using System.Security.Claims;
using ClaimAI.Application.DTOs.AiMl;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.Chat;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly ITemplateService _templateService;

    public ChatController(IChatService chatService, ITemplateService templateService)
    {
        _chatService = chatService;
        _templateService = templateService;
    }

    /// <summary>
    /// Mobile app calls this when the user enters chat or voice mode. Resolves the
    /// active template (by id, or by company + insurance type) and pushes its
    /// settings to the AI/ML <c>/config</c> endpoint so the agent is primed.
    /// </summary>
    [HttpPost("init-template")]
    public async Task<IActionResult> InitTemplate([FromBody] InitChatTemplateRequestDto request, CancellationToken cancellationToken)
    {
        if (request.TemplateId.HasValue)
        {
            var byId = await _templateService.SyncToAiAsync(request.TemplateId.Value, cancellationToken);
            return byId.Succeeded
                ? Ok(ApiResponse<TemplateConfigResponseDto>.SuccessResponse(byId.Data!, byId.Message))
                : BadRequest(ApiResponse<object>.FailResponse(byId.Errors));
        }

        if (string.IsNullOrWhiteSpace(request.CompanyName) || !request.InsuranceType.HasValue)
            return BadRequest(ApiResponse<object>.FailResponse(
                new List<string> { "Provide either templateId, or companyName + insuranceType." }));

        var byActive = await _templateService.SyncActiveToAiAsync(
            request.CompanyName, request.InsuranceType.Value, cancellationToken);

        return byActive.Succeeded
            ? Ok(ApiResponse<TemplateConfigResponseDto>.SuccessResponse(byActive.Data!, byActive.Message))
            : BadRequest(ApiResponse<object>.FailResponse(byActive.Errors));
    }

    [HttpGet("suggestions")]
    public async Task<IActionResult> GetSuggestions([FromQuery] string claimId)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _chatService.GetSuggestionsAsync(userId, claimId);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<List<string>>.SuccessResponse(result.Data!));
    }
}
