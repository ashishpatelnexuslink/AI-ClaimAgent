using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.AppVersions;

public class CreateAppVersionDto
{
    public AppPlatform Platform { get; set; }
    public string VersionName { get; set; } = string.Empty;
    public int VersionCode { get; set; }
    public int MinSupportedVersionCode { get; set; }
    public bool IsLatest { get; set; }
    public bool IsMandatory { get; set; }
    public string? ReleaseNotes { get; set; }
    public DateTime? ReleaseDate { get; set; }
    public string? StoreUrl { get; set; }
}
