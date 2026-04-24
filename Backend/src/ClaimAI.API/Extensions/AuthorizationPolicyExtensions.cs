namespace ClaimAI.API.Extensions;

public static class AuthorizationPolicyExtensions
{
    public static IServiceCollection AddAuthorizationPolicies(this IServiceCollection services)
    {
        services.AddAuthorizationBuilder()
            .AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"))
            .AddPolicy("UserOnly", policy => policy.RequireRole("User"))
            .AddPolicy("AdminOrUser", policy => policy.RequireRole("Admin", "User"));

        return services;
    }
}
