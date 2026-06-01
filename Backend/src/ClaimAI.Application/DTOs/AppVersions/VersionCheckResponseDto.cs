namespace ClaimAI.Application.DTOs.AppVersions;

public class VersionCheckResponseDto
{
    public bool UpdateRequired { get; set; }
    public bool UpdateAvailable { get; set; }
    public bool IsMandatory { get; set; }
    public string LatestVersionName { get; set; } = string.Empty;
    public int LatestVersionCode { get; set; }
    public int MinSupportedVersionCode { get; set; }
    public string? StoreUrl { get; set; }
    public string? ReleaseNotes { get; set; }
}
