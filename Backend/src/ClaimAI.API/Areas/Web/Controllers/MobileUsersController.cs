using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.MobileUsers;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/mobile-users")]
[Authorize]
public class MobileUsersController : ControllerBase
{
    private readonly IMobileUserService _mobileUserService;

    public MobileUsersController(IMobileUserService mobileUserService)
    {
        _mobileUserService = mobileUserService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var result = await _mobileUserService.GetAllAsync(cancellationToken);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<List<MobileUserDto>>.SuccessResponse(result.Data!));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(string id, CancellationToken cancellationToken)
    {
        var result = await _mobileUserService.GetByIdAsync(id, cancellationToken);
        if (!result.Succeeded)
            return NotFound(ApiResponse<object>.FailResponse(result.Errors, 404));

        return Ok(ApiResponse<MobileUserDto>.SuccessResponse(result.Data!));
    }
}
