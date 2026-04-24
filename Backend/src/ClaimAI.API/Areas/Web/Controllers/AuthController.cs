using ClaimAI.Application.DTOs.Auth;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Web.Controllers;

[ApiController]
[Route("api/web/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
    {
        var result = await _authService.LoginAsync(request);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequestDto request)
    {
        var result = await _authService.RegisterAsync(request);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }

    [HttpPost("refresh-token")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequestDto request)
    {
        var result = await _authService.RefreshTokenAsync(request);
        if (!result.Succeeded)
            return Unauthorized(ApiResponse<object>.FailResponse(result.Errors, 401));

        return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpGet("confirm-email")]
    public async Task<IActionResult> ConfirmEmail([FromQuery] string userId, [FromQuery] string token)
    {
        var result = await _authService.ConfirmEmailAsync(userId, token);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] string email)
    {
        var result = await _authService.ForgotPasswordAsync(email);
        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(
        [FromQuery] string email, [FromQuery] string token, [FromBody] string newPassword)
    {
        var result = await _authService.ResetPasswordAsync(email, token, newPassword);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, result.Message));
    }
}
