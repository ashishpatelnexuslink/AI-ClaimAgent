using ClaimAI.Application.DTOs.AppVersions;
using ClaimAI.Domain.Common;
using ClaimAI.Domain.Enums;

namespace ClaimAI.Application.Interfaces;

public interface IAppVersionService
{
    Task<Result<List<AppVersionDto>>> GetAllAsync(AppPlatform? platform, CancellationToken cancellationToken = default);
    Task<Result<AppVersionDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Result<AppVersionDto>> GetLatestAsync(AppPlatform platform, CancellationToken cancellationToken = default);
    Task<Result<AppVersionDto>> CreateAsync(CreateAppVersionDto dto, CancellationToken cancellationToken = default);
    Task<Result<AppVersionDto>> UpdateAsync(Guid id, UpdateAppVersionDto dto, CancellationToken cancellationToken = default);
    Task<Result> DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Result<VersionCheckResponseDto>> CheckAsync(VersionCheckRequestDto request, CancellationToken cancellationToken = default);
}
