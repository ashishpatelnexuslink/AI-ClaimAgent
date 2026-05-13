using ClaimAI.Application.DTOs.Auth;
using ClaimAI.Application.DTOs.Mobile.Auth;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Constants;
using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Interfaces.Repositories;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Security.Claims;
using System.Security.Cryptography;

namespace ClaimAI.Application.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly ITokenService _tokenService;
    private readonly IEmailService _emailService;
    private readonly ISmsService _smsService;
    private readonly IGenericRepository<UserProfile> _profileRepository;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthService> _logger;

    private const int OtpLength = 6;
    private const int OtpExpiryMinutes = 5;
    private const int MaxOtpAttempts = 5;

    public AuthService(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        RoleManager<IdentityRole> roleManager,
        ITokenService tokenService,
        IEmailService emailService,
        ISmsService smsService,
        IGenericRepository<UserProfile> profileRepository,
        IConfiguration configuration,
        ILogger<AuthService> logger)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _roleManager = roleManager;
        _tokenService = tokenService;
        _emailService = emailService;
        _smsService = smsService;
        _profileRepository = profileRepository;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<Result<AuthResponseDto>> LoginAsync(LoginRequestDto request)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user is null)
            return Result<AuthResponseDto>.Failure("Invalid email or password.");

        var profile = (await _profileRepository.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
        if (profile is null || !profile.IsActive)
            return Result<AuthResponseDto>.Failure("Invalid email or password.");

        var result = await _signInManager.CheckPasswordSignInAsync(user, request.Password, lockoutOnFailure: true);

        if (result.IsLockedOut)
            return Result<AuthResponseDto>.Failure("Account is locked. Please try again later.");

        if (result.IsNotAllowed)
            return Result<AuthResponseDto>.Failure("Email not confirmed. Please confirm your email.");

        if (!result.Succeeded)
            return Result<AuthResponseDto>.Failure("Invalid email or password.");

        return await GenerateAuthResponseAsync(user);
    }

    public async Task<Result> RegisterAsync(RegisterRequestDto request)
    {
        var existingUser = await _userManager.FindByEmailAsync(request.Email);
        if (existingUser is not null)
            return Result.Failure("A user with this email already exists.");

        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
        };

        var result = await _userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
            return Result.Failure(result.Errors.Select(e => e.Description).ToList());

        // Create user profile
        var profile = new UserProfile
        {
            UserId = user.Id,
            FirstName = request.FirstName,
            LastName = request.LastName,
        };
        await _profileRepository.AddAsync(profile);

        var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
        await _emailService.SendEmailAsync(
            user.Email!,
            "Confirm your email",
            $"Please confirm your email using this token: {token}");

        return Result.Success("Registration successful. Please confirm your email.");
    }

    public async Task<Result<AuthResponseDto>> RefreshTokenAsync(RefreshTokenRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.AccessToken) || string.IsNullOrWhiteSpace(request.RefreshToken))
            return Result<AuthResponseDto>.Failure("Access token and refresh token are required.");

        var principal = _tokenService.GetPrincipalFromExpiredToken(request.AccessToken);
        if (principal is null)
            return Result<AuthResponseDto>.Failure("Invalid access token.");

        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Result<AuthResponseDto>.Failure("Invalid access token.");

        var user = await _userManager.FindByIdAsync(userId);
        if (user is null ||
            user.RefreshToken != request.RefreshToken ||
            user.RefreshTokenExpiryTime <= DateTime.UtcNow)
        {
            return Result<AuthResponseDto>.Failure("Invalid or expired refresh token.");
        }

        var profile = (await _profileRepository.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
        if (profile is null || !profile.IsActive)
            return Result<AuthResponseDto>.Failure("Account is deactivated.");

        return await GenerateAuthResponseAsync(user);
    }

    public async Task<Result> ConfirmEmailAsync(string userId, string token)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user is null)
            return Result.Failure("User not found.");

        var result = await _userManager.ConfirmEmailAsync(user, token);
        return result.Succeeded
            ? Result.Success("Email confirmed successfully.")
            : Result.Failure(result.Errors.Select(e => e.Description).ToList());
    }

    public async Task<Result> ForgotPasswordAsync(string email)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user is null)
            return Result.Success("If your email is registered, you will receive a reset link.");

        var token = await _userManager.GeneratePasswordResetTokenAsync(user);
        await _emailService.SendEmailAsync(
            email,
            "Reset your password",
            $"Use this token to reset your password: {token}");

        return Result.Success("If your email is registered, you will receive a reset link.");
    }

    public async Task<Result> ResetPasswordAsync(string email, string token, string newPassword)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user is null)
            return Result.Failure("Invalid request.");

        var result = await _userManager.ResetPasswordAsync(user, token, newPassword);
        return result.Succeeded
            ? Result.Success("Password reset successful.")
            : Result.Failure(result.Errors.Select(e => e.Description).ToList());
    }

    public async Task<Result> ChangePasswordAsync(string userId, ChangePasswordDto request)
    {
        var user = await _userManager.FindByIdAsync(userId);
        if (user is null)
            return Result.Failure("User not found.");

        var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        return result.Succeeded
            ? Result.Success("Password changed successfully.")
            : Result.Failure(result.Errors.Select(e => e.Description).ToList());
    }

    public async Task<Result<SendOtpResponseDto>> SendOtpAsync(string phoneNumber, string? country = null)
    {
        var isNewUser = false;
        var normalized = NormalizePhone(phoneNumber);

        // 1. Try exact UserName match (original OTP-registered users)
        var user = await _userManager.FindByNameAsync(phoneNumber);

        // 2. Fallback: match by PhoneNumber (handles profile-updated users whose UserName changed to email)
        user ??= _userManager.Users.AsEnumerable()
            .FirstOrDefault(u => NormalizePhone(u.PhoneNumber) == normalized);

        if (user is null)
        {
            isNewUser = true;

            // Auto-register user with phone number
            // Identity requires email - use phone-based placeholder
            user = new ApplicationUser
            {
                UserName = phoneNumber,
                Email = $"{phoneNumber}@phone.local",
                PhoneNumber = phoneNumber,
                PhoneNumberConfirmed = true,
                EmailConfirmed = true,
            };

            var createResult = await _userManager.CreateAsync(user);
            if (!createResult.Succeeded)
                return Result<SendOtpResponseDto>.Failure(createResult.Errors.Select(e => e.Description).ToList());

            // Create user profile
            var profile = new UserProfile
            {
                UserId = user.Id,
                IsActive = true,
                Country = country,
            };
            await _profileRepository.AddAsync(profile);

            if (!await _roleManager.RoleExistsAsync(Roles.MobileUser))
                await _roleManager.CreateAsync(new IdentityRole(Roles.MobileUser));
            await _userManager.AddToRoleAsync(user, Roles.MobileUser);

            _logger.LogInformation("New user auto-registered for phone {Phone}", phoneNumber);
        }

        var userProfile = (await _profileRepository.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
        if (userProfile is not null && !userProfile.IsActive)
            return Result<SendOtpResponseDto>.Failure("Account is deactivated. Please contact support.");

        // Rate limit: if OTP was sent recently and hasn't expired, don't resend
        if (user.Otp is not null && user.OtpExpiryTime > DateTime.UtcNow.AddMinutes(-1))
            return Result<SendOtpResponseDto>.Success(
                new SendOtpResponseDto { Otp = user.Otp, IsNewUser = isNewUser },
                "OTP already sent. Please wait before requesting again.");

        // Generate 6-digit OTP
        var otp = GenerateOtp();

        user.Otp = otp;
        user.OtpExpiryTime = DateTime.UtcNow.AddMinutes(OtpExpiryMinutes);
        user.OtpAttempts = 0;
        await _userManager.UpdateAsync(user);

        // Send OTP via SMS
        await _smsService.SendSmsAsync(phoneNumber, $"Your ClaimAI verification code is: {otp}");

        _logger.LogInformation("OTP sent to {Phone}", phoneNumber);
        return Result<SendOtpResponseDto>.Success(
            new SendOtpResponseDto { Otp = otp, IsNewUser = isNewUser }, "OTP sent successfully.");
    }

    public async Task<Result<AuthResponseDto>> VerifyOtpAsync(string phoneNumber, string otp)
    {
        var normalized = NormalizePhone(phoneNumber);
        var user = await _userManager.FindByNameAsync(phoneNumber)
                   ?? _userManager.Users.AsEnumerable()
                       .FirstOrDefault(u => NormalizePhone(u.PhoneNumber) == normalized);

        if (user is null)
            return Result<AuthResponseDto>.Failure("Invalid phone number.");

        var profile = (await _profileRepository.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();
        if (profile is null || !profile.IsActive)
            return Result<AuthResponseDto>.Failure("Invalid phone number.");

        // Check if OTP exists
        if (user.Otp is null || user.OtpExpiryTime is null)
            return Result<AuthResponseDto>.Failure("No OTP requested. Please request a new OTP.");

        // Check max attempts
        if (user.OtpAttempts >= MaxOtpAttempts)
        {
            // Clear OTP to force re-request
            user.Otp = null;
            user.OtpExpiryTime = null;
            user.OtpAttempts = 0;
            await _userManager.UpdateAsync(user);
            return Result<AuthResponseDto>.Failure("Too many failed attempts. Please request a new OTP.");
        }

        // Check expiry
        if (user.OtpExpiryTime <= DateTime.UtcNow)
        {
            user.Otp = null;
            user.OtpExpiryTime = null;
            user.OtpAttempts = 0;
            await _userManager.UpdateAsync(user);
            return Result<AuthResponseDto>.Failure("OTP has expired. Please request a new OTP.");
        }

        // Verify OTP
        if (user.Otp != otp)
        {
            user.OtpAttempts++;
            await _userManager.UpdateAsync(user);
            var remaining = MaxOtpAttempts - user.OtpAttempts;
            return Result<AuthResponseDto>.Failure($"Invalid OTP. {remaining} attempt(s) remaining.");
        }

        // OTP verified - clear it
        user.Otp = null;
        user.OtpExpiryTime = null;
        user.OtpAttempts = 0;
        await _userManager.UpdateAsync(user);

        _logger.LogInformation("OTP verified for {Phone}", phoneNumber);
        return await GenerateAuthResponseAsync(user);
    }

    /// Strips all non-digit characters so "+91 12345 67890" and "9112345 67890" compare equal.
    private static string NormalizePhone(string? phone)
    {
        if (string.IsNullOrWhiteSpace(phone)) return string.Empty;
        return new string(phone.Where(char.IsDigit).ToArray());
    }

    private static string GenerateOtp()
    {
        return RandomNumberGenerator.GetInt32(100000, 999999).ToString();
    }

    private async Task<Result<AuthResponseDto>> GenerateAuthResponseAsync(ApplicationUser user)
    {
        var accessToken = await _tokenService.GenerateAccessTokenAsync(user);
        var refreshToken = _tokenService.GenerateRefreshToken();
        var refreshTokenDays = int.Parse(_configuration["Jwt:RefreshTokenExpirationDays"] ?? "7");

        user.RefreshToken = refreshToken;
        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(refreshTokenDays);
        await _userManager.UpdateAsync(user);

        var roles = await _userManager.GetRolesAsync(user);
        var expirationMinutes = int.Parse(_configuration["Jwt:AccessTokenExpirationMinutes"] ?? "30");

        var profile = (await _profileRepository.FindAsync(p => p.UserId == user.Id)).FirstOrDefault();

        var response = new AuthResponseDto
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            AccessTokenExpiration = DateTime.UtcNow.AddMinutes(expirationMinutes),
            UserId = user.Id,
            Email = user.Email!,
            FullName = $"{profile?.FirstName} {profile?.LastName}".Trim(),
            Roles = roles
        };

        return Result<AuthResponseDto>.Success(response, "Login successful.");
    }
}
