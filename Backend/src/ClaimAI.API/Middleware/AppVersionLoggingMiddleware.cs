namespace ClaimAI.API.Middleware;

public class AppVersionLoggingMiddleware
{
    public const string AppVersionHeader = "X-App-Version";
    public const string AppPlatformHeader = "X-App-Platform";

    private readonly RequestDelegate _next;
    private readonly ILogger<AppVersionLoggingMiddleware> _logger;

    public AppVersionLoggingMiddleware(RequestDelegate next, ILogger<AppVersionLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var appVersion = context.Request.Headers[AppVersionHeader].ToString();
        var appPlatform = context.Request.Headers[AppPlatformHeader].ToString();

        if (!string.IsNullOrWhiteSpace(appVersion) || !string.IsNullOrWhiteSpace(appPlatform))
        {
            context.Items[AppVersionHeader] = appVersion;
            context.Items[AppPlatformHeader] = appPlatform;

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["AppVersion"] = appVersion,
                ["AppPlatform"] = appPlatform,
            }))
            {
                await _next(context);
            }
            return;
        }

        await _next(context);
    }
}
