namespace ClaimAI.Infrastructure.Configuration;

/// <summary>Bound from the <c>Firebase</c> section of <c>appsettings.json</c>.</summary>
public class FirebaseOptions
{
    public const string SectionName = "Firebase";

    /// <summary>Path (absolute or relative to ContentRoot) to the Firebase service-account JSON.</summary>
    public string ServiceAccountKeyPath { get; set; } = string.Empty;

    /// <summary>Firebase project ID (optional; SDK reads from the key file when omitted).</summary>
    public string ProjectId { get; set; } = string.Empty;
}
