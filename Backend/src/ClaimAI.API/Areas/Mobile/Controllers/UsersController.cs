using System.Security.Claims;
using ClaimAI.Application.DTOs.Common;
using ClaimAI.Application.DTOs.Mobile.Users;
using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Interfaces.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace ClaimAI.API.Areas.Mobile.Controllers;

[ApiController]
[Route("api/mobile/[controller]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IGenericRepository<UserProfile> _profileRepository;
    private readonly IWebHostEnvironment _env;

    public UsersController(
        UserManager<ApplicationUser> userManager,
        IGenericRepository<UserProfile> profileRepository,
        IWebHostEnvironment env)
    {
        _userManager = userManager;
        _profileRepository = profileRepository;
        _env = env;
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

        var profile = new UserProfileDto
        {
            Id = user.Id,
            FullName = $"{userProfile?.FirstName} {userProfile?.LastName}".Trim(),
            Email = user.Email != null && !user.Email.EndsWith("@phone.local")
                ? user.Email
                : string.Empty,
            Phone = user.PhoneNumber,
            AvatarUrl = !string.IsNullOrEmpty(userProfile?.AvatarUrl)
                ? $"{Request.Scheme}://{Request.Host}{userProfile.AvatarUrl}"
                : null,
            Role = roles.FirstOrDefault() ?? string.Empty,
            IsVerified = user.EmailConfirmed || user.PhoneNumberConfirmed,
            IsBiometricEnabled = userProfile?.IsBiometricEnabled ?? false,
            Country = userProfile?.Country,
        };

        return Ok(ApiResponse<UserProfileDto>.SuccessResponse(profile));
    }

    [HttpPut("profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user is null)
            return NotFound(ApiResponse<object>.FailResponse("User not found.", 404));

        var userProfile = (await _profileRepository.FindAsync(p => p.UserId == userId)).FirstOrDefault();
        if (userProfile is null)
            return NotFound(ApiResponse<object>.FailResponse("User profile not found.", 404));

        // Update profile fields
        var nameParts = request.FullName.Trim().Split(' ', 2);
        userProfile.FirstName = nameParts[0];
        userProfile.LastName = nameParts.Length > 1 ? nameParts[1] : string.Empty;
        if (request.Country is not null)
            userProfile.Country = request.Country;
        await _profileRepository.UpdateAsync(userProfile);

        // Update Identity fields (Email, Phone)
        user.PhoneNumber = request.Phone;

        if (!string.IsNullOrWhiteSpace(request.Email))
        {
            var normalizer = _userManager.KeyNormalizer;
            user.Email = request.Email;
            user.NormalizedEmail = normalizer.NormalizeEmail(request.Email);
            user.UserName = request.Email;
            user.NormalizedUserName = normalizer.NormalizeName(request.Email);
        }

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
            return BadRequest(ApiResponse<object>.FailResponse(
                result.Errors.Select(e => e.Description).ToList()));

        return Ok(ApiResponse<object>.SuccessResponse(new { }, "Profile updated successfully."));
    }

    [HttpPost("profile/photo")]
    public async Task<IActionResult> UploadProfilePhoto(IFormFile file)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var userProfile = (await _profileRepository.FindAsync(p => p.UserId == userId)).FirstOrDefault();
        if (userProfile is null)
            return NotFound(ApiResponse<object>.FailResponse("User profile not found.", 404));

        if (file.Length == 0)
            return BadRequest(ApiResponse<object>.FailResponse("No file uploaded."));

        var allowedTypes = new[] { "image/jpeg", "image/png", "image/webp" };
        if (!allowedTypes.Contains(file.ContentType))
            return BadRequest(ApiResponse<object>.FailResponse("Only JPEG, PNG, and WebP images are allowed."));

        if (file.Length > 5 * 1024 * 1024)
            return BadRequest(ApiResponse<object>.FailResponse("File size must not exceed 5 MB."));

        var uploadsDir = Path.Combine(_env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot"), "uploads", "avatars");
        Directory.CreateDirectory(uploadsDir);

        // Delete old avatar if it exists on disk
        if (!string.IsNullOrEmpty(userProfile.AvatarUrl))
        {
            var oldPath = Path.Combine(_env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot"), userProfile.AvatarUrl.TrimStart('/'));
            if (System.IO.File.Exists(oldPath))
                System.IO.File.Delete(oldPath);
        }

        var ext = Path.GetExtension(file.FileName);
        var fileName = $"{userId}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}{ext}";
        var filePath = Path.Combine(uploadsDir, fileName);

        await using var stream = new FileStream(filePath, FileMode.Create);
        await file.CopyToAsync(stream);

        userProfile.AvatarUrl = $"/uploads/avatars/{fileName}";
        await _profileRepository.UpdateAsync(userProfile);

        var fullAvatarUrl = $"{Request.Scheme}://{Request.Host}{userProfile.AvatarUrl}";
        return Ok(ApiResponse<object>.SuccessResponse(
            new { avatarUrl = fullAvatarUrl },
            "Profile photo updated successfully."));
    }

    [HttpPut("profile/biometric")]
    public async Task<IActionResult> UpdateBiometricSetting([FromBody] UpdateBiometricSettingDto request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId is null)
            return Unauthorized();

        var user = await _userManager.FindByIdAsync(userId);
        if (user is null)
            return NotFound(ApiResponse<object>.FailResponse("User not found.", 404));

        var userProfile = (await _profileRepository.FindAsync(p => p.UserId == userId)).FirstOrDefault();
        if (userProfile is null)
            return NotFound(ApiResponse<object>.FailResponse("User profile not found.", 404));

        userProfile.IsBiometricEnabled = request.IsEnabled;
        await _profileRepository.UpdateAsync(userProfile);

        var roles = await _userManager.GetRolesAsync(user);
        var profile = new UserProfileDto
        {
            Id = user.Id,
            FullName = $"{userProfile.FirstName} {userProfile.LastName}".Trim(),
            Email = user.Email != null && !user.Email.EndsWith("@phone.local")
                ? user.Email
                : string.Empty,
            Phone = user.PhoneNumber,
            AvatarUrl = !string.IsNullOrEmpty(userProfile.AvatarUrl)
                ? $"{Request.Scheme}://{Request.Host}{userProfile.AvatarUrl}"
                : null,
            Role = roles.FirstOrDefault() ?? string.Empty,
            IsVerified = user.EmailConfirmed || user.PhoneNumberConfirmed,
            IsBiometricEnabled = userProfile.IsBiometricEnabled,
            Country = userProfile.Country,
        };

        return Ok(ApiResponse<UserProfileDto>.SuccessResponse(
            profile,
            request.IsEnabled ? "Biometric login enabled." : "Biometric login disabled."));
    }
}
