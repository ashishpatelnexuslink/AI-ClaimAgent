using ClaimAI.Application.DTOs.Auth;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.Auth;
using ClaimAI.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("refresh-token")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequestDto request)
    {
        var result = await _authService.RefreshTokenAsync(request);
        if (!result.Succeeded)
            return Unauthorized(ApiResponse<object>.FailResponse(result.Errors, 401));

        return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpPost("send-otp")]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpRequestDto request)
    {
        var result = await _authService.SendOtpAsync(request.PhoneNumber);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<SendOtpResponseDto>.SuccessResponse(result.Data!, result.Message));
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestDto request)
    {
        var result = await _authService.VerifyOtpAsync(request.PhoneNumber, request.Otp);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(result.Errors));

        return Ok(ApiResponse<AuthResponseDto>.SuccessResponse(result.Data!, result.Message));
    }
}
