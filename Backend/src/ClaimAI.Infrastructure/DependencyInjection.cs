using ClaimAI.Application.Interfaces;
using ClaimAI.Domain.Interfaces.Repositories;
using ClaimAI.Infrastructure.Configuration;
using ClaimAI.Infrastructure.Data;
using ClaimAI.Infrastructure.Identity;
using ClaimAI.Infrastructure.Interceptors;
using ClaimAI.Infrastructure.Repositories;
using ClaimAI.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace ClaimAI.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<AuditableEntityInterceptor>();

        services.AddDbContext<ApplicationDbContext>((sp, options) =>
        {
            var interceptor = sp.GetRequiredService<AuditableEntityInterceptor>();
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection"))
                   .AddInterceptors(interceptor);
        });

        services.AddIdentityConfiguration();

        services.AddHttpContextAccessor();
        services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
        services.AddScoped<ITemplateRepository, TemplateRepository>();
        services.AddScoped<ICurrentUserService, CurrentUserService>();
        services.AddScoped<IEmailService, EmailService>();
        services.AddScoped<ISmsService, SmsService>();
        services.AddScoped<IClaimsService, ClaimsService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IChatService, ChatService>();
        services.AddScoped<IAdminUserService, AdminUserService>();
        services.AddScoped<IMobileUserService, MobileUserService>();
        services.AddScoped<ITemplateService, TemplateService>();

        services.Configure<AiMlOptions>(configuration.GetSection(AiMlOptions.SectionName));
        services.AddHttpClient<IAiMlClient, AiMlClient>((sp, client) =>
        {
            var opts = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<AiMlOptions>>().Value;
            if (!string.IsNullOrWhiteSpace(opts.BaseUrl))
                client.BaseAddress = new Uri(opts.BaseUrl);
            client.Timeout = TimeSpan.FromSeconds(30);
        });

        return services;
    }
}
