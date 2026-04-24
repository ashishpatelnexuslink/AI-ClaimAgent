using ClaimAI.Application.DTOs.Auth;
using ClaimAI.Application.DTOs.Mobile.Auth;
using ClaimAI.Domain.Common;

namespace ClaimAI.Application.Interfaces;

public interface IAuthService
{
    Task<Result<AuthResponseDto>> LoginAsync(LoginRequestDto request);
    Task<Result> RegisterAsync(RegisterRequestDto request);
    Task<Result<AuthResponseDto>> RefreshTokenAsync(RefreshTokenRequestDto request);
    Task<Result> ConfirmEmailAsync(string userId, string token);
    Task<Result> ForgotPasswordAsync(string email);
    Task<Result> ResetPasswordAsync(string email, string token, string newPassword);
    Task<Result> ChangePasswordAsync(string userId, ChangePasswordDto request);
    Task<Result<SendOtpResponseDto>> SendOtpAsync(string phoneNumber);
    Task<Result<AuthResponseDto>> VerifyOtpAsync(string phoneNumber, string otp);
}
