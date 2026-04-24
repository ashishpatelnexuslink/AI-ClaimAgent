using ClaimAI.Application.DTOs.MobileUsers;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Constants;
using ClaimAI.Infrastructure.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Services;

public class MobileUserService : IMobileUserService
{
    private readonly ApplicationDbContext _context;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public MobileUserService(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor)
    {
        _context = context;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task<Result<List<MobileUserDto>>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var mobileUserIds = await GetMobileUserIdsAsync(cancellationToken);
        var baseUrl = GetRequestBaseUrl();

        var query = from user in _context.Users.AsNoTracking()
                    where mobileUserIds.Contains(user.Id)
                    join profile in _context.UserProfiles.AsNoTracking()
                        on user.Id equals profile.UserId into profiles
                    from profile in profiles.DefaultIfEmpty()
                    select new
                    {
                        user.Id,
                        user.Email,
                        user.PhoneNumber,
                        Profile = profile,
                        ClaimsCount = _context.Claims.Count(c => c.UserId == user.Id),
                    };

        var rows = await query.ToListAsync(cancellationToken);

        var result = rows
            .Select(r => new MobileUserDto
            {
                Id = r.Id,
                Name = $"{r.Profile?.FirstName} {r.Profile?.LastName}".Trim(),
                Email = !string.IsNullOrEmpty(r.Email) && !r.Email.EndsWith("@phone.local")
                    ? r.Email
                    : string.Empty,
                Phone = r.PhoneNumber ?? string.Empty,
                MemberSince = (r.Profile?.CreatedAt ?? DateTime.UtcNow).ToString("o"),
                TotalClaims = r.ClaimsCount,
                Status = (r.Profile?.IsActive ?? true) ? "Active" : "Suspended",
                ProfileImage = BuildAvatarUrl(baseUrl, r.Profile?.AvatarUrl),
            })
            .OrderBy(u => u.Name)
            .ToList();

        return Result<List<MobileUserDto>>.Success(result);
    }

    public async Task<Result<MobileUserDto>> GetByIdAsync(string id, CancellationToken cancellationToken = default)
    {
        var mobileUserIds = await GetMobileUserIdsAsync(cancellationToken);
        if (!mobileUserIds.Contains(id))
            return Result<MobileUserDto>.Failure("User not found.");

        var baseUrl = GetRequestBaseUrl();

        var row = await (from user in _context.Users.AsNoTracking()
                         where user.Id == id
                         join profile in _context.UserProfiles.AsNoTracking()
                             on user.Id equals profile.UserId into profiles
                         from profile in profiles.DefaultIfEmpty()
                         select new
                         {
                             user.Id,
                             user.Email,
                             user.PhoneNumber,
                             Profile = profile,
                             ClaimsCount = _context.Claims.Count(c => c.UserId == user.Id),
                         }).FirstOrDefaultAsync(cancellationToken);

        if (row is null)
            return Result<MobileUserDto>.Failure("User not found.");

        var dto = new MobileUserDto
        {
            Id = row.Id,
            Name = $"{row.Profile?.FirstName} {row.Profile?.LastName}".Trim(),
            Email = !string.IsNullOrEmpty(row.Email) && !row.Email.EndsWith("@phone.local")
                ? row.Email
                : string.Empty,
            Phone = row.PhoneNumber ?? string.Empty,
            MemberSince = (row.Profile?.CreatedAt ?? DateTime.UtcNow).ToString("o"),
            TotalClaims = row.ClaimsCount,
            Status = (row.Profile?.IsActive ?? true) ? "Active" : "Suspended",
            ProfileImage = BuildAvatarUrl(baseUrl, row.Profile?.AvatarUrl),
        };

        return Result<MobileUserDto>.Success(dto);
    }

    private async Task<List<string>> GetMobileUserIdsAsync(CancellationToken cancellationToken)
    {
        var roleId = await _context.Roles
            .AsNoTracking()
            .Where(r => r.Name == Roles.MobileUser)
            .Select(r => r.Id)
            .FirstOrDefaultAsync(cancellationToken);

        if (roleId is null)
            return [];

        return await _context.UserRoles
            .AsNoTracking()
            .Where(ur => ur.RoleId == roleId)
            .Select(ur => ur.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);
    }

    private string? GetRequestBaseUrl()
    {
        var request = _httpContextAccessor.HttpContext?.Request;
        return request is null ? null : $"{request.Scheme}://{request.Host}";
    }

    private static string? BuildAvatarUrl(string? baseUrl, string? avatarPath)
    {
        if (string.IsNullOrEmpty(avatarPath))
            return null;
        if (avatarPath.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            avatarPath.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            return avatarPath;
        return string.IsNullOrEmpty(baseUrl) ? avatarPath : $"{baseUrl}{avatarPath}";
    }
}
