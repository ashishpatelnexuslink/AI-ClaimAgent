using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.DTOs.AppVersions;

public class VersionCheckRequestDto
{
    public AppPlatform Platform { get; set; }
    public int VersionCode { get; set; }
}
