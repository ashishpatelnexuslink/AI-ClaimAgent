using ClaimAI.Application.DTOs.Admin;
using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Constants;
using ClaimAI.Domain.Entities;
using ClaimAI.Infrastructure.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Services;

public class AdminUserService : IAdminUserService
{
    private static readonly string[] AdminRoles = [Roles.SuperAdmin, Roles.Reviewer, Roles.Viewer];

    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly ApplicationDbContext _context;

    public AdminUserService(
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager,
        ApplicationDbContext context)
    {
        _userManager = userManager;
        _roleManager = roleManager;
        _context = context;
    }

    public async Task<Result<List<AdminUserDto>>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        await EnsureAdminRolesExistAsync();

        var adminUsers = new Dictionary<string, AdminUserDto>();

        foreach (var role in AdminRoles)
        {
            var usersInRole = await _userManager.GetUsersInRoleAsync(role);
            foreach (var user in usersInRole)
            {
                if (adminUsers.ContainsKey(user.Id))
                    continue;

                var profile = await _context.UserProfiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.UserId == user.Id, cancellationToken);

                adminUsers[user.Id] = new AdminUserDto
                {
                    Id = user.Id,
                    Name = $"{profile?.FirstName} {profile?.LastName}".Trim(),
                    Email = user.Email ?? string.Empty,
                    Role = role,
                    Status = (profile?.IsActive ?? true) ? "Active" : "Suspended",
                };
            }
        }

        var result = adminUsers.Values.OrderBy(u => u.Name).ToList();
        return Result<List<AdminUserDto>>.Success(result);
    }

    public async Task<Result<AdminUserDto>> CreateAsync(CreateAdminUserDto request, CancellationToken cancellationToken = default)
    {
        if (!AdminRoles.Contains(request.Role))
            return Result<AdminUserDto>.Failure($"Role must be one of: {string.Join(", ", AdminRoles)}.");

        var existing = await _userManager.FindByEmailAsync(request.Email);
        if (existing is not null)
            return Result<AdminUserDto>.Failure("A user with this email already exists.");

        await EnsureAdminRolesExistAsync();

        var (firstName, lastName) = SplitName(request.Name);

        var user = new ApplicationUser
        {
            UserName = request.Email,
            Email = request.Email,
            EmailConfirmed = true,
        };

        var createResult = await _userManager.CreateAsync(user, request.Password);
        if (!createResult.Succeeded)
            return Result<AdminUserDto>.Failure(createResult.Errors.Select(e => e.Description).ToList());

        var profile = new UserProfile
        {
            UserId = user.Id,
            FirstName = firstName,
            LastName = lastName,
            IsActive = true,
        };
        _context.UserProfiles.Add(profile);
        await _context.SaveChangesAsync(cancellationToken);

        var roleResult = await _userManager.AddToRoleAsync(user, request.Role);
        if (!roleResult.Succeeded)
            return Result<AdminUserDto>.Failure(roleResult.Errors.Select(e => e.Description).ToList());

        var dto = new AdminUserDto
        {
            Id = user.Id,
            Name = request.Name,
            Email = user.Email!,
            Role = request.Role,
            Status = "Active",
        };

        return Result<AdminUserDto>.Success(dto, "Admin user created successfully.");
    }

    public async Task<Result<AdminUserDto>> UpdateAsync(string id, UpdateAdminUserDto request, CancellationToken cancellationToken = default)
    {
        if (!AdminRoles.Contains(request.Role))
            return Result<AdminUserDto>.Failure($"Role must be one of: {string.Join(", ", AdminRoles)}.");

        var user = await _userManager.FindByIdAsync(id);
        if (user is null)
            return Result<AdminUserDto>.Failure("Admin user not found.");

        await EnsureAdminRolesExistAsync();

        var currentRoles = await _userManager.GetRolesAsync(user);
        var currentAdminRoles = currentRoles.Where(r => AdminRoles.Contains(r)).ToList();

        if (currentAdminRoles.Count > 0)
        {
            var removeResult = await _userManager.RemoveFromRolesAsync(user, currentAdminRoles);
            if (!removeResult.Succeeded)
                return Result<AdminUserDto>.Failure(removeResult.Errors.Select(e => e.Description).ToList());
        }

        var addResult = await _userManager.AddToRoleAsync(user, request.Role);
        if (!addResult.Succeeded)
            return Result<AdminUserDto>.Failure(addResult.Errors.Select(e => e.Description).ToList());

        var (firstName, lastName) = SplitName(request.Name);

        var profile = await _context.UserProfiles
            .FirstOrDefaultAsync(p => p.UserId == user.Id, cancellationToken);

        if (profile is null)
        {
            profile = new UserProfile
            {
                UserId = user.Id,
                FirstName = firstName,
                LastName = lastName,
                IsActive = request.Status == "Active",
            };
            _context.UserProfiles.Add(profile);
        }
        else
        {
            profile.FirstName = firstName;
            profile.LastName = lastName;
            profile.IsActive = request.Status == "Active";
        }

        await _context.SaveChangesAsync(cancellationToken);

        var dto = new AdminUserDto
        {
            Id = user.Id,
            Name = request.Name,
            Email = user.Email ?? string.Empty,
            Role = request.Role,
            Status = request.Status,
        };

        return Result<AdminUserDto>.Success(dto, "Admin user updated successfully.");
    }

    public async Task<Result> DeleteAsync(string id, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByIdAsync(id);
        if (user is null)
            return Result.Failure("Admin user not found.");

        var profile = await _context.UserProfiles
            .FirstOrDefaultAsync(p => p.UserId == user.Id, cancellationToken);

        if (profile is not null)
        {
            _context.UserProfiles.Remove(profile);
            await _context.SaveChangesAsync(cancellationToken);
        }

        var result = await _userManager.DeleteAsync(user);
        return result.Succeeded
            ? Result.Success("Admin user deleted successfully.")
            : Result.Failure(result.Errors.Select(e => e.Description).ToList());
    }

    private async Task EnsureAdminRolesExistAsync()
    {
        foreach (var role in AdminRoles)
        {
            if (!await _roleManager.RoleExistsAsync(role))
                await _roleManager.CreateAsync(new IdentityRole(role));
        }
    }

    private static (string FirstName, string LastName) SplitName(string name)
    {
        var trimmed = (name ?? string.Empty).Trim();
        if (string.IsNullOrEmpty(trimmed))
            return (string.Empty, string.Empty);

        var parts = trimmed.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
        return parts.Length == 1
            ? (parts[0], string.Empty)
            : (parts[0], parts[1]);
    }
}
