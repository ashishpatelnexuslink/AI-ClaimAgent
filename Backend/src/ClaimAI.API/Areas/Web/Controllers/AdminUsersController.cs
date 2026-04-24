using ClaimAI.Application.DTOs.Admin;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/admin-users")]
[Authorize]
public class AdminUsersController : ControllerBase
{
    private readonly IAdminUserService _adminUserService;

    public AdminUsersController(IAdminUserService adminUserService)
    {
        _adminUserService = adminUserService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var result = await _adminUserService.GetAllAsync(cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<List<AdminUserDto>>.SuccessResponse(result.Data!));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateAdminUserDto request, CancellationToken cancellationToken)
    {
        var result = await _adminUserService.CreateAsync(request, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<AdminUserDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] CreateAdminUserDto request, CancellationToken cancellationToken)
    {
        var result = await _adminUserService.CreateAsync(request, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<AdminUserDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateAdminUserDto request, CancellationToken cancellationToken)
    {
        var result = await _adminUserService.UpdateAsync(id, request, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<AdminUserDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id, CancellationToken cancellationToken)
    {
        var result = await _adminUserService.DeleteAsync(id, cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }
}
