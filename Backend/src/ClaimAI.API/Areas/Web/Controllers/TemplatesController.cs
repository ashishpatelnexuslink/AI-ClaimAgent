using ClaimAI.Application.DTOs.AiMl;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Templates;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/templates")]
[Authorize]
public class TemplatesController : ControllerBase
{
    private readonly ITemplateService _templateService;

    public TemplatesController(ITemplateService templateService)
    {
        _templateService = templateService;
    }

    /// <summary>Lists templates with optional filters and paging.</summary>
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] TemplateListQuery query, CancellationToken cancellationToken)
    {
        var result = await _templateService.ListAsync(query, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<PagedResult<TemplateListItemDto>>.SuccessResponse(result.Data!));
    }

    /// <summary>Returns the active template (with full tree) for a company + insurance type pair.</summary>
    [HttpGet("active")]
    public async Task<IActionResult> GetActive(
        [FromQuery] string company,
        [FromQuery] InsuranceType type,
        CancellationToken cancellationToken)
    {
        var result = await _templateService.GetActiveAsync(company, type, cancellationToken);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));

        return Ok(ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!));
    }

    /// <summary>Returns a template with every child collection eagerly loaded.</summary>
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var result = await _templateService.GetByIdAsync(id, cancellationToken);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));

        return Ok(ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!));
    }

    /// <summary>Creates a new template tree (always persisted as Draft).</summary>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateTemplateDto dto, CancellationToken cancellationToken)
    {
        var result = await _templateService.CreateAsync(dto, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Created(string.Empty, ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!, result.Message, 201));
    }

    /// <summary>Replaces a Draft template's scalar fields and child collections wholesale.</summary>
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateTemplateDto dto, CancellationToken cancellationToken)
    {
        var result = await _templateService.UpdateAsync(id, dto, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!, result.Message));
    }

    /// <summary>Deep-copies the template into a new Draft row with an incremented version.</summary>
    [HttpPost("{id:guid}/clone")]
    public async Task<IActionResult> Clone(Guid id, CancellationToken cancellationToken)
    {
        var result = await _templateService.CloneAsync(id, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Created(string.Empty, ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!, result.Message, 201));
    }

    /// <summary>Activates this version; archives the previous active row (if any) for the same company + type.</summary>
    [HttpPost("{id:guid}/activate")]
    public async Task<IActionResult> Activate(Guid id, CancellationToken cancellationToken)
    {
        var result = await _templateService.ActivateAsync(id, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<TemplateDetailDto>.SuccessResponse(result.Data!, result.Message));
    }

    /// <summary>POSTs the template settings to the AI/ML <c>/config</c> endpoint.</summary>
    [HttpPost("{id:guid}/sync-ai")]
    public async Task<IActionResult> SyncToAi(Guid id, CancellationToken cancellationToken)
    {
        var result = await _templateService.SyncToAiAsync(id, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<TemplateConfigResponseDto>.SuccessResponse(result.Data!, result.Message));
    }

    /// <summary>Soft-deletes a Draft template (and its children).</summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        var result = await _templateService.DeleteAsync(id, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }
}
