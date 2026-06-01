using ClaimAI.Domain.Enums;

namespace ClaimAI.Domain.Entities;

public class AppVersion : BaseEntity
{
    public AppPlatform Platform { get; set; }
    public string VersionName { get; set; } = string.Empty;
    public int VersionCode { get; set; }
    public int MinSupportedVersionCode { get; set; }
    public bool IsLatest { get; set; }
    public bool IsMandatory { get; set; }
    public string? ReleaseNotes { get; set; }
    public DateTime ReleaseDate { get; set; } = DateTime.UtcNow;
    public string? StoreUrl { get; set; }
}
