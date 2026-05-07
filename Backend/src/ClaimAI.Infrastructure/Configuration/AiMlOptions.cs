namespace ClaimAI.Infrastructure.Configuration;

/// <summary>Bound from the <c>AiMl</c> section of <c>appsettings.json</c>.</summary>
public class AiMlOptions
{
    public const string SectionName = "AiMl";

    public string BaseUrl { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;

    /// <summary>Login path on the AI/ML host (default: <c>/auth/login</c>).</summary>
    public string LoginPath { get; set; } = "/auth/login";

    /// <summary>Path the template payload is POSTed to (default: <c>/config</c>).</summary>
    public string ConfigPath { get; set; } = "/config";
}
