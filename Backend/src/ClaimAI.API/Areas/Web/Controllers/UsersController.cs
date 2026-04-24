using System.Security.Claims;
using ClaimAI.Application.DTOs.Auth;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Interfaces.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IGenericRepository<UserProfile> _profileRepository;
    private readonly IAuthService _authService;

    public UsersController(
        UserManager<ApplicationUser> userManager,
        IGenericRepository<UserProfile> profileRepository,
        IAuthService authService)
    {
        _userManager = userManager;
        _profileRepository = profileRepository;
        _authService = authService;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user is null)
            return NotFound(ApiResponse<object>.FailResponse("User not found.", 404));

        var userProfile = (await _profileRepository.FindAsync(p => p.UserId == userId)).FirstOrDefault();
        var roles = await _userManager.GetRolesAsync(user);

        var profile = new
        {
            user.Id,
            user.Email,
            FirstName = userProfile?.FirstName ?? string.Empty,
            LastName = userProfile?.LastName ?? string.Empty,
            FullName = $"{userProfile?.FirstName} {userProfile?.LastName}".Trim(),
            user.EmailConfirmed,
            IsActive = userProfile?.IsActive ?? false,
            Roles = roles
        };

        return Ok(ApiResponse<object>.SuccessResponse(profile));
    }

    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var result = await _authService.ChangePasswordAsync(userId, request);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }
}
