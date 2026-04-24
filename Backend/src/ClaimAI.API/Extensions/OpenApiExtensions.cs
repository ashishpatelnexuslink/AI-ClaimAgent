using Microsoft.AspNetCore.OpenApi;

namespace ClaimAI.API.Extensions;

public static class OpenApiExtensions
{
    public static IServiceCollection AddOpenApiWithAuth(this IServiceCollection services)
    {
        services.AddOpenApi(options =>
        {
            options.AddDocumentTransformer((document, context, ct) =>
            {
                document.Info.Title = "ClaimAI API";
                document.Info.Version = "v1";
                document.Info.Description = "AI-based Claim Management System API";
                return Task.CompletedTask;
            });
        });

        return services;
    }
}
