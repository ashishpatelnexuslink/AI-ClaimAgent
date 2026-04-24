using ClaimAI.Domain.Constants;
using ClaimAI.Domain.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace ClaimAI.Infrastructure.Data.Seeders;

public static class RoleSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var sp = scope.ServiceProvider;
        var roleManager = sp.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = sp.GetRequiredService<UserManager<ApplicationUser>>();
        var context = sp.GetRequiredService<ApplicationDbContext>();
        var logger = sp.GetRequiredService<ILogger<ApplicationDbContext>>();

        if (!await roleManager.RoleExistsAsync(Roles.MobileUser))
        {
            await roleManager.CreateAsync(new IdentityRole(Roles.MobileUser));
            logger.LogInformation("Created role {Role}", Roles.MobileUser);
        }

        var adminRoleIds = await context.Roles
            .Where(r => r.Name != null && Roles.AdminRoles.Contains(r.Name))
            .Select(r => r.Id)
            .ToListAsync();

        var adminUserIds = adminRoleIds.Count == 0
            ? new HashSet<string>()
            : new HashSet<string>(
                await context.UserRoles
                    .Where(ur => adminRoleIds.Contains(ur.RoleId))
                    .Select(ur => ur.UserId)
                    .Distinct()
                    .ToListAsync());

        var candidateIds = await context.UserProfiles
            .Select(p => p.UserId)
            .Distinct()
            .ToListAsync();

        var toBackfill = candidateIds.Where(id => !adminUserIds.Contains(id)).ToList();
        if (toBackfill.Count == 0)
            return;

        var backfilled = 0;
        foreach (var userId in toBackfill)
        {
            var user = await userManager.FindByIdAsync(userId);
            if (user is null)
                continue;
            if (await userManager.IsInRoleAsync(user, Roles.MobileUser))
                continue;
            var result = await userManager.AddToRoleAsync(user, Roles.MobileUser);
            if (result.Succeeded)
                backfilled++;
        }

        if (backfilled > 0)
            logger.LogInformation("Backfilled {Count} users into {Role} role", backfilled, Roles.MobileUser);
    }
}
